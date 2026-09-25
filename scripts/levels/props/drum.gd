extends Node3D
## Tambour volé, dans son sanctuaire. Enfermé dans une bulle de silence tant que son gardien
## n'est pas libéré ; ensuite il attend le héros, qui l'emporte en le touchant. S'il est perdu
## en route (PV à zéro), il revient ici ; une fois rapporté au village, il y reste.

## Le gardien est libéré : le tambour est à prendre.
signal released

## Point d'apparition du gardien : sa libération ouvre la bulle.
@export var guardian: Node
## Rotation du tambour qui attend (rad/s).
@export var spin_speed: float

var _available: bool = false
var _carried: bool = false

@onready var _bubble: Node3D = $Bubble
@onready var _model: Node3D = $Model
@onready var _pickup: Area3D = $Pickup


func _ready() -> void:
	_bubble.visible = true
	_pickup.body_entered.connect(_on_body_entered)
	Game.drum_dropped.connect(_on_drum_dropped)
	Game.drum_returned.connect(func(_count: int) -> void: _carried = false)
	if guardian:
		guardian.connect(&"muet_freed", _on_guardian_freed)


func _on_guardian_freed(_muet: Muet) -> void:
	_bubble.visible = false
	_available = true
	Game.free_sanctuary()
	released.emit()


func _on_body_entered(body: Node3D) -> void:
	if not _available or not body is Hero:
		return
	_available = false
	_carried = true
	_model.visible = false
	var fx: Effects = Effects.of(self)
	if fx:
		var tuning: TuningData = Tuning.data
		fx.burst(_model.global_position + Vector3.UP * tuning.fx_drum_pick_height, tuning.fx_drum_pick_cubes, tuning.fx_drum_pick_speed)
	Game.pick_drum()


## Vrai tant que le tambour attend sur son autel qu'on vienne le prendre.
func is_available() -> bool:
	return _available


func _on_drum_dropped() -> void:
	if _carried:
		_carried = false
		_available = true
		_model.visible = true


func _process(delta: float) -> void:
	if _model.visible:
		_model.rotation.y += spin_speed * delta
