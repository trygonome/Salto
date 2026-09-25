class_name Fruit
extends Node3D
## Fruit laissé par un Muet libéré : il flotte en tournant ; le héros qui le touche reprend une
## part de ses PV. Il clignote puis disparaît s'il n'est pas ramassé à temps.

## Un fruit de cubes dorés et sa feuille.
const FRUIT_COLOR := Vector3(3.95, 1.0, 0.55)
const LEAF := Vector3(0.0, 1.9, 0.0)
const LEAF_COLOR := Vector3(2.3, 0.9, 0.4)
const LEAF_SIZE := 0.6
const SIDE := 2

## Matériau voxel des petits assemblages (voxel_actor.tres).
@export var material: Material

var _time: float = 0.0
var _life: float = 0.0

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	_life = tuning.fruit_life
	_time = randf() * TAU
	var cells := PackedFloat32Array()
	VoxelMesh.box(cells, -0.5 - 0.5, -0.5 + SIDE - 0.5, -0.5, -0.5 + SIDE, -0.5 - 0.5, -0.5 + SIDE - 0.5, func(_x: float, _y: float, _z: float) -> Vector3: return FRUIT_COLOR)
	VoxelMesh.add(cells, LEAF.x, LEAF.y, LEAF.z, LEAF_COLOR, LEAF_SIZE)
	var mesh: MultiMeshInstance3D = VoxelMesh.create(cells, material)
	mesh.scale = Vector3.ONE * tuning.fruit_voxel * tuning.voxel_unit
	_visual.add_child(mesh)


func _physics_process(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_time += delta
	_life -= delta
	_visual.position.y = tuning.fruit_float_height + sin(_time * tuning.pickup_bob_speed) * tuning.pickup_bob_height
	_visual.rotation.y = _time * tuning.pickup_spin
	_visual.visible = _life > tuning.fruit_blink_time or fposmod(_time * tuning.fruit_blink_rate, 1.0) < 0.5
	if _life <= 0.0:
		queue_free()
		return
	var hero: Hero = get_tree().get_first_node_in_group(&"hero") as Hero
	if hero == null or hero.fainted_now:
		return
	var flat := Vector2(hero.global_position.x - global_position.x, hero.global_position.z - global_position.z)
	if flat.length() > tuning.fruit_pickup_radius or hero.global_position.y - global_position.y > tuning.fruit_pickup_height:
		return
	var amount: float = roundf(hero.health.maximum * tuning.fruit_heal)
	hero.health.heal(amount)
	var fx: Effects = Effects.of(self)
	if fx:
		fx.word(GameTexts.WORD_HEAL % amount, hero.global_position + Vector3.UP * tuning.hero_height, fx.green)
		fx.burst(global_position + Vector3.UP * tuning.fruit_float_height, tuning.fx_fruit_cubes, tuning.fx_fruit_speed, tuning.fx_fruit_hue)
	var sound: AudioStreamPlayer3D = $Sound
	sound.reparent(get_parent())
	sound.play()
	sound.finished.connect(sound.queue_free)
	queue_free()
