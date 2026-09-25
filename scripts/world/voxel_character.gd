class_name VoxelCharacter
extends Node3D
## Personnage articulé en voxels du prototype (makeChar) : grosse tête, torse, bras et jambes à deux
## segments, chaque partie faite de petits cubes, le tout en un seul maillage (VoxelRig). Les
## articulations suivent une pose (mêmes clés que le prototype) qu'on fait glisser vers une pose
## visée. Les dimensions sont en voxels ; le tout est mis à l'échelle (Tuning.character_voxel en
## unités du prototype).

## Clés d'une pose (angles en radians, hy en voxels).
const POSE_KEYS: Array[StringName] = [
	&"hy", &"hx", &"hyaw", &"hz", &"sx", &"syaw", &"nx", &"nyaw", &"sLx", &"sLz", &"sRx", &"sRz",
	&"eL", &"eR", &"lLx", &"lRx", &"lLz", &"lRz", &"kL", &"kR", &"aL", &"aR",
]
## Hauteur des hanches et du pivot des saltos (voxels).
const HIP_Y := 7.0
const MID_Y := 10.0

## Matériau des assemblages articulés (voxel_rig.tres).
@export var material: Material

var pose: Dictionary = {}
var spin: Node3D
var body: VoxelRig

var _joints: Dictionary = {}
var _eyes: int = -1
var _blink: float = 0.0
var _rng := RandomNumberGenerator.new()


## Construit le personnage avec le style `style` (couleurs des parties, voir VoxelStyles) et un
## facteur de taille ; les personnages de même `key` partagent leur maillage.
func build(style: Dictionary, size: float, key: String = "") -> void:
	var tuning: TuningData = Tuning.data
	var k: float = tuning.character_voxel * tuning.voxel_unit * size
	_rng.randomize()
	_blink = _rng.randf_range(tuning.blink_min, tuning.blink_max)
	spin = Node3D.new()
	spin.position.y = MID_Y * k
	add_child(spin)
	body = VoxelRig.new()
	body.scale = Vector3.ONE * k
	body.position.y = -MID_Y * k
	spin.add_child(body)
	var parts: Dictionary = VoxelStyles.character_parts(style)
	body.add_part(&"hips", &"", Vector3(0.0, HIP_Y, 0.0), parts[&"pelvis"])
	body.add_part(&"spine", &"hips", Vector3(0.0, 2.0, 0.0), parts[&"torso"])
	body.add_part(&"neck", &"spine", Vector3(0.0, 5.6, 0.0), parts[&"head"])
	body.add_part(&"eyes", &"neck", Vector3.ZERO, parts[&"eyes"])
	for side: int in [-1, 1]:
		var suffix: String = "L" if side < 0 else "R"
		body.add_part(StringName("hip" + suffix), &"hips", Vector3(side * 1.5, 0.0, 0.0), parts[&"thigh"])
		body.add_part(StringName("knee" + suffix), StringName("hip" + suffix), Vector3(0.0, -3.0, 0.0), parts[&"shin"])
		body.add_part(StringName("ankle" + suffix), StringName("knee" + suffix), Vector3(0.0, -3.0, 0.0), parts[&"foot"])
		body.add_part(StringName("sh" + suffix), &"spine", Vector3(side * 4.0, 4.4, 0.0), parts[&"upper"])
		body.add_part(StringName("el" + suffix), StringName("sh" + suffix), Vector3(0.0, -3.0, 0.0), parts[&"fore"])
	if parts.has(&"plume"):
		body.add_part(&"plume", &"neck", Vector3(1.8, 5.6, -2.2), parts[&"plume"])
	body.build(material, key)
	for joint: StringName in [&"hips", &"spine", &"neck", &"shL", &"shR", &"elL", &"elR", &"hipL", &"hipR", &"kneeL", &"kneeR", &"ankleL", &"ankleR"]:
		_joints[joint] = body.bone(joint)
	_eyes = body.bone(&"eyes")
	pose = new_pose()
	apply_pose()


## Pose de repos du prototype.
static func new_pose() -> Dictionary:
	var p: Dictionary = {}
	for key: StringName in POSE_KEYS:
		p[key] = 0.0
	p[&"sLz"] = -0.15
	p[&"sRz"] = 0.15
	p[&"eL"] = -0.3
	p[&"eR"] = -0.3
	return p


## Rapproche la pose de `target` (clés absentes : 0) d'une part `weight` (0 à 1).
func blend_pose(target: Dictionary, weight: float) -> void:
	for key: StringName in POSE_KEYS:
		var goal: float = target.get(key, 0.0)
		pose[key] = pose[key] + (goal - pose[key]) * weight


## Place les articulations selon la pose.
func apply_pose() -> void:
	var p: Dictionary = pose
	body.set_part_position(_joints[&"hips"], Vector3(0.0, HIP_Y + p[&"hy"], 0.0))
	body.set_part_rotation(_joints[&"hips"], Vector3(p[&"hx"], p[&"hyaw"], p[&"hz"]))
	body.set_part_rotation(_joints[&"spine"], Vector3(p[&"sx"], p[&"syaw"], 0.0))
	body.set_part_rotation(_joints[&"neck"], Vector3(p[&"nx"], p[&"nyaw"], 0.0))
	body.set_part_rotation(_joints[&"shL"], Vector3(p[&"sLx"], 0.0, p[&"sLz"]))
	body.set_part_rotation(_joints[&"shR"], Vector3(p[&"sRx"], 0.0, p[&"sRz"]))
	body.set_part_rotation(_joints[&"elL"], Vector3(p[&"eL"], 0.0, 0.0))
	body.set_part_rotation(_joints[&"elR"], Vector3(p[&"eR"], 0.0, 0.0))
	body.set_part_rotation(_joints[&"hipL"], Vector3(p[&"lLx"], 0.0, p[&"lLz"]))
	body.set_part_rotation(_joints[&"hipR"], Vector3(p[&"lRx"], 0.0, p[&"lRz"]))
	body.set_part_rotation(_joints[&"kneeL"], Vector3(p[&"kL"], 0.0, 0.0))
	body.set_part_rotation(_joints[&"kneeR"], Vector3(p[&"kR"], 0.0, 0.0))
	body.set_part_rotation(_joints[&"ankleL"], Vector3(p[&"aL"], 0.0, 0.0))
	body.set_part_rotation(_joints[&"ankleR"], Vector3(p[&"aR"], 0.0, 0.0))


## Clignement des yeux, de temps en temps.
func update_blink(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_blink -= delta
	if _blink < -tuning.blink_time:
		_blink = _rng.randf_range(tuning.blink_min, tuning.blink_max)
	body.set_part_scale(_eyes, Vector3(1.0, tuning.blink_squash if _blink < 0.0 else 1.0, 1.0))
