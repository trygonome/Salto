class_name Pips
extends Control
## Rangs d'un talent : un rond plein par rang pris, un rond vide pour les autres.

@export var color: Color
## Rayon d'un rond, écart entre deux ronds, épaisseur d'un rond vide (px).
@export var radius: float
@export var gap: float
@export var line: float

var rank: int = 0:
	set(value):
		rank = value
		queue_redraw()
var maximum: int = 1:
	set(value):
		maximum = value
		custom_minimum_size = Vector2(maximum * radius * 2.0 + (maximum - 1) * gap, radius * 2.0)
		queue_redraw()


func _draw() -> void:
	var width: float = maximum * radius * 2.0 + (maximum - 1) * gap
	var start: float = (size.x - width) / 2.0 + radius
	for i: int in maximum:
		var center := Vector2(start + i * (radius * 2.0 + gap), size.y / 2.0)
		if i < rank:
			draw_circle(center, radius, color, true, -1.0, true)
		else:
			draw_circle(center, radius - line / 2.0, color, false, line, true)
