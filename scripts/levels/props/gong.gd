class_name Gong
extends Node3D
## Gong du cercle des anciens : il sonne et brille quand on le frappe ou quand le cercle joue
## sa mélodie. Chaque gong a sa note (gamme pentatonique).

## Le gong vient d'être frappé par le héros.
signal struck(gong: Gong)

## Position dans le cercle (numéro utilisé par la mélodie).
@export var index: int
## Hauteur de sa note, en demi-tons au-dessus du son de base.
@export var semitones: float
## Couleur et intensité de la lueur quand il sonne, et durée de la lueur (s).
@export var glow_color: Color
@export var error_color: Color
@export var glow_energy: float
@export var glow_time: float
## Balancement du disque quand il sonne (degrés).
@export var swing_deg: float

var _material: StandardMaterial3D
var _glow_left: float = 0.0

@onready var _disc: MeshInstance3D = $Frame/Disc
@onready var _sound: AudioStreamPlayer3D = $Sound
@onready var _hurtbox: Hurtbox = $Hurtbox


func _ready() -> void:
	_material = (_disc.mesh.surface_get_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
	_material.emission_enabled = true
	_material.emission_energy_multiplier = 0.0
	_disc.material_override = _material
	_hurtbox.hurt.connect(_on_hurt)


## Fait sonner le gong.
func ring() -> void:
	_sound.pitch_scale = pow(2.0, semitones / Hero.SEMITONES_PER_OCTAVE)
	_sound.play()
	_glow(glow_color)
	var tween: Tween = create_tween()
	_disc.rotation.x = deg_to_rad(swing_deg)
	tween.tween_property(_disc, "rotation:x", 0.0, glow_time).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Lueur d'erreur (mauvais gong frappé).
func flash_error() -> void:
	_glow(error_color)


func _glow(color: Color) -> void:
	_material.emission = color
	_glow_left = glow_time


func _on_hurt(_hit: HitData) -> void:
	ring()
	struck.emit(self)


func _process(delta: float) -> void:
	if _glow_left > 0.0:
		_glow_left = maxf(_glow_left - delta, 0.0)
		_material.emission_energy_multiplier = glow_energy * _glow_left / glow_time
