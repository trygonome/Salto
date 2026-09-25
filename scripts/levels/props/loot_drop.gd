class_name LootDrop
extends Node3D
## Butin du prototype : un petit objet de cubes aux couleurs de sa rareté, qui flotte en tournant
## sous une colonne de lumière de la même couleur. Le héros le ramasse en passant dessus ; il va
## dans le sac (s'il est plein, il est recyclé en plumes).

## Couleur codée des cubes (voir voxel.gdshader) et de la colonne, par rareté (commun, rare,
## épique, légendaire).
const RARITY_CUBES: Array[Vector3] = [Vector3(2.75, 0.15, 0.85), Vector3(2.58, 0.9, 0.6), Vector3(2.78, 0.8, 0.66), Vector3(2.12, 1.0, 0.58)]
## Forme de l'objet (cases) ; le sommet est un peu plus clair.
const SHAPE: Array[Vector3] = [
	Vector3(0.0, 0.0, 0.0), Vector3(0.9, 0.0, 0.0), Vector3(-0.9, 0.0, 0.0), Vector3(0.0, 0.0, 0.9),
	Vector3(0.0, 0.0, -0.9), Vector3(0.0, 0.9, 0.0), Vector3(0.0, 1.7, 0.0),
]
const TOP_ABOVE := 1.0
const TOP_LIGHTER := 0.12

## Couleur de la colonne par rareté, et son opacité (de base, et en plus par rang de rareté).
@export var rarity_colors: Array[Color]
@export var beam_alpha: float
@export var beam_alpha_per_rarity: float
@export var material: Material

## Objet contenu (tiré au sort s'il n'est pas donné).
var item: ItemData

var _time: float = 0.0
var _taken: bool = false

@onready var _visual: Node3D = $Visual
@onready var _beam: MeshInstance3D = $Beam
@onready var _sound: AudioStreamPlayer3D = $PickupSound
@onready var _rare_sound: AudioStreamPlayer3D = $RareSound


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	if item == null:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		item = ItemMath.roll_item(rng, Game.night, tuning.loot_boss_weights, tuning)
	var color: Vector3 = RARITY_CUBES[item.rarity]
	var cells := PackedFloat32Array()
	for cell: Vector3 in SHAPE:
		VoxelMesh.add(cells, cell.x, cell.y, cell.z, Vector3(color.x, color.y, color.z + (TOP_LIGHTER if cell.y > TOP_ABOVE else 0.0)))
	var mesh: MultiMeshInstance3D = VoxelMesh.create(cells, material)
	mesh.scale = Vector3.ONE * tuning.loot_voxel * tuning.voxel_unit
	_visual.add_child(mesh)
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = tuning.loot_beam_radius
	beam_mesh.bottom_radius = tuning.loot_beam_radius
	beam_mesh.height = tuning.loot_beam_height
	beam_mesh.cap_top = false
	beam_mesh.cap_bottom = false
	_beam.mesh = beam_mesh
	_beam.position.y = tuning.loot_beam_height / 2.0
	var glow: StandardMaterial3D = (_beam.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
	glow.albedo_color = Color(rarity_colors[item.rarity], beam_alpha + beam_alpha_per_rarity * item.rarity)
	_beam.material_override = glow
	if item.rarity >= ItemData.Rarity.EPIC:
		_rare_sound.play()


func _physics_process(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_time += delta
	_visual.position.y = tuning.loot_float_height + sin(_time * tuning.loot_bob_speed) * tuning.loot_bob_height
	_visual.rotation.y = _time * tuning.loot_spin
	if _taken:
		return
	var hero: Hero = get_tree().get_first_node_in_group(&"hero") as Hero
	if hero == null or hero.fainted_now:
		return
	var flat := Vector2(hero.global_position.x - global_position.x, hero.global_position.z - global_position.z)
	if flat.length() > tuning.loot_pickup_radius or hero.global_position.y - global_position.y > tuning.loot_pickup_height:
		return
	_taken = true
	var fx: Effects = Effects.of(self)
	if fx:
		fx.burst(hero.global_position + Vector3.UP * tuning.hero_height, tuning.fx_loot_cubes, tuning.fx_loot_speed)
	Game.add_item(item)
	_sound.play()
	_visual.visible = false
	_beam.visible = false
	get_tree().create_timer(_sound.stream.get_length()).timeout.connect(queue_free)
