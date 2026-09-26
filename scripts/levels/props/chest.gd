extends Node3D
## Coffre des anciens, en cubes comme le reste du monde : le toucher l'ouvre. Il donne une page du
## carnet, et le rythme qu'il gardait remplit la jauge de groove (gerbe arc-en-ciel). Un coffre
## caché peut n'apparaître qu'une fois révélé (cercle des gongs). Si sa page est déjà dans le
## carnet, il est ouvert et vide.

## Page du carnet qu'il contient (numéro à partir de 1).
@export var page: int
## Caché au départ (révélé par reveal()).
@export var hidden: bool
## Ouverture du couvercle (degrés) et sa durée (s).
@export var lid_open_deg: float
@export var open_time: float
## Profondeur d'où il surgit quand il est révélé (m) et durée (s).
@export var rise_depth: float
@export var rise_time: float
## Matériau voxel des petits assemblages (voxel_actor.tres) et taille d'une case (m).
@export var material: Material
@export var cell: float

## Caisse (cases : demi-largeur, hauteur, demi-profondeur), couvercle (épaisseur), couleurs codées
## (mode 2, fixes) : bois, bois sombre, bandes et serrure dorées.
const HALF_X := 4
const HEIGHT := 5
const HALF_Z := 3
const LID := 2
const WOOD := Vector3(2.07, 0.6, 0.3)
const DARK := Vector3(2.06, 0.55, 0.2)
const GOLD := Vector3(2.12, 0.9, 0.55)

var _opened: bool = false

@onready var _lid: Node3D = $Lid
@onready var _zone: Area3D = $Zone
@onready var _body: CollisionShape3D = $Body/CollisionShape3D
@onready var _sound: AudioStreamPlayer3D = $OpenSound


func _ready() -> void:
	var base := PackedFloat32Array()
	for x: int in range(-HALF_X, HALF_X + 1):
		for z: int in range(-HALF_Z, HALF_Z + 1):
			for y: int in HEIGHT:
				var edge: bool = absi(x) == HALF_X or absi(z) == HALF_Z or y == 0
				if not edge:
					continue
				var band: bool = absi(x) == HALF_X - 1 or (z == HALF_Z and x == 0 and y >= HEIGHT - 2)
				VoxelMesh.add(base, x, y + 0.5, z, GOLD if band else (DARK if y == 0 else WOOD))
	var base_mesh: MultiMeshInstance3D = VoxelMesh.create(base, material)
	base_mesh.scale = Vector3.ONE * cell
	add_child(base_mesh)
	var lid := PackedFloat32Array()
	for x: int in range(-HALF_X, HALF_X + 1):
		for z: int in range(0, HALF_Z * 2 + 1):
			for y: int in LID:
				VoxelMesh.add(lid, x, y + 0.5, z, GOLD if absi(x) == HALF_X - 1 else WOOD)
	var lid_mesh: MultiMeshInstance3D = VoxelMesh.create(lid, material)
	lid_mesh.scale = Vector3.ONE * cell
	_lid.add_child(lid_mesh)
	# Charnière à l'arrière, sur la caisse.
	_lid.position = Vector3(0.0, HEIGHT * cell, -(HALF_Z + 0.5) * cell)
	lid_mesh.position = Vector3(0.0, 0.0, 0.5 * cell)
	_zone.body_entered.connect(_on_body_entered)
	if Game.profile.has_page(page):
		# Déjà trouvé : il attend, ouvert et vide.
		_opened = true
		_lid.rotation.x = deg_to_rad(-lid_open_deg)
	if hidden:
		visible = false
		_body.set_deferred(&"disabled", true)
		_zone.set_deferred(&"monitoring", false)


## Fait surgir le coffre caché.
func reveal() -> void:
	visible = true
	_body.set_deferred(&"disabled", false)
	_zone.set_deferred(&"monitoring", true)
	var rest: Vector3 = position
	position = rest + Vector3.DOWN * rise_depth
	create_tween().tween_property(self, "position", rest, rise_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Vrai une fois ouvert (ou trouvé lors d'une nuit précédente).
func is_opened() -> bool:
	return _opened


func _on_body_entered(body: Node3D) -> void:
	var hero: Hero = body as Hero
	if _opened or hero == null:
		return
	_opened = true
	_sound.play()
	create_tween().tween_property(_lid, "rotation:x", deg_to_rad(-lid_open_deg), open_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var tuning: TuningData = Tuning.data
	hero.groove.add(hero.groove.maximum * tuning.perch_groove)
	var fx: Effects = Effects.of(self)
	if fx:
		fx.burst(global_position + Vector3.UP * HEIGHT * cell, tuning.fx_plume_cubes, tuning.fx_plume_speed)
	Game.add_page(page)
