class_name PlumePickup
extends Node3D
## Plume arc-en-ciel posée au sommet d'un perchoir : elle tourne et flotte ; le héros qui
## l'atteint voit sa jauge de groove se remplir (de quoi lancer le Salto arc-en-ciel). Elle revient
## à la sortie suivante.

var _time: float = 0.0
var _taken: bool = false

## Une plume de cubes arc-en-ciel qui s'affinent (chacun décalé dans l'arc-en-ciel), et sa pointe.
const QUILL := 5
const QUILL_STEP := 0.8
const QUILL_COLOR := Vector3(3.0, 0.95, 0.6)
const QUILL_HUE_STEP := 0.15
const QUILL_SIZE := 0.7
const QUILL_TAPER := 0.08
const TIP := Vector3(0.5, 3.2, 0.0)
const TIP_COLOR := Vector3(3.1, 1.0, 0.65)
const TIP_SIZE := 0.45

## Matériau voxel des petits assemblages (voxel_actor.tres).
@export var material: Material

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	var cells := PackedFloat32Array()
	for i: int in QUILL:
		VoxelMesh.add(cells, 0.0, i * QUILL_STEP, 0.0, Vector3(QUILL_COLOR.x + i * QUILL_HUE_STEP, QUILL_COLOR.y, QUILL_COLOR.z), QUILL_SIZE - i * QUILL_TAPER)
	VoxelMesh.add(cells, TIP.x, TIP.y, TIP.z, TIP_COLOR, TIP_SIZE)
	var mesh: MultiMeshInstance3D = VoxelMesh.create(cells, material)
	mesh.scale = Vector3.ONE * tuning.pickup_voxel * tuning.voxel_unit
	_visual.add_child(mesh)


func _physics_process(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_time += delta
	_visual.rotation.y = _time * tuning.pickup_spin
	_visual.position.y = sin(_time * tuning.pickup_bob_speed) * tuning.pickup_bob_height
	if _taken:
		return
	var hero: Hero = get_tree().get_first_node_in_group(&"hero") as Hero
	if hero == null or hero.fainted_now:
		return
	var flat := Vector2(hero.global_position.x - global_position.x, hero.global_position.z - global_position.z)
	if flat.length() > tuning.perch_pickup_radius or absf(hero.global_position.y + tuning.perch_pickup_height - global_position.y) > tuning.perch_pickup_height * 2.0:
		return
	_taken = true
	hero.groove.add(hero.groove.maximum * tuning.perch_groove)
	var fx: Effects = Effects.of(self)
	if fx:
		fx.burst(global_position, tuning.fx_plume_cubes, tuning.fx_plume_speed)
	($Sound as AudioStreamPlayer3D).play()
	_visual.visible = false
	get_tree().create_timer(($Sound as AudioStreamPlayer3D).stream.get_length()).timeout.connect(queue_free)
