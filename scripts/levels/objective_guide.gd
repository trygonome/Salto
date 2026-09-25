class_name ObjectiveGuide
extends Node3D
## Guidage vers l'objectif, comme dans le prototype : une flèche de cubes dorés flotte près du
## héros et pointe vers l'objectif (quand il est loin), une colonne de lumière dorée monte de
## l'objectif (quand il est plus loin encore).

## Flèche (cases) : une pointe en V.
const ARROW: Array[Vector2] = [Vector2(0.0, 1.0), Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(-2.0, -1.0), Vector2(2.0, -1.0)]
## Couleur codée des cubes de la flèche (doré vif).
const ARROW_COLOR := Vector3(2.14, 1.0, 0.6)

## Matériau voxel des petits assemblages (voxel_actor.tres) ; matériau de la colonne (beam).
@export var material: Material
@export var beam_material: Material

var _time: float = 0.0
var _arrow: Node3D
var _beam: MeshInstance3D


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	var cells := PackedFloat32Array()
	for cell: Vector2 in ARROW:
		VoxelMesh.add(cells, cell.x, 0.0, cell.y, ARROW_COLOR)
	_arrow = Node3D.new()
	_arrow.name = "Arrow"
	var cubes: MultiMeshInstance3D = VoxelMesh.create(cells, material)
	cubes.scale = Vector3.ONE * tuning.guide_arrow_voxel * tuning.voxel_unit
	_arrow.add_child(cubes)
	add_child(_arrow)
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = tuning.guide_beam_radius
	cylinder.bottom_radius = tuning.guide_beam_radius
	cylinder.height = tuning.guide_beam_height
	cylinder.cap_top = false
	cylinder.cap_bottom = false
	_beam = MeshInstance3D.new()
	_beam.name = "Beam"
	_beam.mesh = cylinder
	_beam.material_override = beam_material
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)
	_arrow.visible = false
	_beam.visible = false


## Place la flèche près de `hero` et la colonne sur l'objectif `goal` (voir VoxelNight.objective ;
## vide : rien à montrer).
func follow(hero: Node3D, goal: Dictionary) -> void:
	var tuning: TuningData = Tuning.data
	_time += get_process_delta_time()
	if goal.is_empty():
		_arrow.visible = false
		_beam.visible = false
		return
	var point: Vector3 = goal[&"point"]
	var flat := Vector3(point.x - hero.global_position.x, 0.0, point.z - hero.global_position.z)
	var distance: float = flat.length()
	_arrow.visible = distance > tuning.guide_arrow_min
	if _arrow.visible:
		var direction: Vector3 = flat / distance
		_arrow.global_position = hero.global_position + direction * tuning.guide_arrow_distance \
			+ Vector3.UP * (tuning.guide_arrow_height + sin(_time * tuning.guide_arrow_bob_speed) * tuning.guide_arrow_bob_height)
		_arrow.rotation.y = atan2(direction.x, direction.z)
	_beam.visible = distance > tuning.guide_beam_min
	_beam.global_position = Vector3(point.x, tuning.guide_beam_height / 2.0, point.z)
