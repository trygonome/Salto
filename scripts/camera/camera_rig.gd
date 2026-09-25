class_name CameraRig
extends Node3D
## Caméra plongeante du jeu. Le nœud suit le point visé en douceur, un peu en avant du héros
## dans sa direction de course ; la Camera3D enfant recule et s'incline selon les réglages,
## avec un cadrage différent en portrait et en paysage. Elle tremble quand Feedback le demande,
## et se laisse pousser dans le sens du coup.

## Corps suivi (le héros).
@export var target: CharacterBody3D

var _base_offset: Vector3 = Vector3.ZERO
var _trauma: float = 0.0
var _push_direction: Vector3 = Vector3.ZERO
var _rng := RandomNumberGenerator.new()

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	# Déplacée dans _process : la position lissée ne doit pas être interpolée une deuxième fois.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_viewport().size_changed.connect(_apply_framing)
	Feedback.shake_requested.connect(_on_shake_requested)
	_rng.randomize()
	_apply_framing()
	if target:
		if target.has_signal(&"respawned"):
			target.connect(&"respawned", snap)
		snap()


## Place la caméra tout de suite sur sa cible, sans glisser (départ, retour au village).
func snap() -> void:
	global_position = _desired_position()


func _process(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	if target:
		var weight: float = Smoothing.weight(tuning.camera_follow_rate, delta)
		global_position = global_position.lerp(_desired_position(), weight)
	_trauma = maxf(_trauma - tuning.shake_decay * delta, 0.0)
	_camera.position = _base_offset + shake_offset(_trauma, _push_direction, _random_unit(), tuning)


## Décalage de la caméra pour une secousse `trauma` (0 à 1) : tremblement dans la direction
## `jitter` (au hasard, longueur au plus 1), proportionnel au carré de la secousse, plus une poussée
## dans la direction du coup.
static func shake_offset(trauma: float, push_direction: Vector3, jitter: Vector3, tuning: TuningData) -> Vector3:
	return jitter * trauma * trauma * tuning.shake_max_offset + push_direction * trauma * tuning.camera_push


func _on_shake_requested(trauma: float, direction: Vector3) -> void:
	_trauma = minf(_trauma + trauma, 1.0)
	_push_direction = Vector3(direction.x, 0.0, direction.z).normalized()


func _random_unit() -> Vector3:
	return Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)).limit_length(1.0)


func _desired_position() -> Vector3:
	var tuning: TuningData = Tuning.data
	var feet: Vector3 = target.get_global_transform_interpolated().origin
	var running: Vector3 = Vector3(target.velocity.x, 0.0, target.velocity.z)
	return feet + Vector3.UP * tuning.camera_target_height + lookahead_for(running, tuning)


func _apply_framing() -> void:
	var tuning: TuningData = Tuning.data
	var size: Vector2 = get_viewport().get_visible_rect().size
	_camera.fov = fov_for(size, tuning)
	_base_offset = offset_for(distance_for(size, tuning), tuning.camera_tilt_deg)
	_camera.position = _base_offset
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
