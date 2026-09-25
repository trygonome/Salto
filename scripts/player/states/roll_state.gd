extends State
## Roulade au sol : invulnérable pendant une partie de sa durée, fin ralentie.
## On peut en sortir par un saut (qui garde l'élan), par Frappe (coup roulé) ou l'enchaîner
## avec une autre roulade.

var _elapsed: float = 0.0
var _direction: Vector3 = Vector3.FORWARD

@onready var hero: Hero = owner as Hero


func enter(_previous: StringName) -> void:
	_elapsed = 0.0
	_direction = hero.intended_direction()
	hero.face_now(_direction)
	hero.visual.play_roll(hero.tuning.roll_duration)
	hero.play_move_sound(&"roll")
	hero.visual.animator.show_roll()


func exit() -> void:
	hero.invulnerable = false
	hero.visual.stop_spin()
	hero.end_roll()


func physics_update(delta: float) -> void:
	var tuning: TuningData = hero.tuning
	_elapsed += delta
	var fraction: float = _elapsed / tuning.roll_duration
	hero.invulnerable = HeroMotion.is_roll_invulnerable(fraction, tuning)
	if hero.consume_press(&"attack"):
		machine.transition_to(&"Attack")
		return
	if fraction >= tuning.roll_jump_from and hero.consume_press(&"jump"):
		hero.set_horizontal_velocity(_direction * tuning.roll_jump_carry_speed)
		hero.jump(tuning.jump_speed)
		hero.move(delta)
		machine.transition_to(&"Air")
		return
	if fraction >= tuning.roll_chain_from and hero.consume_press(&"dodge"):
		machine.transition_to(&"Roll")
		return
	hero.set_horizontal_velocity(_direction * HeroMotion.roll_speed(fraction, tuning))
	hero.apply_gravity(delta)
	hero.move(delta)
	if not hero.is_on_floor():
		hero.coyote_left = tuning.coyote_time
		machine.transition_to(&"Air")
	elif fraction >= 1.0:
		hero.roll_cooldown_left = tuning.roll_cooldown
		machine.transition_to(&"Ground")
