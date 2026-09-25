class_name HeroAnimator
extends Node
## Animations du héros voxel, calculées comme dans le prototype (animPlayer) : au repos il se
## balance sur le temps, il court en balançant bras et jambes, se ramasse en roulade et en salto,
## s'étire en montant et écarte les bras en retombant, arme puis détend chaque coup de pied,
## lève les bras en plongeant ; il se tasse à l'atterrissage et recule le buste quand il est
## touché. Sa plume suit ses mouvements. La pose rejoint la pose visée plus ou moins vite
## selon le mouvement.

enum Mode { GROUND, AIR, ROLL, DASH, ATTACK, PLUNGE, HURT }

## Poses fixes (angles en radians, voir VoxelCharacter.POSE_KEYS).
const ROLL_POSE := {
	&"lLx": -1.9, &"lRx": -1.9, &"kL": 2.3, &"kR": 2.3, &"sLx": -1.0, &"sRx": -1.0, &"eL": -1.6, &"eR": -1.6,
	&"sx": 0.8, &"nx": 0.5,
}
const FLIP_POSE := {
	&"lLx": -1.9, &"lRx": -1.9, &"kL": 2.3, &"kR": 2.3, &"sLx": -1.0, &"sRx": -1.0, &"eL": -1.6, &"eR": -1.6,
	&"sx": 0.6, &"sLz": -0.3, &"sRz": 0.3,
}
const DASH_POSE := {
	&"sx": 0.9, &"lLx": 0.7, &"lRx": 0.5, &"kL": 0.9, &"kR": 0.6, &"sLx": 1.3, &"sRx": 1.3, &"eL": -0.2, &"eR": -0.2,
	&"nx": -0.4,
}
const PLUNGE_POSE := {
	&"kL": 0.2, &"kR": 0.2, &"sLx": -2.9, &"sRx": -2.9, &"eL": -0.1, &"eR": -0.1, &"sx": -0.1, &"nx": 0.45,
}
const RISE_POSE := {
	&"lLx": -1.0, &"kL": 1.4, &"lRx": 0.3, &"kR": 0.5, &"sLx": -2.3, &"sRx": 0.6, &"eL": -0.4, &"eR": -0.5,
	&"sx": -0.12, &"sLz": -0.2, &"sRz": 0.3,
}
const FALL_POSE := {
	&"lLx": -0.45, &"kL": 0.7, &"lRx": -0.2, &"kR": 0.45, &"sLx": -0.3, &"sRx": -0.3, &"sLz": -1.1, &"sRz": 1.1,
	&"eL": -0.3, &"eR": -0.3, &"sx": 0.1,
}
## Coups : pose d'armé puis de frappe (la rotation des hanches de la frappe se relâche ensuite de
## moitié) ; une seule pose pour les coups tournoyants ou lancés.
const ATTACK_POSES := {
	&"martelo": [
		{&"hyaw": 0.5, &"syaw": 0.3, &"lRx": 0.3, &"kR": 1.1, &"kL": 0.35, &"sLz": -0.6, &"sRz": 0.4, &"eL": -0.8, &"eR": -0.8},
		{&"hyaw": -1.0, &"syaw": -0.3, &"lRx": -1.35, &"lRz": 0.55, &"kR": 0.1, &"lLx": 0.1, &"kL": 0.4, &"sLz": -1.2, &"sRz": 0.9, &"eL": -0.3, &"eR": -0.4, &"sx": 0.1},
	],
	&"meia_lua": [
		{&"hyaw": -0.55, &"syaw": -0.3, &"lLx": 0.3, &"kL": 1.1, &"kR": 0.35, &"sLz": -0.4, &"sRz": 0.6, &"eL": -0.8, &"eR": -0.8},
		{&"hyaw": 1.1, &"syaw": 0.3, &"lLx": -1.5, &"lLz": -0.75, &"kL": 0.1, &"lRx": 0.1, &"kR": 0.4, &"sLz": -0.5, &"sRz": 1.3, &"eL": -0.4, &"eR": -0.3, &"sx": 0.1},
	],
	&"armada": [
		{&"lRx": -1.2, &"lRz": 0.95, &"kR": 0.0, &"lLx": 0.2, &"kL": 1.4, &"sLz": -1.4, &"sRz": 1.4, &"eL": -0.2, &"eR": -0.2, &"sx": -0.1},
	],
	&"rolling_kick": [
		{&"sx": -0.3, &"lRx": -1.65, &"kR": 0.0, &"lLx": 0.35, &"kL": 1.3, &"sLx": 0.9, &"sRx": 0.9, &"eL": -0.3, &"eR": -0.3, &"nx": -0.1},
	],
	&"air_kick": [
		{&"sx": -0.3, &"lRx": -1.65, &"kR": 0.0, &"lLx": 0.35, &"kL": 1.3, &"sLx": 0.9, &"sRx": 0.9, &"eL": -0.3, &"eR": -0.3, &"nx": -0.1},
	],
}
## Coups portés de la jambe gauche (les autres : jambe droite).
const LEFT_LEG_ATTACKS: Array[StringName] = [&"meia_lua"]
## Course : amplitude des jambes, genoux (repos, levée), chevilles, bras, coudes (repos, en
## course), épaules écartées, buste penché, torsions du buste, des hanches et du cou, rebond
## des hanches (voxels) autour de son milieu, tête baissée.
const RUN := {
	&"leg": 0.9, &"knee": 0.2, &"knee_lift": 1.2, &"ankle": -0.2, &"arm": 0.85, &"elbow": -0.3, &"elbow_run": -1.1,
	&"shoulder_out": 0.2, &"lean": 0.22, &"spine_yaw": 0.25, &"hip_yaw": -0.15, &"neck_yaw": -0.12,
	&"hip_bob": 0.9, &"hip_bob_center": 0.6, &"nod": -0.1,
}
## Repos : genoux, jambes, chevilles, hanches qui descendent (voxels), épaules, coudes, tête et
## buste, plus le rebond sur chaque temps.
const IDLE := {
	&"knee": 0.25, &"knee_bounce": 0.35, &"leg": -0.12, &"leg_bounce": -0.15, &"ankle_bounce": -0.1,
	&"hips_drop": -0.9, &"shoulder": 0.25, &"shoulder_bounce": 0.1, &"elbow": -0.5, &"nod": 0.15, &"lean": 0.05,
}
## Tassement à l'atterrissage et recul quand il est touché (par unité de tassement ou de recul).
const LAND := {&"knee": 1.2, &"leg": -0.6, &"lean": 0.45, &"hips_drop": -2.2, &"arm": -0.6}
const FLINCH := {&"lean": -0.5, &"nod": -0.3, &"shoulder": 0.7, &"shoulder_rest": 0.2}
## Bras le long du corps, coudes pliés, quand la pose visée ne dit rien.
const REST_ARMS := {&"sLz": -0.15, &"sRz": 0.15, &"eL": -0.3, &"eR": -0.3}
## Plume : penchée en arrière avec la vitesse, en avant en montant, en arrière en tombant (rad).
const PLUME := {&"speed": 0.7, &"rise": -0.4, &"fall": 0.5, &"min": -0.8, &"max": 1.3}

## Personnage animé (fourni par HeroVisual).
var character: VoxelCharacter
var mode: Mode = Mode.GROUND

var _speed: float = 0.0
var _attack: AttackData
var _attack_time: float = 0.0
var _walk: float = 0.0
var _step_side: int = 0
var _land: float = 0.0
var _flinch: float = 0.0
var _plume_angle: float = 0.0
var _plume_speed: float = 0.0
var _plume: int = -1


## Au sol : repos ou course, le cycle de course suivant la vitesse (m/s).
func show_ground(horizontal_speed: float) -> void:
	mode = Mode.GROUND
	_speed = horizontal_speed


func show_air() -> void:
	mode = Mode.AIR


func show_roll() -> void:
	mode = Mode.ROLL


## Élan aérien (sa durée ne change pas la pose).
func show_dash(_duration: float) -> void:
	mode = Mode.DASH


## Coup reçu : le buste recule, puis revient.
func show_hurt() -> void:
	mode = Mode.HURT
	_flinch = 1.0


## Coup : la pose suit ensuite le temps donné par set_attack_time().
func show_attack(attack: AttackData) -> void:
	mode = Mode.ATTACK
	_attack = attack
	_attack_time = 0.0


func set_attack_time(t: float) -> void:
	_attack_time = t


## Plongeon : bras levés, jambes tendues.
func show_plunge() -> void:
	mode = Mode.PLUNGE


## Atterrissage après une chute de `fall` mètres : il se tasse d'autant plus que c'est haut.
func land(fall: float) -> void:
	_land = minf(1.0, fall / Tuning.data.hero_land_crouch_height)


## Vrai si le coup en cours est porté de la jambe gauche.
func kicks_with_left_leg() -> bool:
	return mode == Mode.ATTACK and _attack != null and LEFT_LEG_ATTACKS.has(_attack.id)


## Pose d'un coup `id` au temps `t` : armé jusqu'à un peu avant l'impact, puis frappe dont la
## rotation des hanches se relâche jusqu'à la fin du coup.
static func attack_pose(attack: AttackData, t: float, tuning: TuningData) -> Dictionary:
	var poses: Array = ATTACK_POSES.get(attack.id, ATTACK_POSES[&"martelo"])
	if poses.size() == 1:
		return (poses[0] as Dictionary).duplicate()
	if t < attack.impact * tuning.hero_windup_fraction:
		return (poses[0] as Dictionary).duplicate()
	var pose: Dictionary = (poses[1] as Dictionary).duplicate()
	var recovery: float = clampf((t - attack.impact) / (attack.duration - attack.impact), 0.0, 1.0)
	pose[&"hyaw"] = float(pose[&"hyaw"]) * (1.0 - recovery * tuning.hero_hip_unwind)
	return pose


## Pose de course à la phase `walk` du cycle, avec l'entrain `amount` (0 à 1).
static func run_pose(walk: float, amount: float) -> Dictionary:
	var s: float = sin(walk)
	var c: float = cos(walk)
	var a: float = amount
	var elbow: float = RUN[&"elbow"] + RUN[&"elbow_run"] * a
	return {
		&"lLx": -s * RUN[&"leg"] * a, &"lRx": s * RUN[&"leg"] * a,
		&"kL": (RUN[&"knee"] + RUN[&"knee_lift"] * maxf(0.0, c)) * a, &"kR": (RUN[&"knee"] + RUN[&"knee_lift"] * maxf(0.0, -c)) * a,
		&"aL": RUN[&"ankle"] * a * maxf(0.0, c), &"aR": RUN[&"ankle"] * a * maxf(0.0, -c),
		&"sLx": s * RUN[&"arm"] * a, &"sRx": -s * RUN[&"arm"] * a, &"eL": elbow, &"eR": elbow,
		&"sLz": -RUN[&"shoulder_out"], &"sRz": RUN[&"shoulder_out"], &"sx": RUN[&"lean"] * a,
		&"syaw": s * RUN[&"spine_yaw"] * a, &"hyaw": s * RUN[&"hip_yaw"] * a,
		&"hy": (absf(s) - RUN[&"hip_bob_center"]) * RUN[&"hip_bob"] * a,
		&"nx": RUN[&"nod"] * a, &"nyaw": s * RUN[&"neck_yaw"] * a,
	}


## Pose de repos, avec le rebond `bounce` (1 sur le temps, puis vers 0).
static func idle_pose(bounce: float) -> Dictionary:
	var b: float = bounce
	var knee: float = IDLE[&"knee"] + IDLE[&"knee_bounce"] * b
	var leg: float = IDLE[&"leg"] + IDLE[&"leg_bounce"] * b
	return {
		&"kL": knee, &"kR": knee, &"lLx": leg, &"lRx": leg, &"aL": IDLE[&"ankle_bounce"] * b, &"aR": IDLE[&"ankle_bounce"] * b,
		&"hy": IDLE[&"hips_drop"] * b, &"sLz": -IDLE[&"shoulder"] - IDLE[&"shoulder_bounce"] * b,
		&"sRz": IDLE[&"shoulder"] + IDLE[&"shoulder_bounce"] * b, &"eL": IDLE[&"elbow"], &"eR": IDLE[&"elbow"],
		&"nx": IDLE[&"nod"] * b, &"sx": IDLE[&"lean"] * b,
	}


## Fait avancer l'animation de `delta` secondes ; `flipping` : un salto est en cours.
func update(delta: float, flipping: bool) -> void:
	if character == null:
		return
	var tuning: TuningData = Tuning.data
	var hero: Hero = owner as Hero
	var grounded: bool = hero == null or hero.is_on_floor()
	var rising: bool = hero != null and hero.velocity.y > 0.0
	var run_amount: float = minf(tuning.hero_run_max, _speed / tuning.run_speed) if mode == Mode.GROUND else 0.0
	_land = maxf(0.0, _land - delta * tuning.hero_land_crouch_decay)
	_flinch = maxf(0.0, _flinch - delta * tuning.hero_flinch_decay)
	var target: Dictionary
	var rate: float = tuning.hero_pose_rate
	match mode:
		Mode.ROLL:
			target = ROLL_POSE.duplicate()
			rate = tuning.hero_pose_rate_roll
		Mode.DASH:
			target = DASH_POSE.duplicate()
			rate = tuning.hero_pose_rate_roll
		Mode.ATTACK:
			target = attack_pose(_attack, _attack_time, tuning)
			rate = tuning.hero_pose_rate_attack
		Mode.PLUNGE:
			target = PLUNGE_POSE.duplicate()
			rate = tuning.hero_pose_rate_plunge
		_:
			if flipping:
				target = FLIP_POSE.duplicate()
				rate = tuning.hero_pose_rate_flip
			elif not grounded:
				target = (RISE_POSE if rising else FALL_POSE).duplicate()
			elif _speed >= tuning.idle_speed_threshold and mode == Mode.GROUND:
				target = _running(delta, run_amount, hero)
			else:
				target = idle_pose(exp(-_beat_phase() * tuning.hero_idle_bounce_decay))
	if _land > 0.0 and grounded and mode != Mode.ATTACK and mode != Mode.ROLL:
		_add(target, &"kL", LAND[&"knee"] * _land)
		_add(target, &"kR", LAND[&"knee"] * _land)
		_add(target, &"lLx", LAND[&"leg"] * _land)
		_add(target, &"lRx", LAND[&"leg"] * _land)
		_add(target, &"sx", LAND[&"lean"] * _land)
		_add(target, &"hy", LAND[&"hips_drop"] * _land)
		_add(target, &"sLx", LAND[&"arm"] * _land)
		_add(target, &"sRx", LAND[&"arm"] * _land)
	if _flinch > 0.0:
		_add(target, &"sx", FLINCH[&"lean"] * _flinch)
		_add(target, &"nx", FLINCH[&"nod"] * _flinch)
		target[&"sLz"] = float(target.get(&"sLz", -FLINCH[&"shoulder_rest"])) - FLINCH[&"shoulder"] * _flinch
		target[&"sRz"] = float(target.get(&"sRz", FLINCH[&"shoulder_rest"])) + FLINCH[&"shoulder"] * _flinch
	for key: StringName in REST_ARMS:
		if not target.has(key):
			target[key] = REST_ARMS[key]
	character.blend_pose(target, Smoothing.weight(rate, delta))
	character.apply_pose()
	_update_plume(delta, run_amount, grounded, rising, tuning)


func _running(delta: float, amount: float, hero: Hero) -> Dictionary:
	var tuning: TuningData = Tuning.data
	_walk += delta * (tuning.hero_run_step_base + tuning.hero_run_step_speed * amount) * minf(1.0, amount * tuning.hero_run_ramp)
	var side: int = 1 if sin(_walk) > 0.0 else -1
	if side != _step_side:
		_step_side = side
		var fx: Effects = Effects.of(self)
		if fx and hero and amount > tuning.fx_step_speed:
			fx.dust(hero.global_position - hero.facing_direction() * tuning.fx_step_back, tuning.fx_step_dust, tuning.fx_step_dust_speed)
	return run_pose(_walk, minf(1.0, amount * tuning.hero_run_amount))


func _update_plume(delta: float, amount: float, grounded: bool, rising: bool, tuning: TuningData) -> void:
	if _plume < 0:
		_plume = character.body.bone(&"plume")
		if _plume < 0:
			return
	var lift: float = 0.0 if grounded else (PLUME[&"rise"] if rising else PLUME[&"fall"])
	var goal: float = clampf(amount * PLUME[&"speed"] + lift, PLUME[&"min"], PLUME[&"max"])
	_plume_speed += ((goal - _plume_angle) * tuning.hero_plume_stiffness - _plume_speed * tuning.hero_plume_damping) * delta
	_plume_angle += _plume_speed * delta
	character.body.set_part_rotation(_plume, Vector3(_plume_angle, 0.0, 0.0))


func _beat_phase() -> float:
	if not Rhythm.is_playing():
		return 1.0
	return fposmod(Rhythm.song_time() / Rhythm.beat_length(), 1.0)


static func _add(pose: Dictionary, key: StringName, amount: float) -> void:
	pose[key] = float(pose.get(key, 0.0)) + amount
