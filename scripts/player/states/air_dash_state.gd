extends State
## Élan aérien : trajet horizontal rapide, sans gravité, invulnérable au début.
## Un saut restant peut l'interrompre (salto), Frappe le transforme en plongeon.

var _elapsed: float = 0.0
var _direction: Vector3 = Vector3.FORWARD

@onready var hero: Hero = owner as Hero


func enter(_previous: StringName) -> void:
	_elapsed = 0.0
	hero.air_dashes_used += 1
	_direction = hero.intended_direction()
	hero.face_now(_direction)
	hero.visual.animator.show_dash(hero.tuning.air_dash_duration)


func exit() -> void:
	hero.invulnerable = false


func physics_update(delta: float) -> void:
	var tuning: TuningData = hero.tuning
	_elapsed += delta
	hero.invulnerable = _elapsed <= tuning.air_dash_invuln
	hero.velocity = _direction * tuning.air_dash_speed
	if hero.consume_press(&"attack"):
		machine.transition_to(&"Dive")
		return
	if hero.try_air_jump():
		hero.move(delta)
		machine.transition_to(&"Air")
		return
	hero.move(delta)
	if hero.is_on_floor():
		machine.transition_to(&"Ground")
	elif _elapsed >= tuning.air_dash_duration:
		machine.transition_to(&"Air")
