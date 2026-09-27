class_name WovenBand
extends Control
## Bandeau tissé sous le titre d'un écran : des chevrons aux couleurs de la jungle, bordés de bois,
## aux bouts en pointe. Il se tisse du milieu vers les bords à l'ouverture (`reveal`). Couleurs et
## tailles : type « WovenBand » du thème.

## Part tissée, de 0 (rien) à 1 (tout le bandeau).
var reveal: float = 1.0:
	set(value):
		reveal = value
		queue_redraw()

var _block: float = 4.0
var _rows: int = 3
var _share: float = 0.6
var _colors: PackedColorArray = []
var _edge: Color = Color.BLACK


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_block = get_theme_constant(&"block", &"WovenBand")
	_rows = get_theme_constant(&"rows", &"WovenBand")
	_share = get_theme_constant(&"percent", &"WovenBand") / 100.0
	_edge = get_theme_color(&"edge", &"WovenBand")
	var i: int = 0
	while has_theme_color(StringName("color_%d" % i), &"WovenBand"):
		_colors.append(get_theme_color(StringName("color_%d" % i), &"WovenBand"))
		i += 1
	custom_minimum_size.y = (_rows + 2) * _block


func _draw() -> void:
	if _colors.is_empty():
		return
	var b: float = _block
	var half_columns: int = floori(size.x * _share / b / 2.0)
	var shown: int = roundi(half_columns * reveal)
	if shown <= 0:
		return
	var middle: float = roundf(size.x / 2.0 / b) * b
	var top: float = roundf((size.y - (_rows + 2) * b) / 2.0)
	# Bois autour, pointes aux bouts.
	draw_rect(Rect2(middle - shown * b, top, 2.0 * shown * b, (_rows + 2) * b), _edge)
	for side: float in [-1.0, 1.0]:
		for k: int in _rows / 2 + 1:
			var x: float = middle + side * (shown + k) * b - (b if side < 0.0 else 0.0)
			draw_rect(Rect2(x, top + (k + 1) * b, b, (_rows - 2 * k) * b), _edge)
	for row: int in _rows:
		var shift: int = absi(row - _rows / 2)
		for column: int in range(-shown, shown):
			var index: int = posmod((absi(column) + shift) / 2, _colors.size())
			draw_rect(Rect2(middle + column * b, top + (row + 1) * b, b, b), _colors[index])
