class_name SilenceStone
extends Node3D
## Pierre du silence (version 3.6, première minute) : au début de la toute première expédition, la
## clairière est sombre et muette ; au milieu du chemin se dresse une pierre grise dont le glyphe
## respire à peine. La frapper (signal `struck`) rend au monde sa couleur et son premier accord.

signal struck

## Pierre, pierre claire du sommet, glyphe éteint ; glyphe réveillé (arc-en-ciel).
const STONE := Vector3(4.72, 0.1, 0.34)
const STONE_TOP := Vector3(4.72, 0.08, 0.44)
const GLYPH_DARK := Vector3(4.6, 0.05, 0.22)
const GLYPH_LIT := Vector3(3.0, 1.0, 0.62)
## Taille (cubes) : demi-largeur, hauteur ; respiration du glyphe (tours par seconde, ampleur).
const HALF := 3
const HEIGHT := 12
const BREATH := 0.35
const BREATH_AMOUNT := 0.08
## Rayon de la zone qu'on frappe (m) ; ses cubes, plus gros que ceux des petits objets.
const HIT_RADIUS := 0.6
const SIZE := 1.6

## Matériau voxel des petits assemblages (voxel_actor.tres).
var material: Material

var _struck: bool = false
var _glyph: Node3D
var _time: float = 0.0


func _ready() -> void:
	var cell: float = Tuning.data.breakable_cell * SIZE
	add_to_group(&"silence_stones")
	var cells := PackedFloat32Array()
	for x: int in range(-HALF, HALF + 1):
		for y: int in HEIGHT:
			for z: int in range(-1, 2):
				# Un monolithe qui s'affine vers le haut.
				if y > HEIGHT - 4 and absi(x) > HEIGHT - y - 1:
					continue
				VoxelMesh.add(cells, x, y + 0.5, z, STONE_TOP if y >= HEIGHT - 2 else STONE)
	var stone: MultiMeshInstance3D = VoxelMesh.create(cells, material)
	stone.scale = Vector3.ONE * cell
	add_child(stone)
	_glyph = Node3D.new()
	_glyph.name = "Glyph"
	_glyph.position = Vector3(0.0, HEIGHT * 0.55, 1.6) * cell
	_glyph.add_child(_glyph_mesh(GLYPH_DARK))
	add_child(_glyph)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(HALF * 2 + 1, HEIGHT, 3) * cell
	shape.shape = box
	shape.position = Vector3.UP * HEIGHT * cell / 2.0
	body.add_child(shape)
	add_child(body)
	var hurtbox := Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 16
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	hurtbox.radius = HIT_RADIUS
	var zone := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = HIT_RADIUS * 1.4
	zone.shape = sphere
	zone.position = Vector3.UP * HEIGHT * cell / 2.0
	hurtbox.add_child(zone)
	add_child(hurtbox)
	hurtbox.hurt.connect(_on_hurt)


## Le glyphe : une note de musique en cubes.
func _glyph_mesh(color: Vector3) -> MultiMeshInstance3D:
	var cells := PackedFloat32Array()
	for p: Vector2 in [Vector2(-1, 0), Vector2(0, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(0, 1), Vector2(0, 2), Vector2(0, 3), Vector2(1, 3), Vector2(2, 2)]:
		VoxelMesh.add(cells, p.x, p.y, 0.0, color)
	var mesh: MultiMeshInstance3D = VoxelMesh.create(cells, material)
	mesh.scale = Vector3.ONE * Tuning.data.breakable_cell * SIZE
	return mesh


func is_struck() -> bool:
	return _struck


func _process(delta: float) -> void:
	if _struck:
		return
	_time += delta
	_glyph.scale = Vector3.ONE * (1.0 + sin(_time * TAU * BREATH) * BREATH_AMOUNT)


func _on_hurt(hit: HitData) -> void:
	if _struck or not hit.attacker is Hero:
		return
	_struck = true
	_glyph.scale = Vector3.ONE
	for child: Node in _glyph.get_children():
		child.queue_free()
	_glyph.add_child(_glyph_mesh(GLYPH_LIT))
	var fx: Effects = Effects.of(self)
	if fx:
		var tuning: TuningData = Tuning.data
		fx.burst(global_position + Vector3.UP * HEIGHT * tuning.breakable_cell * SIZE * 0.6, tuning.fx_rainbow_cubes, tuning.fx_rainbow_speed)
	struck.emit()
