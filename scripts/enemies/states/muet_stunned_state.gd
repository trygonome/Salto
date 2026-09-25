class_name MuetStunnedState
extends MuetState
## Étourdi : le Muet ne fait plus rien un moment (étoiles au-dessus de la tête).

## Durée de l'étourdissement (s), fixée par Muet.stun().
var duration: float = 0.0
## Multiplicateur des dégâts reçus pendant l'étourdissement (le cornu assommé est fragile).
@export var damage_taken_multiplier: float

var _left: float = 0.0


func enter(_previous: StringName) -> void:
	_left = duration
	muet.hitbox.deactivate()
	muet.body.set_stunned(true)
	if damage_taken_multiplier > 0.0:
		muet.hurtbox.damage_taken_multiplier = damage_taken_multiplier


func exit() -> void:
	muet.body.set_stunned(false)
	muet.hurtbox.damage_taken_multiplier = 1.0


func physics_update(delta: float) -> void:
	muet.move(Vector3.ZERO, delta)
	_left -= delta
	if _left <= 0.0:
		machine.transition_to(machine.initial_state.name)
