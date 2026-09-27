class_name ScreenBackdrop
extends Control
## Fond des écrans : le jeu derrière, flou et teinté (sauf l'écran titre, sur le camp), des
## feuilles de la jungle en cubes aux quatre coins qui se balancent avec la musique, et des cubes de
## couleur qui montent doucement (les couleurs rendues par les Muets). Couleurs et tailles : type
## « ScreenBackdrop » du thème (ou sa variante) ; mouvements : Tuning.ui_*.

## Feuilles par coin, et leur tirage (longueur et largeur en cubes, écart d'angle).
const LEAVES := 4
const LEAF_LENGTH := Vector2i(20, 32)
const LEAF_WIDTH := Vector2i(7, 11)
const LEAF_SPREAD := 0.75
## Couleurs des cubes qui montent (dans le thème : mote_0, mote_1…).
const MOTE_COLORS := 5
const SALT := 104

var _tint: ColorRect
var _motes: MoteLayer
var _clusters: Array[LeafCluster] = []
var _clock: float = 0.0


func _ready() -> void:
	var type: StringName = theme_type_variation if theme_type_variation != &"" else &"ScreenBackdrop"
	var block: float = get_theme_constant(&"block", type)
	var tint: Color = get_theme_color(&"tint", type)
	if tint.a > 0.0:
		_tint = ColorRect.new()
		_tint.name = "Tint"
		_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
		var material := ShaderMaterial.new()
		material.shader = preload("res://scenes/ui/backdrop.gdshader")
		material.set_shader_parameter(&"tint", tint)
		material.set_shader_parameter(&"edge", get_theme_color(&"edge", type))
		material.set_shader_parameter(&"blur", float(get_theme_constant(&"blur", type)))
		_tint.material = material
		add_child(_tint)
	_motes = MoteLayer.new()
	_motes.name = "Motes"
	_motes.set_anchors_preset(Control.PRESET_FULL_RECT)
	_motes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_motes.block = block
	for i: int in MOTE_COLORS:
		_motes.colors.append(get_theme_color(StringName("mote_%d" % i), type))
	_motes.count = get_theme_constant(&"motes", type)
	add_child(_motes)
	var colors: PackedColorArray = [get_theme_color(&"leaf_dark", type), get_theme_color(&"leaf_mid", type), get_theme_color(&"leaf_light", type), get_theme_color(&"leaf_vein", type)]
	for corner: int in 4:
		var cluster := LeafCluster.new()
		cluster.name = "Leaves%d" % corner
		cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cluster.build(corner, block, colors, SALT + corner)
		add_child(cluster)
		_clusters.append(cluster)
	resized.connect(_place)
	_place()


func _place() -> void:
	var corners: Array[Vector2] = [Vector2.ZERO, Vector2(size.x, 0.0), Vector2(0.0, size.y), size]
	for corner: int in _clusters.size():
		_clusters[corner].position = corners[corner]
	_motes.reset(size)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var tuning: TuningData = Tuning.data
	_clock += delta
	# Les feuilles se balancent sur deux temps de la musique (ou d'elles-mêmes, sans musique).
	var beat: float = Rhythm.beat_length() if Rhythm.is_playing() else tuning.ui_idle_beat
	var time: float = Rhythm.song_time() if Rhythm.is_playing() else _clock
	var sway: float = deg_to_rad(tuning.ui_leaf_sway_deg) * sin(TAU * time / (2.0 * beat))
	for corner: int in _clusters.size():
		_clusters[corner].rotation = sway * (1.0 if corner % 2 == 0 else -1.0)
	_motes.advance(delta, tuning.ui_mote_speed, tuning.ui_mote_drift, _clock)


## Feuilles d'un coin : quelques grandes feuilles en cubes qui partent du coin vers l'intérieur.
class LeafCluster:
	extends Control

	var _cells: Array[Rect2] = []
	var _cell_colors: PackedColorArray = []

	## `corner` : 0 en haut à gauche, 1 en haut à droite, 2 en bas à gauche, 3 en bas à droite.
	func build(corner: int, block: float, colors: PackedColorArray, seed_value: int) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var inward := Vector2(1.0 if corner % 2 == 0 else -1.0, 1.0 if corner < 2 else -1.0)
		var base_angle: float = inward.angle()
		for k: int in ScreenBackdrop.LEAVES:
			var angle: float = base_angle + (float(k) / (ScreenBackdrop.LEAVES - 1) - 0.5) * 2.0 * ScreenBackdrop.LEAF_SPREAD + rng.randf_range(-0.1, 0.1)
			var length: int = rng.randi_range(ScreenBackdrop.LEAF_LENGTH.x, ScreenBackdrop.LEAF_LENGTH.y)
			var width: int = rng.randi_range(ScreenBackdrop.LEAF_WIDTH.x, ScreenBackdrop.LEAF_WIDTH.y)
			_leaf(Vector2.from_angle(angle), length, width, block, colors, k % 2 == 0)
		queue_redraw()

	## Une feuille pointue, rastérisée sur la grille des cubes, par rangées de même couleur.
	func _leaf(direction: Vector2, length: int, width: int, block: float, colors: PackedColorArray, lit: bool) -> void:
		var side := Vector2(-direction.y, direction.x)
		var reach: int = length + width
		for row: int in range(-reach, reach + 1):
			var run_start: int = 0
			var run_color: int = -1
			for column: int in range(-reach, reach + 2):
				var index: int = -1
				if column <= reach:
					var p := Vector2(column + 0.5, row + 0.5)
					var u: float = p.dot(direction)
					var v: float = p.dot(side)
					if u > 0.0 and u < length:
						var half: float = width * 0.5 * pow(sin(PI * u / length), 0.7)
						if absf(v) < half:
							index = 3 if absf(v) < 0.6 else 0 if absf(v) > half - 1.0 else (2 if v > 0.0 and lit else 1)
				if index != run_color:
					if run_color >= 0:
						_cells.append(Rect2(run_start * block, row * block, (column - run_start) * block, block))
						_cell_colors.append(colors[run_color])
					run_start = column
					run_color = index

	func _draw() -> void:
		for i: int in _cells.size():
			draw_rect(_cells[i], _cell_colors[i])


## Cubes de couleur qui montent doucement et s'effacent vers le haut.
class MoteLayer:
	extends Control

	var block: float = 4.0
	var count: int = 0
	var colors: PackedColorArray = []
	var _points: PackedVector2Array = []
	var _phases: PackedFloat32Array = []
	var _rng := RandomNumberGenerator.new()
	var _clock: float = 0.0
	var _drift: float = 0.0

	func reset(area: Vector2) -> void:
		_rng.seed = ScreenBackdrop.SALT
		_points.clear()
		_phases.clear()
		for i: int in count:
			_points.append(Vector2(_rng.randf() * area.x, _rng.randf() * area.y))
			_phases.append(_rng.randf() * TAU)

	func advance(delta: float, speed: float, drift: float, clock: float) -> void:
		for i: int in _points.size():
			var p: Vector2 = _points[i]
			p.y -= speed * delta * (0.6 + 0.4 * sin(_phases[i]))
			if p.y < -block * 2.0:
				p = Vector2(_rng.randf() * size.x, size.y + block * 2.0)
			_points[i] = p
		_clock = clock
		_drift = drift
		queue_redraw()

	func _draw() -> void:
		if size.y <= 0.0:
			return
		for i: int in _points.size():
			var p: Vector2 = _points[i]
			var x: float = p.x + sin(_clock + _phases[i]) * _drift
			var color: Color = colors[i % colors.size()] if not colors.is_empty() else Color.WHITE
			color.a *= clampf(p.y / size.y, 0.0, 1.0)
			var side: float = block * (1.0 + float(i % 3) * 0.5)
			draw_rect(Rect2(Vector2(x, p.y) - Vector2.ONE * side * 0.5, Vector2.ONE * side), color)
