extends Node3D
## Support des tambours, au cœur du village : le héros y pose le tambour qu'il porte.
## Chaque tambour posé y reste visible.

## Tambours posés, dans l'ordre (masqués au début de la nuit).
@export var slots: Array[Node3D]
## Effet de fête quand un tambour est posé, sa durée (s) et sa taille (m).
@export var burst_scene: PackedScene
@export var burst_duration: float
@export var burst_size: float

@onready var _zone: Area3D = $Zone
@onready var _sound: AudioStreamPlayer3D = $ReturnSound


func _ready() -> void:
	for slot: Node3D in slots:
		slot.visible = false
	_zone.body_entered.connect(_on_body_entered)
	Game.drum_returned.connect(_on_drum_returned)


func _on_body_entered(body: Node3D) -> void:
	if body is Hero and Game.progress.carrying_drum:
		Game.return_drum()


func _on_drum_returned(count: int) -> void:
	var slot: Node3D = slots[mini(count, slots.size()) - 1]
	slot.visible = true
	_sound.play()
	if burst_scene:
		var burst: FadingBurst = burst_scene.instantiate() as FadingBurst
		add_child(burst)
		burst.global_position = slot.global_position
		burst.play(burst_duration, burst_size)
