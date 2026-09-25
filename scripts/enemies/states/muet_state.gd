class_name MuetState
extends State
## État d'un Muet : accès au Muet, et réaction aux temps de la musique.

@onready var muet: Muet = owner as Muet


## Appelé à chaque temps (avec le décalage propre au Muet).
func on_beat(_index: int) -> void:
	pass


## Vrai si le Muet blesse au simple contact dans cet état.
func allows_contact() -> bool:
	return true


## Vrai si un coup reçu fait renoncer le Muet à ce qu'il prépare (attaque annoncée).
func interruptible() -> bool:
	return false
