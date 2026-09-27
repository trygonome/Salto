@tool
class_name VoxelBox
extends StyleBox
## Cadre de l'interface en cubes (voxels) dessiné par le code, net à toutes les tailles : contour
## sombre, biseau clair en haut à gauche et sombre en bas à droite, coins en escalier, ombre portée.
## Au choix : veinures du bois, bandeau tissé aux couleurs de la jungle, laçage de tambour, clous
## aux coins. Les valeurs viennent du thème (tools/ui/make_theme.py).

## Côté d'un cube (px de l'interface).
@export var block: float = 3.0
## Coins en escalier (en cubes).
@export var corner: int = 1
@export var fill: Color = Color.BLACK
@export var rim: Color = Color.BLACK
@export var light: Color = Color.WHITE
@export var dark: Color = Color.BLACK
## Ombre portée, décalée vers le bas (en cubes ; couleur transparente : aucune).
@export var shadow: Color = Color.TRANSPARENT
@export var shadow_blocks: int = 1
## Enfoncé : tout le cadre descend de `sink` cubes (bouton appuyé, à la place de son ombre).
@export var sink: int = 0
## Veinures du bois : traits horizontaux irréguliers (couleur transparente : aucune).
@export var grain: Color = Color.TRANSPARENT
## Bandeau tissé en haut (hauteur en cubes ; aucune couleur : pas de bandeau).
@export var band_colors: PackedColorArray = PackedColorArray()
@export var band_blocks: int = 3
## Laçage de tambour en haut et en bas (couleur transparente : aucun).
@export var lacing: Color = Color.TRANSPARENT
## Clous aux coins (couleur transparente : aucun).
@export var studs: Color = Color.TRANSPARENT

## Pas des veinures (en cubes) et graine de leur tirage.
const GRAIN_STEP := 3
const GRAIN_SALT := 7919
## Laçage : période du zigzag (en cubes).
const LACE_PERIOD := 4


func _get_draw_rect(rect: Rect2) -> Rect2:
	return rect.grow_side(SIDE_BOTTOM, shadow_blocks * block)


func _draw(canvas: RID, rect: Rect2) -> void:
	var b: float = block
	rect.position.y += sink * b
	if shadow.a > 0.0:
		_shape(canvas, Rect2(rect.position + Vector2(0.0, shadow_blocks * b), rect.size), corner, shadow)
	_shape(canvas, rect, corner, rim)
	var inner: Rect2 = rect.grow(-b)
	_shape(canvas, inner, maxi(corner - 1, 0), dark)
	_shape(canvas, Rect2(inner.position, inner.size - Vector2(b, b)), maxi(corner - 1, 0), light)
	var body: Rect2 = inner.grow(-b)
	_shape(canvas, body, maxi(corner - 2, 0), fill)
	if grain.a > 0.0:
		_grain(canvas, body)
	if not band_colors.is_empty():
		_band(canvas, Rect2(body.position, Vector2(body.size.x, minf(band_blocks * b, body.size.y))))
	if lacing.a > 0.0:
		_lacing(canvas, body)
	if studs.a > 0.0:
		for corner_point: Vector2 in [body.position, Vector2(body.end.x - 2.0 * b, body.position.y), Vector2(body.position.x, body.end.y - 2.0 * b), body.end - Vector2(2.0 * b, 2.0 * b)]:
			RenderingServer.canvas_item_add_rect(canvas, Rect2(corner_point + Vector2(b, b) * 0.5, Vector2(b, b)), studs)


## Rectangle aux coins en escalier de `steps` cubes.
func _shape(canvas: RID, rect: Rect2, steps: int, color: Color) -> void:
	if color.a <= 0.0 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var b: float = block
	var n: int = mini(steps, floori(minf(rect.size.x, rect.size.y) / (2.0 * b)))
	for k: int in n:
		var inset: float = (n - k) * b
		var width: float = rect.size.x - 2.0 * inset
		RenderingServer.canvas_item_add_rect(canvas, Rect2(rect.position.x + inset, rect.position.y + k * b, width, b), color)
		RenderingServer.canvas_item_add_rect(canvas, Rect2(rect.position.x + inset, rect.end.y - (k + 1) * b, width, b), color)
	RenderingServer.canvas_item_add_rect(canvas, Rect2(rect.position.x, rect.position.y + n * b, rect.size.x, rect.size.y - 2.0 * n * b), color)


## Veinures : un trait par rangée de GRAIN_STEP cubes, de longueur et de place tirées de la rangée.
func _grain(canvas: RID, body: Rect2) -> void:
	var b: float = block
	var rows: int = floori(body.size.y / b)
	var columns: int = floori(body.size.x / b)
	for row: int in range(1, rows - 1, GRAIN_STEP):
		var h: int = hash(row * GRAIN_SALT)
		var length: int = 3 + posmod(h, maxi(columns / 2, 1))
		var start: int = posmod(h >> 8, maxi(columns - length, 1))
		RenderingServer.canvas_item_add_rect(canvas, Rect2(body.position.x + start * b, body.position.y + row * b, length * b, b), grain)


## Bandeau tissé : chevrons de couleurs, un rang de cubes par ligne.
func _band(canvas: RID, band: Rect2) -> void:
	var b: float = block
	var columns: int = ceili(band.size.x / b)
	var rows: int = floori(band.size.y / b)
	var count: int = band_colors.size()
	for row: int in rows:
		var shift: int = absi(row - rows / 2)
		var run_start: int = 0
		var run_color: int = -1
		for column: int in columns + 1:
			var index: int = posmod((column + shift) / 2, count) if column < columns else -2
			if index != run_color:
				if run_color >= 0:
					var x0: float = band.position.x + run_start * b
					var x1: float = minf(band.position.x + column * b, band.end.x)
					RenderingServer.canvas_item_add_rect(canvas, Rect2(x0, band.position.y + row * b, x1 - x0, b), band_colors[run_color])
				run_start = column
				run_color = index


## Laçage de tambour : un zigzag de cubes le long du haut et du bas.
func _lacing(canvas: RID, body: Rect2) -> void:
	var b: float = block
	var columns: int = floori(body.size.x / b)
	for column: int in columns:
		var phase: int = column % LACE_PERIOD
		var row: int = phase if phase <= LACE_PERIOD / 2 else LACE_PERIOD - phase
		var x: float = body.position.x + column * b
		RenderingServer.canvas_item_add_rect(canvas, Rect2(x, body.position.y + row * b, b, b), lacing)
		RenderingServer.canvas_item_add_rect(canvas, Rect2(x, body.end.y - (row + 1) * b, b, b), lacing)
