class_name MarkerArrow
extends Control
## Pointe du repère de l'objectif : un triangle doré tourné vers le bas, avec son ombre.

@export var color: Color
@export var shadow_color: Color
@export var shadow_offset: Vector2


func _draw() -> void:
	var points := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), Vector2(size.x / 2.0, size.y)])
	var shadow := PackedVector2Array()
	for point: Vector2 in points:
		shadow.append(point + shadow_offset)
	draw_colored_polygon(shadow, shadow_color)
	draw_colored_polygon(points, color)
