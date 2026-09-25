extends Node3D
## Niveau d'une nuit : remet la nuit à zéro et lance la musique (la base, plus une couche par
## tambour déjà rapporté).


func _ready() -> void:
	Game.start_night()
	Rhythm.play(Game.music_layers())


func _exit_tree() -> void:
	Rhythm.stop()
