class_name MuetBody
extends Node3D
## Apparence d'un Muet, en formes rondes : corps violet désaturé, grands yeux, bouche cousue,
## antennes aux couleurs volées. Brille en blanc quand il est touché, fait tourner des étoiles
## quand il est étourdi, rougit quand il enrage, retrouve des couleurs vives quand il est libéré.
## Le modèle mesure 1 m de haut : setup() le met à la taille de l'espèce.

## Couleur du corps.
@export var body_color: Color
## Couleur du corps libéré.
@export var freed_color: Color
## Couleur du corps en rage (Grand Muet, phase 2).
@export var enraged_color: Color
## Couleur de l'éclat quand il est touché.
@export var flash_color: Color
## Intensité de l'éclat.
@export var flash_energy: float
## Grossissement au moment de la libération, avant de disparaître.
@export var freed_pop_scale: float
## Vitesse de rotation des étoiles d'étourdissement (rad/s).
@export var stars_spin_speed: float

var _material: StandardMaterial3D
var _flash_left: float = 0.0
var _flash_time: float = 0.0

@onready var _pivot: Node3D = $Pivot
@onready var _torso: MeshInstance3D = $Pivot/Torso
@onready var _stars: Node3D = $Pivot/Stars


func setup(height: float) -> void:
	_pivot.scale = Vector3.ONE * height
	_material = (_torso.mesh.surface_get_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
	_material.albedo_color = body_color
	_material.emission_enabled = true
	_material.emission = flash_color
	_material.emission_energy_multiplier = 0.0
	_torso.material_override = _material
	_stars.visible = false


func flash(duration: float) -> void:
	_flash_time = duration
	_flash_left = duration


func set_stunned(stunned: bool) -> void:
	_stars.visible = stunned


func set_enraged(enraged: bool) -> void:
	_material.albedo_color = enraged_color if enraged else body_color


## Libération : les couleurs reviennent, le corps grossit un peu puis disparaît en `duration` s.
func play_freed(duration: float) -> void:
	_stars.visible = false
	var tween: Tween = create_tween()
	tween.tween_property(_material, "albedo_color", freed_color, duration / 2.0)
	tween.parallel().tween_property(_pivot, "scale", _pivot.scale * freed_pop_scale, duration / 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_pivot, "scale", Vector3.ZERO, duration / 2.0).set_ease(Tween.EASE_IN)


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left = maxf(_flash_left - delta, 0.0)
		_material.emission_energy_multiplier = flash_energy * _flash_left / _flash_time
	if _stars.visible:
		_stars.rotation.y += stars_spin_speed * delta
