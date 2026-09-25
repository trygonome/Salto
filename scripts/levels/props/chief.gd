extends Node3D
## Chef Taroum. Il salue le héros, et danse quand un tambour revient — un peu plus fort à chaque
## tambour (il sait tout, et n'en parle jamais).

const IDLE := &"general/Idle_A"
const WAVE := &"simulation/Waving"
const CHEER := &"simulation/Cheering"

@onready var _model: Node3D = $Model
@onready var _animations: AnimationPlayer = $Model/AnimationPlayer


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	_model.scale = Vector3.ONE * tuning.chief_height / _model_height()
	for clip: StringName in [IDLE, CHEER]:
		_animations.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	_animations.play(WAVE)
	_animations.queue(IDLE)
	Game.drum_returned.connect(_on_drum_returned)


func _on_drum_returned(count: int) -> void:
	var tuning: TuningData = Tuning.data
	_animations.play(CHEER, tuning.anim_blend_time, 1.0 + tuning.chief_cheer_speed_per_drum * count)
	get_tree().create_timer(tuning.chief_cheer_time).timeout.connect(_animations.play.bind(IDLE, tuning.anim_blend_time))


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
