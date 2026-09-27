extends MuetState
## Gardien, choix de l'attaque : il alterne entre ses attaques (dans l'ordre), et passe tout de
## suite à la suivante.

## États d'attaque, dans l'ordre où il les enchaîne.
@export var attacks: Array[StringName] = []

var _next: int = 0


func enter(_previous: StringName) -> void:
	var chosen: StringName = attacks[_next % attacks.size()]
	_next += 1
	machine.transition_to.call_deferred(chosen)


func physics_update(delta: float) -> void:
	muet.move(Vector3.ZERO, delta)
