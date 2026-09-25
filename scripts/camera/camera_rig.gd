class_name CameraRig
extends Node3D
## Caméra plongeante du jeu. Le nœud suit le point visé en douceur, un peu en avant du héros
## dans sa direction de course ; la Camera3D enfant recule et s'incline selon les réglages,
## avec un cadrage différent en portrait et en paysage.

## Corps suivi (le héros).
@export var target: CharacterBody3D

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	# Déplacée dans _process : la position lissée ne doit pas être interpolée une deuxième fois.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_viewport().size_changed.connect(_apply_framing)
	_apply_framing()
	if target:
		global_position = _desired_position()


func _process(delta: float) -> void:
	if target:
		var weight: float = Smoothing.weight(Tuning.data.camera_follow_rate, delta)
		global_position = global_position.lerp(_desired_position(), weight)


func _desired_position() -> Vector3:
	var tuning: TuningData = Tuning.data
	var feet: Vector3 = target.get_global_transform_interpolated().origin
	var running: Vector3 = Vector3(target.velocity.x, 0.0, target.velocity.z)
	return feet + Vector3.UP * tuning.camera_target_height + lookahead_for(running, tuning)


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


## Décalage du point visé dans la direction de course : camera_lookahead à pleine vitesse,
## proportionnel en dessous, jamais plus.
static func lookahead_for(horizontal_velocity: Vector3, tuning: TuningData) -> Vector3:
	var offset: Vector3 = horizontal_velocity / tuning.run_speed * tuning.camera_lookahead
	return offset.limit_length(tuning.camera_lookahead)
