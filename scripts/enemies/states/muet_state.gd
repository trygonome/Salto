class_name MuetState
extends State
## État d'un Muet : accès au Muet, et réaction aux temps de la musique.

@onready var muet: Muet = owner as Muet


## Appelé à chaque temps (avec le décalage propre au Muet).
func on_beat(_index: int) -> void:
	pass
