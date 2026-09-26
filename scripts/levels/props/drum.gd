extends Node3D
## Tambour volé, dans son sanctuaire. Enfermé dans une bulle de silence tant que son gardien
## n'est pas libéré ; ensuite il attend le héros, qui l'emporte en le touchant. S'il est perdu
## en route (PV à zéro), il revient ici ; une fois rapporté au village, il y reste.

## Le gardien est libéré : le tambour est à prendre.
signal released

## Point d'apparition du gardien : sa libération ouvre la bulle.
@export var guardian: Node
## Sanctuaire du tambour (-1 : le premier à prendre).
@export var sanctuary: int = -1
## Rotation du tambour qui attend (rad/s).
@export var spin_speed: float

var _available: bool = false
var _carried: bool = false
var _time: float = 0.0
var _rest_height: float = 0.0

@onready var _bubble: Node3D = $Bubble
@onready var _model: Node3D = $Model
@onready var _pickup: Area3D = $Pickup


func _ready() -> void:
	_bubble.visible = true
	var model: VoxelDrum = _model as VoxelDrum
	if model and sanctuary >= 0:
		model.hue_index = sanctuary
	_rest_height = _model.position.y
	if sanctuary >= 0 and sanctuary < Game.progress.returned.size() and Game.progress.returned[sanctuary]:
		# Déjà rapporté au village lors d'une sortie précédente.
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	_pickup.body_entered.connect(_on_body_entered)
	Game.drum_dropped.connect(_on_drum_dropped)
	Game.drum_returned.connect(func(_count: int) -> void: _carried = false)
	if guardian:
		guardian.connect(&"muet_freed", _on_guardian_freed)


func _on_guardian_freed(_muet: Muet) -> void:
	release()


## Le gardien est libéré : la bulle éclate, le tambour est à prendre.
func release() -> void:
	_bubble.visible = false
	_available = true
	Game.free_sanctuary(sanctuary)
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
	Game.pick_drum(sanctuary)
	Feedback.vibrate(Tuning.data.vibration_drum)


## Vrai tant que le tambour attend sur son autel qu'on vienne le prendre.
func is_available() -> bool:
	return _available


func _on_drum_dropped() -> void:
	if _carried:
		_carried = false
		_available = true
		_model.visible = true


func _process(delta: float) -> void:
	_time += delta
	if _model.visible:
		_model.rotation.y += spin_speed * delta
	# Libéré, il flotte au-dessus de l'autel en attendant le héros.
	var tuning: TuningData = Tuning.data
	_model.position.y = _rest_height + (tuning.drum_float_height + sin(_time * tuning.drum_bob_speed) * tuning.drum_bob_height if _available else 0.0)
