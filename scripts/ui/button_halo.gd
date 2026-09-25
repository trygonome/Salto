class_name ButtonHalo
extends Node2D
## Halo qui bat autour d'un bouton tactile (ou du repère du joystick) : c'est le bouton à
## utiliser pour l'aide en cours.

var radius: float = 0.0
var color: Color = Color.WHITE
var width: float = 0.0
## Écart du battement, en fraction du rayon.
var pulse_amount: float = 0.0

var _time: float = 0.0


func _ready() -> void:
	visible = false


## Allume ou éteint le halo.
func set_active(active: bool) -> void:
	visible = active
	_time = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var beat: float = 0.5 + 0.5 * sin(TAU * _time / Tuning.data.hint_pulse_period)
	var ring: Color = color
	ring.a *= lerpf(0.45, 1.0, beat)
	draw_arc(Vector2.ZERO, radius * (1.0 + pulse_amount * beat), 0.0, TAU, 48, ring, width, true)
