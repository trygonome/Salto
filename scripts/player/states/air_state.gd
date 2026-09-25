extends State
## En l'air : contrôle réduit, saut variable, salto, élan aérien et plongeon.

@onready var hero: Hero = owner as Hero


func physics_update(delta: float) -> void:
	var tuning: TuningData = hero.tuning
	if hero.air_dashes_used < hero.stats.air_dashes and hero.consume_press(&"dodge"):
		machine.transition_to(&"AirDash")
		return
	if hero.consume_press(&"attack"):
		machine.transition_to(&"Dive")
		return
	var jumped: bool = hero.try_air_jump()
	var direction: Vector3 = hero.move_direction()
	hero.approach_horizontal_velocity(direction * tuning.run_speed * hero.stats.speed, tuning.air_control_rate, delta)
	hero.turn_toward(direction, tuning.turn_rate_air, delta)
	if not jumped:
		hero.apply_gravity(delta)
	hero.move(delta)
	hero.visual.animator.show_air()
	if hero.is_on_floor() and hero.velocity.y <= 0.0:
		machine.transition_to(&"Ground")
