extends Node3D
## Support des tambours, au cœur du village : le héros y pose les tambours qu'il porte.
## Chaque tambour rapporté y reste visible à sa place (une par sanctuaire), d'une sortie à l'autre.

## Tambours posés, dans l'ordre (masqués au début de la nuit) ; chacun arrive dans une gerbe de
## cubes et un anneau doré.
@export var slots: Array[Node3D]

@onready var _zone: Area3D = $Zone
@onready var _sound: AudioStreamPlayer3D = $ReturnSound


func _ready() -> void:
	_show_returned()
	_zone.body_entered.connect(_on_body_entered)
	Game.drum_returned.connect(_on_drum_returned)
	Game.night_started.connect(func(_night: int) -> void: _show_returned())


## Montre les tambours déjà rapportés cette nuit.
func _show_returned() -> void:
	for i: int in slots.size():
		slots[i].visible = i < Game.progress.returned.size() and Game.progress.returned[i]


func _on_body_entered(body: Node3D) -> void:
	if body is Hero and Game.progress.carrying_drum:
		Game.return_drum()


func _on_drum_returned(_count: int) -> void:
	_sound.play()
	for i: int in mini(Game.progress.returned.size(), slots.size()):
		var slot: Node3D = slots[i]
		if slot.visible or not Game.progress.returned[i]:
			continue
		slot.visible = true
		var fx: Effects = Effects.of(self)
		if fx:
			var tuning: TuningData = Tuning.data
			fx.burst(slot.global_position, tuning.fx_drum_return_cubes, tuning.fx_drum_return_speed)
			fx.ring(slot.global_position, tuning.fx_drum_return_ring, fx.gold, tuning.fx_drum_return_ring_time)
