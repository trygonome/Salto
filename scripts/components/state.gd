class_name State
extends Node
## Un état d'une StateMachine. Surcharger enter, exit et physics_update.

## Machine qui possède cet état (renseignée par la StateMachine au démarrage).
var machine: StateMachine


## Appelé en entrant dans l'état ; `previous` est le nom de l'état quitté (vide au démarrage).
func enter(_previous: StringName) -> void:
	pass


## Appelé en quittant l'état.
func exit() -> void:
	pass


## Appelé à chaque image physique tant que l'état est actif.
func physics_update(_delta: float) -> void:
	pass
