extends Node3D
## Butin : un objet jaillit du sol, brille de la couleur de sa rareté et flotte ; le héros le
## ramasse en le touchant.

## Couleur de la lueur par rareté (commun, rare, épique, légendaire).
@export var rarity_colors: Array[Color]
## Hauteur et durée du jaillissement (m, s), puis flottement (m, s par cycle).
@export var jump_height: float
@export var jump_time: float
@export var bob_height: float
@export var bob_period: float

## Objet contenu (tiré au sort s'il n'est pas donné).
var item: ItemData

var _time: float = 0.0
var _rest_height: float = 0.0

@onready var _orb: MeshInstance3D = $Orb
@onready var _zone: Area3D = $Zone
@onready var _sound: AudioStreamPlayer3D = $PickupSound


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	if item == null:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		item = ItemMath.roll_item(rng, tuning.hero_start_level, tuning.loot_guaranteed_weights, tuning)
	var material: StandardMaterial3D = (_orb.mesh.surface_get_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
	material.emission = rarity_colors[item.rarity]
	material.albedo_color = rarity_colors[item.rarity]
	_orb.material_override = material
	_rest_height = jump_height
	_orb.position.y = 0.0
	create_tween().tween_property(_orb, "position:y", jump_height, jump_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_zone.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	if _time > jump_time and is_instance_valid(_orb):
		_orb.position.y = _rest_height + bob_height * sin(TAU * (_time - jump_time) / bob_period)


func _on_body_entered(body: Node3D) -> void:
	if not body is Hero or not is_instance_valid(_orb):
		return
	Game.add_item(item)
	_sound.play()
	_orb.queue_free()
	_zone.set_deferred(&"monitoring", false)
	get_tree().create_timer(_sound.stream.get_length()).timeout.connect(queue_free)
