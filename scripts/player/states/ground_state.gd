extends State
## Au sol : course, saut et roulade. Quitter un bord sans sauter ouvre la tolérance de saut.

@onready var hero: Hero = owner as Hero


func enter(_previous: StringName) -> void:
	hero.jumps_used = 0
	hero.air_dashes_used = 0


func physics_update(delta: float) -> void:
	var tuning: TuningData = hero.tuning
	if hero.roll_cooldown_left <= 0.0 and hero.consume_press(&"dodge"):
		machine.transition_to(&"Roll")
		return
	var direction: Vector3 = hero.move_direction()
	var rate: float = tuning.ground_brake_rate if direction.is_zero_approx() else tuning.ground_accel_rate
	hero.approach_horizontal_velocity(direction * tuning.run_speed, rate, delta)
	hero.turn_toward(direction, tuning.turn_rate_ground, delta)
	var jumped: bool = hero.consume_press(&"jump")
	if jumped:
		hero.jump(tuning.jump_speed)
	else:
		hero.apply_gravity(delta)
	hero.move(delta)
	if jumped:
		machine.transition_to(&"Air")
	elif not hero.is_on_floor():
		hero.coyote_left = tuning.coyote_time
		machine.transition_to(&"Air")
