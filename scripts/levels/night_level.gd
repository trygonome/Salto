extends Node3D
## Niveau d'une nuit : remet la nuit à zéro et lance la musique (la base, plus une couche par
## tambour déjà rapporté).

## Numéro de la nuit (1 à 5).
@export var night: int


func _ready() -> void:
	Game.start_night(night)
	Rhythm.play(Game.music_layers())


func _exit_tree() -> void:
	Rhythm.stop()
