class_name HeroAnimator
extends AnimationPlayer
## Animations du héros (clips KayKit) : repos, course, air, roulade, élan, coups, pose du plongeon.
## Le lecteur est avancé à la main par update(), à chaque image physique : les coups restent
## calés sur leur minutage de jeu, et l'arrêt sur image fige aussi le corps.

const IDLE := &"general/Idle_A"
const RUN := &"basic/Running_A"
const AIR := &"basic/Jump_Idle"
const ROLL := &"advanced/Crouching"
const DASH := &"advanced/Dodge_Forward"
const LOOPING: Array[StringName] = [IDLE, RUN, AIR, ROLL]

var _speed: float = 1.0
var _attack: AttackData
var _attack_time: float = 0.0


func _ready() -> void:
	callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for clip: StringName in LOOPING:
		get_animation(clip).loop_mode = Animation.LOOP_LINEAR


## Au sol : repos ou course, le cycle de course suivant la vitesse.
func show_ground(horizontal_speed: float) -> void:
	var tuning: TuningData = Tuning.data
	if horizontal_speed < tuning.idle_speed_threshold:
		_show(IDLE, 1.0)
	else:
		_show(RUN, horizontal_speed / tuning.run_speed * tuning.run_animation_speed)


func show_air() -> void:
	_show(AIR, 1.0)


## Pose ramassée pendant toute la roulade (le tour complet est fait par HeroVisual).
func show_roll() -> void:
	_show(ROLL, 1.0)


## Élan aérien : le clip d'esquive vers l'avant, joué sur `duration` secondes.
func show_dash(duration: float) -> void:
	_show(DASH, get_animation(DASH).length / duration)


## Coup : le clip suit ensuite le temps donné par set_attack_time().
func show_attack(attack: AttackData) -> void:
	_attack = attack
	_attack_time = 0.0
	play(attack.animation, Tuning.data.anim_blend_time)


func set_attack_time(t: float) -> void:
	_attack_time = t


## Pose figée : l'instant `time` du clip `clip` (plongeon).
func show_pose(clip: StringName, time: float) -> void:
	_attack = null
	play(clip, Tuning.data.anim_blend_time)
	seek(time, true)
	_speed = 0.0


## Avance les animations de `delta` secondes de jeu.
func update(delta: float) -> void:
	if _attack:
		var target: float = _attack.animation_time(_attack_time, current_animation_length)
		advance(maxf(target - current_animation_position, 0.0))
	else:
		advance(delta * _speed)


func _show(clip: StringName, speed: float) -> void:
	_speed = speed
	if current_animation == clip and _attack == null:
		return
	_attack = null
	play(clip, Tuning.data.anim_blend_time)
