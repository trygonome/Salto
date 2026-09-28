extends State
## Coup au sol (enchaînement martelo → meia-lua → armada, coup roulé, coup chargé, riposte, coup
## de grâce) : élan jusqu'à l'impact (vers le Muet visé pour la riposte et la grâce), zone de coup
## active à l'impact, enchaînement avec Frappe, annulation par le saut ou l'esquive à tout moment,
## fin écourtée quand on pousse le joystick. Frappe tenue pendant un coup de l'enchaînement : la
## charge commence.

## Coup en cours.
var attack: AttackData

var _elapsed: float = 0.0
var _judgement: RhythmMath.Judgement = RhythmMath.Judgement.MISS
var _struck: bool = false
var _direction: Vector3 = Vector3.FORWARD
var _lunge: float = 0.0
var _power: float = 1.0

@onready var hero: Hero = owner as Hero


func enter(previous: StringName) -> void:
	attack = hero.next_attack(previous)
	_judgement = hero.take_judgement(&"attack")
	_elapsed = 0.0
	_struck = false
	_direction = hero.attack_direction()
	_lunge = hero.attack_lunge(attack)
	_power = CombatMath.charge_multiplier(hero.charge_level, hero.tuning) if attack.id == &"charged" else 1.0
	hero.face_now(_direction)
	if attack.hop_speed > 0.0:
		hero.velocity.y = attack.hop_speed
	hero.visual.stop_spin()
	hero.visual.animator.show_attack(attack)
	hero.visual.trail.emitting = true
	match attack.id:
		&"grace":
			hero.visual.play_salto(attack.impact)
			hero.play_move_sound(&"grace")
		&"riposte":
			hero.play_move_sound(&"riposte")
		_:
			hero.play_move_sound(&"swing")


func exit() -> void:
	hero.end_attack()
	hero.charge_level = 0.0
	hero.attack_target = null
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
	var lunge_speed: float = _lunge / attack.impact if _elapsed <= attack.impact else 0.0
	hero.set_horizontal_velocity(_direction * lunge_speed)
	hero.apply_gravity(delta)
	hero.move(delta)
	if not _struck and _elapsed >= attack.impact:
		_struck = true
		hero.strike(attack, _direction, _judgement, -1.0, _power)
		var combo_list: Array[AttackData] = hero.combo_attacks()
		if hero.stats.finale and attack == combo_list[combo_list.size() - 1]:
			hero.quake(tuning.finale_quake_radius, tuning.finale_quake_damage * hero.stats.finale_damage, &"finale")
	if hero.combo_attacks().has(attack) and hero.input_attack_held and _elapsed >= tuning.charge_hold_delay and hero.is_on_floor():
		machine.transition_to(&"Charge")
	elif _elapsed >= attack.chain_from and hero.consume_press(&"attack"):
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
