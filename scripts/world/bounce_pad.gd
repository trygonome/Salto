class_name BouncePad
extends Area3D
## Dessus d'un champignon-trampoline : le héros qui y retombe repart très haut (le salto reste
## possible), avec un « boïng ».

## Rayon du dessus (m).
var radius: float = 0.0
var sound: AudioStream

var _player: AudioStreamPlayer3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = Tuning.data.bounce_pad_thickness
	var shape := CollisionShape3D.new()
	shape.shape = cylinder
	add_child(shape)
	_player = AudioStreamPlayer3D.new()
	_player.stream = sound
	add_child(_player)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var hero: Hero = body as Hero
	if hero == null or hero.velocity.y > 0.0:
		return
	hero.bounce(Tuning.data.mushroom_bounce_speed)
	_player.play()
