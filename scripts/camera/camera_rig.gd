class_name CameraRig
extends Node3D
## Caméra plongeante du jeu. Le nœud se place sur le point visé ; la Camera3D enfant
## recule et s'incline selon les réglages, avec un cadrage différent en portrait et en paysage.
## Le suivi lissé et l'anticipation arrivent au jalon 1.

## Nœud suivi (le héros).
@export var target: Node3D

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_framing)
	_apply_framing()


func _process(_delta: float) -> void:
	if target:
		global_position = target.global_position + Vector3.UP * Tuning.data.camera_target_height


func _apply_framing() -> void:
	var tuning: TuningData = Tuning.data
	var size: Vector2 = get_viewport().get_visible_rect().size
	_camera.fov = fov_for(size, tuning)
	_camera.position = offset_for(distance_for(size, tuning), tuning.camera_tilt_deg)
	_camera.rotation = Vector3(-deg_to_rad(tuning.camera_tilt_deg), 0.0, 0.0)


## Vrai si l'écran est plus haut que large.
static func is_portrait(size: Vector2) -> bool:
	return size.y > size.x


## Distance entre la caméra et le point visé, selon l'orientation de l'écran (m).
static func distance_for(size: Vector2, tuning: TuningData) -> float:
	return tuning.camera_distance_portrait if is_portrait(size) else tuning.camera_distance_landscape


## Champ de vision vertical selon l'orientation de l'écran (degrés).
static func fov_for(size: Vector2, tuning: TuningData) -> float:
	return tuning.camera_fov_portrait_deg if is_portrait(size) else tuning.camera_fov_landscape_deg


## Position de la caméra par rapport au point visé : en arrière (+Z) et au-dessus.
static func offset_for(distance: float, tilt_deg: float) -> Vector3:
	var tilt: float = deg_to_rad(tilt_deg)
	return Vector3(0.0, sin(tilt), cos(tilt)) * distance
