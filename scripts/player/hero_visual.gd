class_name HeroVisual
extends Node3D
## Apparence provisoire du héros (capsule et visière) : orientation, salto et roulade.
## Remplacée par le personnage animé au jalon 2.

var _stand_height: float
var _ball_height: float
var _ball_scale: float
var _spin_time: float = 0.0
var _spin_duration: float = 0.0
var _rolling: bool = false

@onready var _pivot: Node3D = $Pivot
@onready var _body: MeshInstance3D = $Pivot/Body


## Adapte la capsule à la taille du héros. Le pivot des rotations est au centre du corps.
func setup(height: float, radius: float) -> void:
	var capsule: CapsuleMesh = _body.mesh as CapsuleMesh
	capsule.height = height
	capsule.radius = radius
	_stand_height = height / 2.0
	# En roulade, le corps se ramasse en boule du diamètre de la capsule.
	_ball_height = radius
	_ball_scale = 2.0 * radius / height
	_reset_pivot()


## Salto : un tour complet vers l'avant.
func play_salto(duration: float) -> void:
	_end_roll()
	_start_spin(duration)


## Roulade : le corps se met en boule et fait un tour vers l'avant.
func play_roll(duration: float) -> void:
	_rolling = true
	_pivot.position.y = _ball_height
	_pivot.scale = Vector3(1.0, _ball_scale, 1.0)
	_start_spin(duration)


## Interrompt la roulade (saut depuis la roulade, fin anticipée).
func stop_roll() -> void:
	if _rolling:
		_end_roll()
		_spin_duration = 0.0
		_pivot.rotation.x = 0.0


## Oriente le corps et fait avancer la rotation en cours. Appelé à chaque image physique.
func update_pose(yaw: float, delta: float) -> void:
	rotation.y = yaw
	if _spin_duration <= 0.0:
		return
	_spin_time += delta
	var fraction: float = minf(_spin_time / _spin_duration, 1.0)
	_pivot.rotation.x = -TAU * fraction
	if fraction >= 1.0:
		_spin_duration = 0.0
		_pivot.rotation.x = 0.0
		_end_roll()


func _start_spin(duration: float) -> void:
	_spin_time = 0.0
	_spin_duration = duration


func _end_roll() -> void:
	_rolling = false
	_reset_pivot()


func _reset_pivot() -> void:
	_pivot.position.y = _stand_height
	_pivot.scale = Vector3.ONE
