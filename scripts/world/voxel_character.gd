class_name VoxelCharacter
extends Node3D
## Personnage articulé en voxels du prototype (makeChar) : grosse tête, torse, bras et jambes à deux
## segments, chaque partie faite de petits cubes. Les articulations suivent une pose (mêmes clés que
## le prototype) qu'on fait glisser vers une pose visée. Les dimensions sont en voxels ; le tout est
## mis à l'échelle (Tuning.character_voxel en unités du prototype).

## Clés d'une pose (angles en radians, hy en voxels).
const POSE_KEYS: Array[StringName] = [
	&"hy", &"hx", &"hyaw", &"hz", &"sx", &"syaw", &"nx", &"nyaw", &"sLx", &"sLz", &"sRx", &"sRz",
	&"eL", &"eR", &"lLx", &"lRx", &"lLz", &"lRz", &"kL", &"kR", &"aL", &"aR",
]
## Hauteur des hanches et du pivot des saltos (voxels).
const HIP_Y := 7.0
const MID_Y := 10.0

## Matériau voxel des personnages (sans transparence).
@export var material: Material

var pose: Dictionary = {}
var spin: Node3D
var body: Node3D

var _joints: Dictionary = {}
var _eyes: Node3D
var _blink: float = 0.0
var _rng := RandomNumberGenerator.new()


## Construit le personnage avec le style `style` (couleurs des parties, voir VoxelStyles) et un
## facteur de taille.
func build(style: Dictionary, size: float) -> void:
	var tuning: TuningData = Tuning.data
	var k: float = tuning.character_voxel * tuning.voxel_unit * size
	_rng.randomize()
	_blink = _rng.randf_range(tuning.blink_min, tuning.blink_max)
	spin = Node3D.new()
	spin.position.y = MID_Y * k
	add_child(spin)
	body = Node3D.new()
	body.scale = Vector3.ONE * k
	body.position.y = -MID_Y * k
	spin.add_child(body)
	var parts: Dictionary = VoxelStyles.character_parts(style)
	var hips: Node3D = _joint(&"hips", body, Vector3(0.0, HIP_Y, 0.0), parts[&"pelvis"])
	var spine: Node3D = _joint(&"spine", hips, Vector3(0.0, 2.0, 0.0), parts[&"torso"])
	var neck: Node3D = _joint(&"neck", spine, Vector3(0.0, 5.6, 0.0), parts[&"head"])
	_eyes = VoxelMesh.create(parts[&"eyes"], material)
	neck.add_child(_eyes)
	for side: int in [-1, 1]:
		var suffix: String = "L" if side < 0 else "R"
		var hip: Node3D = _joint(StringName("hip" + suffix), hips, Vector3(side * 1.5, 0.0, 0.0), parts[&"thigh"])
		var knee: Node3D = _joint(StringName("knee" + suffix), hip, Vector3(0.0, -3.0, 0.0), parts[&"shin"])
		_joint(StringName("ankle" + suffix), knee, Vector3(0.0, -3.0, 0.0), parts[&"foot"])
		var shoulder: Node3D = _joint(StringName("sh" + suffix), spine, Vector3(side * 4.0, 4.4, 0.0), parts[&"upper"])
		_joint(StringName("el" + suffix), shoulder, Vector3(0.0, -3.0, 0.0), parts[&"fore"])
	if parts.has(&"plume"):
		_joint(&"plume", neck, Vector3(1.8, 5.6, -2.2), parts[&"plume"])
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
	var hips: Node3D = _joints[&"hips"]
	hips.position.y = HIP_Y + p[&"hy"]
	hips.rotation = Vector3(p[&"hx"], p[&"hyaw"], p[&"hz"])
	(_joints[&"spine"] as Node3D).rotation = Vector3(p[&"sx"], p[&"syaw"], 0.0)
	(_joints[&"neck"] as Node3D).rotation = Vector3(p[&"nx"], p[&"nyaw"], 0.0)
	(_joints[&"shL"] as Node3D).rotation = Vector3(p[&"sLx"], 0.0, p[&"sLz"])
	(_joints[&"shR"] as Node3D).rotation = Vector3(p[&"sRx"], 0.0, p[&"sRz"])
	(_joints[&"elL"] as Node3D).rotation = Vector3(p[&"eL"], 0.0, 0.0)
	(_joints[&"elR"] as Node3D).rotation = Vector3(p[&"eR"], 0.0, 0.0)
	(_joints[&"hipL"] as Node3D).rotation = Vector3(p[&"lLx"], 0.0, p[&"lLz"])
	(_joints[&"hipR"] as Node3D).rotation = Vector3(p[&"lRx"], 0.0, p[&"lRz"])
	(_joints[&"kneeL"] as Node3D).rotation = Vector3(p[&"kL"], 0.0, 0.0)
	(_joints[&"kneeR"] as Node3D).rotation = Vector3(p[&"kR"], 0.0, 0.0)
	(_joints[&"ankleL"] as Node3D).rotation = Vector3(p[&"aL"], 0.0, 0.0)
	(_joints[&"ankleR"] as Node3D).rotation = Vector3(p[&"aR"], 0.0, 0.0)


## Clignement des yeux, de temps en temps.
func update_blink(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_blink -= delta
	if _blink < -tuning.blink_time:
		_blink = _rng.randf_range(tuning.blink_min, tuning.blink_max)
	_eyes.scale.y = tuning.blink_squash if _blink < 0.0 else 1.0


func _joint(joint_name: StringName, parent: Node3D, at: Vector3, cells: PackedFloat32Array) -> Node3D:
	var joint := Node3D.new()
	joint.name = joint_name
	joint.rotation_order = EULER_ORDER_XYZ
	joint.position = at
	if not cells.is_empty():
		joint.add_child(VoxelMesh.create(cells, material))
	parent.add_child(joint)
	_joints[joint_name] = joint
	return joint
