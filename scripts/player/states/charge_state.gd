extends State
## Coup chargé : Frappe maintenue pendant un coup. Le héros se ramasse, avance lentement là où l'on
## pousse et se tourne vers sa cible ; la charge monte (des étincelles dorées de plus en plus vives,
## un son qui monte ; un anneau quand elle est pleine). Frappe relâchée (jugée sur le temps à ce
## moment), ou tenue trop longtemps : le coup chargé part. La roulade et le saut l'annulent.

var _elapsed: float = 0.0
var _spark_left: float = 0.0
var _full: bool = false

@onready var hero: Hero = owner as Hero


func enter(_previous: StringName) -> void:
	_elapsed = 0.0
	_spark_left = 0.0
	_full = false
	hero.charge_level = 0.0
	hero.visual.stop_spin()
	hero.visual.animator.show_charge()
	hero.play_move_sound(&"charge")


func exit() -> void:
	hero.play_move_sound(&"stop")


func physics_update(delta: float) -> void:
	var tuning: TuningData = hero.tuning
	if hero.roll_cooldown_left <= 0.0 and hero.is_on_floor() and hero.consume_press(&"dodge"):
		hero.charge_level = 0.0
		machine.transition_to(&"Roll")
		return
	if hero.is_on_floor() and hero.consume_press(&"jump"):
		hero.charge_level = 0.0
		hero.jump(tuning.jump_speed)
		hero.move(delta)
		machine.transition_to(&"Air")
		return
	_elapsed += delta
	hero.charge_level = CombatMath.charge_level(_elapsed, tuning)
	hero.approach_horizontal_velocity(hero.move_direction() * tuning.run_speed * tuning.charge_move_factor, tuning.ground_accel_rate, delta)
	hero.turn_toward(hero.aim_direction(), tuning.turn_rate_ground, delta)
	hero.apply_gravity(delta)
	hero.move(delta)
	_sparkle(delta, tuning)
	if not hero.is_on_floor():
		hero.charge_level = 0.0
		machine.transition_to(&"Air")
	elif not hero.input_attack_held or _elapsed >= tuning.charge_hold_max:
		hero.release_charge()
		machine.transition_to(&"Attack")


func _sparkle(delta: float, tuning: TuningData) -> void:
	var fx: Effects = Effects.of(hero)
	if fx == null:
		return
	_spark_left -= delta
	if _spark_left <= 0.0:
		_spark_left = tuning.charge_fx_period
		var count: int = maxi(1, roundi(tuning.fx_charge_cubes * hero.charge_level))
		fx.burst(hero.global_position + Vector3.UP * tuning.fx_double_height, count, tuning.fx_charge_speed, tuning.fx_gold_hue)
	if hero.charge_level >= 1.0 and not _full:
		_full = true
		fx.ring(hero.global_position, tuning.fx_charge_ring, fx.gold, tuning.fx_dodge_ring_time)
		hero.visual.squash(tuning.hero_squash_jump)
		Feedback.vibrate(tuning.vibration_hit)
