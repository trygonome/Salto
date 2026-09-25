extends MuetState
## Porte-bouclier, préparation : il se tasse derrière son bouclier un temps, puis donne son coup
## de bouclier. Un coup reçu pendant la préparation l'en dissuade.

var _left: float = 0.0


func enter(_previous: StringName) -> void:
	_left = muet.beats_to_seconds(Tuning.data.shielder_prepare_beats)
	muet.body.squash(-Tuning.data.muet_squash_bash)


func interruptible() -> bool:
	return true


func physics_update(delta: float) -> void:
	if muet.target:
		muet.face(muet.flat_direction_to(muet.target.global_position))
	muet.body.set_motion(false, 0.0, 0.0, true, false)
	muet.move(Vector3.ZERO, delta)
	_left -= delta
	if _left <= 0.0:
		machine.transition_to(&"Bash")
