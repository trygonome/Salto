class_name SpiritStele
extends Node3D
## Stèle des esprits (version 3.4), au fond d'un recoin : une dalle de pierre et son glyphe aux
## quatre couleurs des familles de dons, qui respire. Quand le héros s'en approche, elle s'éveille
## une fois (signal `awakened`) : le niveau offre un don au choix ; le glyphe s'éteint ensuite.

signal awakened

## Pierre de la dalle, glyphe (une couleur par famille : Feu, Eau, Sève, Vent), glyphe éteint.
const STONE := Vector3(4.72, 0.14, 0.36)
const STONE_TOP := Vector3(4.3, 0.4, 0.42)
const DARK := Vector3(4.6, 0.1, 0.25)
## Taille de la dalle (cubes) : demi-largeur, hauteur, épaisseur.
const HALF := 3
const HEIGHT := 9
const DEPTH := 2
## Respiration du glyphe (tours par seconde, ampleur).
const BREATH := 0.6
const BREATH_AMOUNT := 0.12

## Matériau voxel des petits assemblages (voxel_actor.tres).
var material: Material

var _used: bool = false
var _glyph: Node3D
var _time: float = 0.0


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	add_to_group(&"steles")
	var cells := PackedFloat32Array()
	for x: int in range(-HALF, HALF + 1):
		for y: int in HEIGHT:
			for z: int in DEPTH:
				# Le haut s'arrondit.
				if y >= HEIGHT - 2 and absi(x) == HALF:
					continue
				VoxelMesh.add(cells, x, y + 0.5, z - DEPTH / 2.0, STONE_TOP if y == HEIGHT - 1 else STONE)
	var slab: MultiMeshInstance3D = VoxelMesh.create(cells, material)
	slab.scale = Vector3.ONE * tuning.breakable_cell
	add_child(slab)
	_glyph = Node3D.new()
	_glyph.name = "Glyph"
	_glyph.add_child(_glyph_mesh(false))
	_glyph.position = Vector3(0.0, 0.0, -(DEPTH / 2.0 + 0.6) * tuning.breakable_cell)
	add_child(_glyph)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3((HALF * 2 + 1), HEIGHT, DEPTH) * tuning.breakable_cell
	shape.shape = box
	shape.position = Vector3.UP * HEIGHT * tuning.breakable_cell / 2.0
	body.add_child(shape)
	add_child(body)


## Le glyphe : un losange aux quatre couleurs des familles (éteint : gris).
func _glyph_mesh(dark: bool) -> MultiMeshInstance3D:
	var cells := PackedFloat32Array()
	var families: Array[StringName] = [Boons.FEU, Boons.EAU, Boons.SEVE, Boons.VENT]
	var center_y: float = HEIGHT * 0.55
	for i: int in families.size():
		var color: Vector3 = DARK if dark else VoxelIcons.FAMILY_COLORS[families[i]]
		var dx: int = [0, 1, 0, -1][i]
		var dy: int = [1, 0, -1, 0][i]
		VoxelMesh.add(cells, dx * 1.2, center_y + dy * 1.2, 0.0, color)
		VoxelMesh.add(cells, dx * 2.2, center_y + dy * 2.2, 0.0, color, 0.7)
	VoxelMesh.add(cells, 0.0, center_y, 0.0, DARK if dark else Vector3(3.1, 1.0, 0.65))
	var mesh: MultiMeshInstance3D = VoxelMesh.create(cells, material)
	mesh.scale = Vector3.ONE * Tuning.data.breakable_cell
	return mesh


func is_used() -> bool:
	return _used


func _physics_process(delta: float) -> void:
	if _used:
		return
	_time += delta
	_glyph.scale = Vector3.ONE * (1.0 + sin(_time * TAU * BREATH) * BREATH_AMOUNT)
	var hero: Hero = get_tree().get_first_node_in_group(&"hero") as Hero
	if hero == null or hero.fainted_now:
		return
	var flat := Vector2(hero.global_position.x - global_position.x, hero.global_position.z - global_position.z)
	if flat.length() > Tuning.data.stele_radius:
		return
	_used = true
	_glyph.scale = Vector3.ONE
	for child: Node in _glyph.get_children():
		child.queue_free()
	_glyph.add_child(_glyph_mesh(true))
	var fx: Effects = Effects.of(self)
	if fx:
		fx.burst(global_position + Vector3.UP * HEIGHT * Tuning.data.breakable_cell * 0.6, Tuning.data.fx_plume_cubes, Tuning.data.fx_plume_speed)
	awakened.emit()
