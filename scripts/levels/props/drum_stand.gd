extends Node3D
## Support des tambours, au cœur du village : le héros y pose les tambours qu'il porte.
## Chaque tambour posé y reste visible.

## Tambours posés, dans l'ordre (masqués au début de la nuit) ; chacun arrive dans une gerbe de
## cubes et un anneau doré.
@export var slots: Array[Node3D]

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
	_sound.play()
	for i: int in mini(count, slots.size()):
		var slot: Node3D = slots[i]
		if slot.visible:
			continue
		slot.visible = true
		var fx: Effects = Effects.of(self)
		if fx:
			var tuning: TuningData = Tuning.data
			fx.burst(slot.global_position, tuning.fx_drum_return_cubes, tuning.fx_drum_return_speed)
			fx.ring(slot.global_position, tuning.fx_drum_return_ring, fx.gold, tuning.fx_drum_return_ring_time)
