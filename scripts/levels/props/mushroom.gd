extends Node3D
## Champignon-trampoline : tomber dessus relance le héros très haut (le salto reste possible).

## Écrasement du chapeau au rebond (facteurs d'échelle) et durée du retour (s).
@export var squash_scale: Vector3
@export var squash_recover_time: float

@onready var _cap: Node3D = $Cap
@onready var _zone: Area3D = $BounceZone
@onready var _sound: AudioStreamPlayer3D = $BounceSound


func _ready() -> void:
	_zone.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var hero: Hero = body as Hero
	if hero == null or hero.velocity.y > 0.0:
		return
	hero.bounce(Tuning.data.mushroom_bounce_speed)
	_sound.play()
	var rest: Vector3 = _cap.scale
	_cap.scale = rest * squash_scale
	create_tween().tween_property(_cap, "scale", rest, squash_recover_time).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
