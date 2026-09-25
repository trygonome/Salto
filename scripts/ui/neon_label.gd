class_name NeonLabel
extends Label
## Grand texte du prototype : une ombre rose en bas à droite (thème) et un écho cyan en haut à
## gauche, dessiné derrière.

## Couleur et décalage de l'écho (px).
@export var echo_color: Color
@export var echo_offset: Vector2

var _echo: Label


func _ready() -> void:
	_echo = Label.new()
	_echo.name = "Echo"
	_echo.show_behind_parent = true
	_echo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_echo.position = echo_offset
	add_child(_echo, false, Node.INTERNAL_MODE_FRONT)
	draw.connect(_sync)
	_sync()


func _sync() -> void:
	_echo.text = text
	_echo.theme_type_variation = theme_type_variation
	_echo.horizontal_alignment = horizontal_alignment
	_echo.vertical_alignment = vertical_alignment
	_echo.autowrap_mode = autowrap_mode
	_echo.add_theme_color_override(&"font_color", echo_color)
	_echo.add_theme_color_override(&"font_shadow_color", Color.TRANSPARENT)
	_echo.size = size
	_echo.position = echo_offset
