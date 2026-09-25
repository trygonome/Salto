class_name HeroVisual
extends Node3D
## Apparence du héros (personnage KayKit) : orientation, tour complet du salto et de la roulade,
## rotation des coups tournoyants, inclinaison du plongeon, traînée du pied qui frappe.
## Les clips sont joués par HeroAnimator.

## Os de la jambe qui frappe (squelette KayKit), entre lesquels la traînée est tendue.
const KICK_ROOT_BONE := "upperleg.r"
const KICK_TIP_BONE := "foot.r"

var _center_height: float
var _roll_height: float
var _spin_time: float = 0.0
var _spin_duration: float = 0.0
var _yaw_offset: float = 0.0
var _pitch: float = 0.0

@onready var animator: HeroAnimator = $Pivot/Model/AnimationPlayer
@onready var trail: RibbonTrail = $Trail
@onready var _pivot: Node3D = $Pivot
@onready var _model: Node3D = $Pivot/Model


## Met le personnage à la taille du héros et accroche la traînée au pied qui frappe.
## Le pivot des rotations est au centre du corps (au ras du sol pour la roulade).
func setup(height: float, roll_pivot_height: float) -> void:
	_model.scale = Vector3.ONE * height / _model_height()
	_center_height = height / 2.0
	_roll_height = roll_pivot_height
	_set_pivot_height(_center_height)
	var skeleton: Skeleton3D = _model.find_child("Skeleton3D") as Skeleton3D
	trail.root_node = _attach(skeleton, KICK_ROOT_BONE)
	trail.tip_node = _attach(skeleton, KICK_TIP_BONE)


## Salto : un tour complet vers l'avant autour du centre du corps.
func play_salto(duration: float) -> void:
	_start_spin(duration, _center_height)


## Roulade : un tour complet vers l'avant, pivot près du sol.
func play_roll(duration: float) -> void:
	_start_spin(duration, _roll_height)


## Interrompt le tour en cours (roulade ou salto coupés par une autre action).
func stop_spin() -> void:
	_spin_duration = 0.0
	_set_pivot_height(_center_height)


## Rotation du corps autour de la verticale, en plus du regard (coups tournoyants).
func set_yaw_offset_deg(degrees: float) -> void:
	_yaw_offset = deg_to_rad(degrees)


## Inclinaison du corps vers l'avant (plongeon).
func set_pitch_deg(degrees: float) -> void:
	_pitch = deg_to_rad(degrees)


## Oriente le corps et fait avancer les rotations. Appelé à chaque image physique.
func update_pose(yaw: float, delta: float) -> void:
	rotation.y = yaw + _yaw_offset
	var spin: float = 0.0
	if _spin_duration > 0.0:
		_spin_time += delta
		var fraction: float = minf(_spin_time / _spin_duration, 1.0)
		spin = TAU * fraction
		if fraction >= 1.0:
			stop_spin()
			spin = 0.0
	_pivot.rotation.x = -spin - _pitch
	animator.update(delta)


func _start_spin(duration: float, pivot_height: float) -> void:
	_spin_time = 0.0
	_spin_duration = duration
	_set_pivot_height(pivot_height)


func _attach(skeleton: Skeleton3D, bone: String) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone
	skeleton.add_child(attachment)
	return attachment


func _set_pivot_height(height: float) -> void:
	_pivot.position.y = height
	_model.position.y = -height


## Hauteur du personnage à l'échelle 1, d'après ses maillages.
func _model_height() -> float:
	var to_model: Transform3D = _model.global_transform.affine_inverse()
	var bounds := AABB()
	var first: bool = true
	for node: Node in _model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		var box: AABB = to_model * mesh.global_transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds.size.y
