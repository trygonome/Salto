extends State
## Plongeon (Frappe en l'air) : chute droite et rapide ; à l'atterrissage, une onde frappe tout
## autour, d'autant plus large et forte que la chute était haute. Court temps de reprise au sol,
## que le saut et l'esquive peuvent interrompre.

var _start_height: float = 0.0
var _landed: bool = false
var _recovery_left: float = 0.0

@onready var hero: Hero = owner as Hero


func enter(_previous: StringName) -> void:
	var tuning: TuningData = hero.tuning
	_start_height = hero.global_position.y
	_landed = false
	hero.velocity = Vector3.DOWN * tuning.dive_fall_speed
	hero.visual.stop_spin()
	hero.visual.animator.show_pose(tuning.dive_animation, tuning.dive_pose_time)
	hero.visual.set_pitch_deg(tuning.dive_pitch_deg)
	hero.visual.trail.emitting = true


func exit() -> void:
	hero.visual.set_pitch_deg(0.0)
	hero.visual.trail.emitting = false
	hero.hitbox.deactivate()


func physics_update(delta: float) -> void:
	var tuning: TuningData = hero.tuning
	if not _landed:
		hero.velocity = Vector3.DOWN * tuning.dive_fall_speed
		hero.move(delta)
		if hero.is_on_floor():
			_land()
		return
	if hero.roll_cooldown_left <= 0.0 and hero.consume_press(&"dodge"):
		machine.transition_to(&"Roll")
		return
	if hero.consume_press(&"jump"):
		hero.jump(tuning.jump_speed)
		hero.move(delta)
		machine.transition_to(&"Air")
		return
	hero.set_horizontal_velocity(Vector3.ZERO)
	hero.apply_gravity(delta)
	hero.move(delta)
	_recovery_left -= delta
	if _recovery_left <= 0.0:
		machine.transition_to(&"Ground")


func _land() -> void:
	_landed = true
	_recovery_left = hero.tuning.dive_recovery
	hero.visual.set_pitch_deg(0.0)
	hero.visual.trail.emitting = false
	hero.visual.animator.show_ground(0.0)
	hero.shockwave(_start_height - hero.global_position.y)
