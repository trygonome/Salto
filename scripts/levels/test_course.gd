extends Node3D
## Parcours d'essai : lance la musique de la nuit avec `music_layers` couches audibles.

## Couches audibles (1 = la base seule ; une de plus par tambour rapporté).
@export var music_layers: int


func _ready() -> void:
	Rhythm.play(music_layers)


func _exit_tree() -> void:
	Rhythm.stop()
