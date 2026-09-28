extends State
## Danse de la voie de l'Onde (version 4.1) : le héros fait un pas tribal, l'énergie remonte ses bras
## (des étincelles dorées au bout des doigts), puis la vibration part : onde de paume, spirale ou
## pluie de pas, selon l'enchaînement. On avance lentement en dansant ; l'esquive et le saut
## l'annulent ; redanser après le départ de la vibration enchaîne la figure suivante. Le fil d'écho,
## lui, dure tant qu'on tient le bouton (et qu'il reste du groove) : on le balaie avec le pouce.

## Figure dansée.
var figure: StringName = &""

var _elapsed: float = 0.0
var _released: bool = false
var _direction: Vector3 = Vector3.FORWARD
var _point: Vector3 = Vector3.ZERO
var _spark_left: float = 0.0
var _thread: DanceThread

@onready var hero: Hero = owner as Hero


func enter(_previous: StringName) -> void:
	figure = hero.pending_figure
	_elapsed = 0.0
	_released = false
	_spark_left = 0.0
	var aim: Dictionary = hero.dance_aim(figure)
	_direction = aim[&"direction"]
	_point = aim[&"point"]
	hero.face_now(_direction)
	hero.visual.stop_spin()
	hero.visual.animator.show_dance(figure)
	hero.play_move_sound(figure)
	if figure == DanceMath.THREAD:
		_thread = hero.start_thread()


func exit() -> void:
	hero.end_dance()
	hero.visual.set_yaw_offset_deg(0.0)
	if figure == DanceMath.THREAD:
		hero.thread_held = false
		hero.play_move_sound(&"stop")
	if is_instance_valid(_thread):
		_thread.queue_free()
	_thread = null


func physics_update(delta: float) -> void:
	var tuning: TuningData = hero.tuning
	if hero.roll_cooldown_left <= 0.0 and hero.is_on_floor() and hero.consume_press(&"dodge"):
		machine.transition_to(&"Roll")
		return
	if hero.is_on_floor() and hero.consume_press(&"jump"):
		hero.jump(tuning.jump_speed)
		hero.move(delta)
		machine.transition_to(&"Air")
		return
	_elapsed += delta
	hero.visual.animator.set_attack_time(_elapsed)
	hero.approach_horizontal_velocity(hero.move_direction() * tuning.run_speed * tuning.dance_move_factor, tuning.ground_accel_rate, delta)
	hero.apply_gravity(delta)
	hero.move(delta)
	if figure == DanceMath.THREAD:
		_hold_thread(delta, tuning)
		return
	if figure == DanceMath.SPIRAL:
		hero.visual.set_yaw_offset_deg(360.0 * minf(1.0, _elapsed / tuning.dance_duration))
	if not _released:
		_sparkle(delta, tuning)
		if _elapsed >= tuning.dance_release_time:
			_released = true
			hero.cast_dance(figure, _direction, _point)
			hero.end_dance()
	if _released and hero.wants_dance():
		machine.transition_to(&"Dance")
	elif _elapsed >= tuning.dance_duration or not hero.is_on_floor():
		machine.transition_to(&"Ground" if hero.is_on_floor() else &"Air")


## Fil d'écho : le rayon suit le pouce (ou la Sourdine la plus proche) et boit le groove.
func _hold_thread(delta: float, tuning: TuningData) -> void:
	hero.groove.add(-tuning.dance_thread_drain * delta)
	Journal.count("thread_s", delta)
	if not hero.thread_held or hero.groove.value <= 0.0 or not hero.is_on_floor():
		machine.transition_to(&"Ground" if hero.is_on_floor() else &"Air")
		return
	var aim: Dictionary = hero.dance_aim(figure)
	_direction = aim[&"direction"]
	hero.turn_toward(_direction, tuning.turn_rate_ground, delta)
	var from: Vector3 = (hero.hand_point(true) + hero.hand_point(false)) / 2.0
	var to: Vector3 = from + hero.facing_direction() * tuning.dance_thread_length
	_thread.aim(from, to)
	_thread.tick(delta)
	_sparkle(delta, tuning)


## L'énergie au bout des doigts : de petites gerbes dorées.
func _sparkle(delta: float, tuning: TuningData) -> void:
	_spark_left -= delta
	if _spark_left > 0.0:
		return
	_spark_left = tuning.dance_spark_period
	var fx: Effects = Effects.of(hero)
	if fx:
		fx.burst(hero.hand_point(true), tuning.dance_spark_cubes, tuning.fx_charge_speed, tuning.fx_gold_hue)
		fx.burst(hero.hand_point(false), tuning.dance_spark_cubes, tuning.fx_charge_speed, tuning.fx_gold_hue)
