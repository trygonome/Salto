extends State
## Coup au sol (enchaînement martelo → meia-lua → armada, ou coup roulé) : élan jusqu'à l'impact,
## zone de coup active à l'impact, enchaînement avec Frappe, annulation par le saut ou l'esquive
## à tout moment, fin écourtée quand on pousse le joystick.

## Coup en cours.
var attack: AttackData

var _elapsed: float = 0.0
var _judgement: RhythmMath.Judgement = RhythmMath.Judgement.MISS
var _struck: bool = false
var _direction: Vector3 = Vector3.FORWARD

@onready var hero: Hero = owner as Hero


func enter(previous: StringName) -> void:
	attack = hero.next_attack(previous)
	_judgement = hero.take_judgement(&"attack")
	_elapsed = 0.0
	_struck = false
	_direction = hero.aim_direction()
	hero.face_now(_direction)
	if attack.hop_speed > 0.0:
		hero.velocity.y = attack.hop_speed
	hero.visual.stop_spin()
	hero.visual.animator.show_attack(attack)
	hero.visual.trail.emitting = true
	hero.play_move_sound(&"swing")


func exit() -> void:
	hero.end_attack()
	hero.hitbox.deactivate()
	hero.visual.set_yaw_offset_deg(0.0)
	hero.visual.trail.emitting = false


func physics_update(delta: float) -> void:
	var tuning: TuningData = hero.tuning
	if hero.roll_cooldown_left <= 0.0 and hero.is_on_floor() and hero.consume_press(&"dodge"):
		machine.transition_to(&"Roll")
		return
	if _try_jump():
		hero.move(delta)
		machine.transition_to(&"Air")
		return
	_elapsed += delta * hero.stats.attack_speed
	hero.visual.animator.set_attack_time(_elapsed)
	hero.visual.set_yaw_offset_deg(attack.yaw_offset_deg(_elapsed))
	var lunge_speed: float = attack.lunge / attack.impact if _elapsed <= attack.impact else 0.0
	hero.set_horizontal_velocity(_direction * lunge_speed)
	hero.apply_gravity(delta)
	hero.move(delta)
	if not _struck and _elapsed >= attack.impact:
		_struck = true
		hero.strike(attack, _direction, _judgement)
		if hero.stats.finale and attack == tuning.combo_attacks[tuning.combo_attacks.size() - 1]:
			hero.quake(tuning.finale_quake_radius, tuning.finale_quake_damage, &"finale")
	if _elapsed >= attack.chain_from and hero.consume_press(&"attack"):
		machine.transition_to(&"Attack")
	elif _elapsed >= attack.chain_from + tuning.move_cancel_delay and hero.input_move.length() > tuning.move_cancel_threshold:
		machine.transition_to(&"Ground")
	elif _elapsed >= attack.duration:
		machine.transition_to(&"Ground" if hero.is_on_floor() else &"Air")


func _try_jump() -> bool:
	if not hero.is_on_floor():
		return hero.try_air_jump()
	if not hero.consume_press(&"jump"):
		return false
	hero.jump(hero.tuning.jump_speed)
	return true
