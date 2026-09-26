class_name Gong
extends Node3D
## Gong du cercle des anciens, en cubes comme le reste du monde : deux montants de bois, une barre,
## un disque doré suspendu. Il sonne (sa note de la gamme pentatonique), se balance et lance un
## anneau doré quand on le frappe ou quand le cercle joue sa mélodie ; un anneau violet quand on
## se trompe.

## Le gong vient d'être frappé par le héros.
signal struck(gong: Gong)

## Position dans le cercle (numéro utilisé par la mélodie).
@export var index: int
## Hauteur de sa note, en demi-tons au-dessus du son de base.
@export var semitones: float
## Couleur de l'anneau quand il sonne, quand on se trompe ; rayon (m) et durée (s) de l'anneau.
@export var glow_color: Color
@export var error_color: Color
@export var glow_radius: float
@export var glow_time: float
## Balancement du disque quand il sonne (degrés), et grossissement.
@export var swing_deg: float
@export var ring_scale: float
## Matériau voxel des petits assemblages (voxel_actor.tres) et taille d'une case (m).
@export var material: Material
@export var cell: float

## Montants et barre (cases), disque (rayon, centre sous la barre), couleurs codées (voir
## salto_voxel.gdshaderinc : mode 2, couleurs fixes).
const POST_X := 6
const POST_HEIGHT := 15
const DISC_RADIUS := 4.2
const DISC_DROP := 5.5
const WOOD := Vector3(2.07, 0.55, 0.28)
const BAR := Vector3(2.06, 0.5, 0.34)
const GOLD := Vector3(2.11, 0.85, 0.52)
const RIM := Vector3(2.09, 0.8, 0.4)
const BOSS := Vector3(2.12, 0.9, 0.68)

@onready var _disc: Node3D = $Disc
@onready var _sound: AudioStreamPlayer3D = $Sound
@onready var _hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	var frame := PackedFloat32Array()
	for side: int in [-1, 1]:
		for y: int in POST_HEIGHT:
			VoxelMesh.add(frame, side * POST_X, y + 0.5, 0.0, WOOD, 1.2)
	for x: int in range(-POST_X - 1, POST_X + 2):
		VoxelMesh.add(frame, x, POST_HEIGHT + 0.5, 0.0, BAR, 1.3)
	var frame_mesh: MultiMeshInstance3D = VoxelMesh.create(frame, material)
	frame_mesh.scale = Vector3.ONE * cell
	add_child(frame_mesh)
	var disc := PackedFloat32Array()
	var reach: int = ceili(DISC_RADIUS)
	for x: int in range(-reach, reach + 1):
		for y: int in range(-reach, reach + 1):
			var d: float = Vector2(x, y).length()
			if d > DISC_RADIUS:
				continue
			var color: Vector3 = BOSS if d < 1.2 else (RIM if d > DISC_RADIUS - 1.0 else GOLD)
			VoxelMesh.add(disc, x, y - DISC_DROP, 0.0, color)
	var disc_mesh: MultiMeshInstance3D = VoxelMesh.create(disc, material)
	disc_mesh.scale = Vector3.ONE * cell
	_disc.add_child(disc_mesh)
	_disc.position = Vector3.UP * POST_HEIGHT * cell
	_hurtbox.hurt.connect(_on_hurt)


## Fait sonner le gong.
func ring() -> void:
	_sound.pitch_scale = pow(2.0, semitones / Hero.SEMITONES_PER_OCTAVE)
	_sound.play()
	_glow(glow_color)
	_disc.rotation.x = deg_to_rad(swing_deg)
	_disc.scale = Vector3.ONE * ring_scale
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_disc, "rotation:x", 0.0, glow_time).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_disc, "scale", Vector3.ONE, glow_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Anneau d'erreur (mauvais gong frappé).
func flash_error() -> void:
	_glow(error_color)


## Centre du disque (m).
func disc_center() -> Vector3:
	return _disc.global_position + Vector3.DOWN * DISC_DROP * cell


func _glow(color: Color) -> void:
	var fx: Effects = Effects.of(self)
	if fx:
		fx.ring(global_position, glow_radius, color, glow_time)


func _on_hurt(_hit: HitData) -> void:
	ring()
	struck.emit(self)
