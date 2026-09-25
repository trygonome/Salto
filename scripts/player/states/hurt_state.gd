extends State
## Touché : le héros est repoussé et ne répond plus pendant un court instant.

var _left: float = 0.0

@onready var hero: Hero = owner as Hero


func enter(_previous: StringName) -> void:
	_left = hero.tuning.hero_hurt_time
	hero.visual.stop_spin()
	hero.visual.animator.show_hurt()


func physics_update(delta: float) -> void:
	var tuning: TuningData = hero.tuning
	_left -= delta
	hero.approach_horizontal_velocity(Vector3.ZERO, tuning.ground_brake_rate, delta)
	hero.apply_gravity(delta)
	hero.move(delta)
	if _left <= 0.0:
		machine.transition_to(&"Ground" if hero.is_on_floor() else &"Air")
