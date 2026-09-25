class_name MuetStunnedState
extends MuetState
## Étourdi : le Muet ne fait plus rien un moment (ses yeux tournent). Certaines espèces sont
## alors plus fragiles (Tuning.<espèce>_stunned_damage_multiplier : le cornu assommé).

## Durée de l'étourdissement (s), fixée par Muet.stun().
var duration: float = 0.0

var _left: float = 0.0


func enter(_previous: StringName) -> void:
	_left = duration
	muet.hitbox.deactivate()
	muet.body.set_stunned(true)
	muet.hurtbox.damage_taken_multiplier = muet.stat_or(&"stunned_damage_multiplier", 1.0)


func exit() -> void:
	muet.body.set_stunned(false)
	muet.hurtbox.damage_taken_multiplier = 1.0


func allows_contact() -> bool:
	return false


func physics_update(delta: float) -> void:
	muet.body.set_motion(false, 0.0, 0.0, false, false)
	muet.move(Vector3.ZERO, delta)
	_left -= delta
	if _left <= 0.0:
		machine.transition_to(machine.initial_state.name)
