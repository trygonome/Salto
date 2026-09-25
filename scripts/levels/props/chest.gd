extends Node3D
## Coffre : le toucher l'ouvre. Il donne une page du carnet, et un objet jaillit.
## Un coffre caché peut n'apparaître qu'une fois révélé (cercle des gongs). Si sa page est
## déjà dans le carnet, il est ouvert et vide.

## Page du carnet qu'il contient (numéro à partir de 1).
@export var page: int
## Butin qui jaillit à l'ouverture.
@export var loot_scene: PackedScene
## Caché au départ (révélé par reveal()).
@export var hidden: bool
## Ouverture du couvercle (degrés) et sa durée (s).
@export var lid_open_deg: float
@export var open_time: float
## Profondeur d'où il surgit quand il est révélé (m) et durée (s).
@export var rise_depth: float
@export var rise_time: float

var _opened: bool = false

@onready var _lid: Node3D = $Lid
@onready var _zone: Area3D = $Zone
@onready var _body: CollisionShape3D = $Body/CollisionShape3D
@onready var _sound: AudioStreamPlayer3D = $OpenSound


func _ready() -> void:
	_zone.body_entered.connect(_on_body_entered)
	if Game.profile.has_page(page):
		# Déjà trouvé lors d'une nuit précédente : il attend, ouvert et vide.
		_opened = true
		_lid.rotation.x = deg_to_rad(-lid_open_deg)
	if hidden:
		visible = false
		_body.set_deferred(&"disabled", true)
		_zone.set_deferred(&"monitoring", false)


## Fait surgir le coffre caché.
func reveal() -> void:
	visible = true
	_body.set_deferred(&"disabled", false)
	_zone.set_deferred(&"monitoring", true)
	var rest: Vector3 = position
	position = rest + Vector3.DOWN * rise_depth
	create_tween().tween_property(self, "position", rest, rise_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_body_entered(body: Node3D) -> void:
	if _opened or not body is Hero:
		return
	_opened = true
	_sound.play()
	create_tween().tween_property(_lid, "rotation:x", deg_to_rad(-lid_open_deg), open_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Game.add_page(page)
	if loot_scene:
		var loot: Node3D = loot_scene.instantiate() as Node3D
		get_parent().add_child(loot)
		loot.global_position = global_position
