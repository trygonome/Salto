class_name TrainingDummy
extends StaticBody3D
## Mannequin d'entraînement : il encaisse les coups (recul, animation de coup reçu, compteur
## de dégâts pour la mise au point) et se relève dès que ses points de vie sont épuisés.

## Animations de coup reçu, jouées à tour de rôle.
const HIT_CLIPS: Array[StringName] = [&"general/Hit_A", &"general/Hit_B"]
const IDLE := &"general/Idle_A"

## Dégâts reçus depuis l'apparition (mise au point et tests).
var damage_taken: float = 0.0
## Coups reçus depuis l'apparition.
var hits_taken: int = 0

var _next_clip: int = 0

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var _visual: Node3D = $Visual
@onready var _model: Node3D = $Visual/Model
@onready var _animations: AnimationPlayer = $Visual/Model/AnimationPlayer


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	for shape_node: CollisionShape3D in [$CollisionShape3D as CollisionShape3D, $Hurtbox/CollisionShape3D as CollisionShape3D]:
		var capsule: CapsuleShape3D = shape_node.shape as CapsuleShape3D
		capsule.radius = tuning.dummy_radius
		capsule.height = tuning.dummy_height
		shape_node.position = Vector3.UP * tuning.dummy_height / 2.0
	hurtbox.radius = tuning.dummy_radius
	health.setup(tuning.dummy_health)
	health.depleted.connect(health.restore)
	hurtbox.hurt.connect(_on_hurt)
	_model.scale = Vector3.ONE * tuning.dummy_height / _model_height()
	_animations.get_animation(IDLE).loop_mode = Animation.LOOP_LINEAR
	_animations.play(IDLE)


func _on_hurt(hit: HitData) -> void:
	var tuning: TuningData = Tuning.data
	damage_taken += hit.damage
	hits_taken += 1
	_animations.play(HIT_CLIPS[_next_clip], tuning.anim_blend_time)
	_animations.queue(IDLE)
	_next_clip = (_next_clip + 1) % HIT_CLIPS.size()
	# Recul : le corps est chassé dans le sens du coup puis revient à sa place.
	_visual.position = hit.direction * tuning.dummy_recoil_distance
	var tween: Tween = create_tween()
	tween.tween_property(_visual, "position", Vector3.ZERO, tuning.dummy_recoil_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


## Hauteur du modèle à l'échelle 1, d'après ses maillages.
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
