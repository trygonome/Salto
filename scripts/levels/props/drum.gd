extends Node3D
## Tambour volé, dans son sanctuaire. Enfermé dans une bulle de silence tant que son gardien
## n'est pas libéré ; ensuite il attend le héros, qui l'emporte en le touchant. S'il est perdu
## en route (chute), il revient ici.

## Point d'apparition du gardien : sa libération ouvre la bulle.
@export var guardian: Node
## Rotation du tambour qui attend (rad/s).
@export var spin_speed: float

var _available: bool = false

@onready var _bubble: Node3D = $Bubble
@onready var _model: Node3D = $Model
@onready var _pickup: Area3D = $Pickup


func _ready() -> void:
	_bubble.visible = true
	_pickup.body_entered.connect(_on_body_entered)
	Game.drum_dropped.connect(_on_drum_dropped)
	if guardian:
		guardian.connect(&"muet_freed", _on_guardian_freed)


func _on_guardian_freed(_muet: Muet) -> void:
	_bubble.visible = false
	_available = true


func _on_body_entered(body: Node3D) -> void:
	if not _available or not body is Hero:
		return
	_available = false
	_model.visible = false
	Game.pick_drum()


func _on_drum_dropped() -> void:
	if not _bubble.visible:
		_available = true
		_model.visible = true


func _process(delta: float) -> void:
	if _model.visible:
		_model.rotation.y += spin_speed * delta
