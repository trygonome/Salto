class_name Villager
extends Node3D
## Villageois du prototype (animNPC) : il danse sur la musique, se balance, lève les bras un peu
## plus haut à chaque tambour rapporté ; la nuit gagnée, il enchaîne les saltos. Le Chef Taroum
## danse plus sobrement, et salue d'un salto quand il parle au héros.

## Coefficients de la danse (angles en radians, hauteur des hanches en voxels), multipliés par
## l'entrain : balancement sur chaque temps (`bounce`, 0 à 1) ou de gauche à droite (`swing`, -1 à 1).
const DANCE := {
	&"hips_drop": 0.8, &"knee": 0.15, &"knee_bounce": 0.5, &"leg": -0.08, &"leg_bounce": -0.25,
	&"arm_rest": 0.15, &"arm_raise": 2.3, &"arm_swing": 0.35, &"elbow": -0.4, &"elbow_bounce": -0.6,
	&"hip_roll": 0.12, &"spine_yaw": 0.2, &"nod": 0.15, &"sway_speed": 0.5,
}
## Pose du salto, multipliée par l'élan du saut (0 à 1 à 0), sauf les épaules écartées.
const FLIP_POSE := {
	&"lLx": -1.8, &"lRx": -1.8, &"kL": 2.2, &"kR": 2.2, &"sLx": -1.0, &"sRx": -1.0, &"eL": -1.5, &"eR": -1.5, &"sx": 0.5,
}
const FLIP_ARMS := {&"sLz": -0.3, &"sRz": 0.3}

## Le Chef Taroum (sinon un danseur).
var is_chief: bool = false

var _body: VoxelCharacter
## Orientation de repos (rad), décalage de la danse (temps), salto en cours (0 à 1 ; -1 : aucun).
var _base_yaw: float = 0.0
var _phase: float = 0.0
var _flip: float = -1.0
var _next_flip: float = 0.0
var _time: float = 0.0
var _rng := RandomNumberGenerator.new()


## Prépare le villageois : style (VoxelStyles) et sa clé (maillage partagé), taille, orientation de repos, décalage de la
## danse (en temps de musique) et instant de son premier salto de fête (s).
func setup(style: Dictionary, key: String, size: float, base_yaw: float, phase: float, first_flip: float, voxel_material: Material, shadow_material: Material, shadow_radius: float) -> void:
	_rng.randomize()
	_base_yaw = base_yaw
	_phase = phase
	_next_flip = first_flip
	rotation.y = base_yaw
	_body = VoxelCharacter.new()
	_body.name = "Body"
	_body.material = voxel_material
	add_child(_body)
	_body.build(style, size, key)
	var shadow := BlobShadow.new()
	shadow.name = "Shadow"
	shadow.radius = shadow_radius
	shadow.material = shadow_material
	add_child(shadow)
	if is_chief:
		add_to_group(&"chief")


## Salue le héros d'un salto (le Chef, quand il lui parle).
func greet() -> void:
	if _flip < 0.0:
		_flip = 0.0


## Entrain de la danse pour `drums` tambours rapportés (nuit gagnée : au plus haut).
static func dance_amount(drums: int, won: bool, tuning: TuningData) -> float:
	if won:
		return tuning.villager_dance_won
	return tuning.villager_dance_base + tuning.villager_dance_per_drum * drums


func _process(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_time += delta
	var won: bool = Game.progress.is_complete()
	var amount: float = dance_amount(Game.progress.drums_returned, won, tuning)
	if is_chief:
		amount *= tuning.chief_dance_factor
	var beats: float = _time / Rhythm.beat_length()
	if Rhythm.is_playing():
		beats = Rhythm.song_time() / Rhythm.beat_length()
	beats += _phase
	var swing: float = sin(beats * PI)
	var bounce: float = absf(swing)
	if _flip >= 0.0:
		_flip += delta / tuning.villager_flip_time
		if _flip >= 1.0:
			_flip = -1.0
			_next_flip = _time + _rng.randf_range(tuning.villager_flip_gap_min, tuning.villager_flip_gap_max)
	elif won and not is_chief and _time > _next_flip:
		_flip = 0.0
	var target: Dictionary = {}
	var lift: float = 0.0
	var spin: float = 0.0
	if _flip >= 0.0:
		var jump: float = sin(PI * _flip)
		lift = jump * tuning.villager_flip_height
		spin = -TAU * Smoothing.ease_in_out(_flip)
		for key: StringName in FLIP_POSE:
			target[key] = FLIP_POSE[key] * jump
		target.merge(FLIP_ARMS)
	else:
		var up: float = DANCE[&"arm_rest"] + DANCE[&"arm_raise"] * minf(1.0, amount)
		var knee: float = DANCE[&"knee"] + bounce * DANCE[&"knee_bounce"] * amount
		var leg: float = DANCE[&"leg"] + bounce * DANCE[&"leg_bounce"] * amount
		var elbow: float = DANCE[&"elbow"] + DANCE[&"elbow_bounce"] * bounce * amount
		target = {
			&"hy": -bounce * DANCE[&"hips_drop"] * amount, &"kL": knee, &"kR": knee, &"lLx": leg, &"lRx": leg,
			&"sLz": -up + swing * DANCE[&"arm_swing"] * amount, &"sRz": up - swing * DANCE[&"arm_swing"] * amount,
			&"eL": elbow, &"eR": elbow, &"hz": swing * DANCE[&"hip_roll"] * amount,
			&"syaw": swing * DANCE[&"spine_yaw"] * amount, &"nx": bounce * DANCE[&"nod"] * amount,
		}
	_body.blend_pose(target, Smoothing.weight(tuning.villager_pose_rate, delta))
	_body.apply_pose()
	_body.spin.rotation.x = spin
	_body.position.y = lift
	rotation.y = _base_yaw + sin(beats * PI * DANCE[&"sway_speed"]) * tuning.villager_sway * amount
	_body.update_blink(delta)
