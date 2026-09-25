extends MuetState
## Porte-bouclier, coup de bouclier : un petit bond vers le héros ; à l'atterrissage, le héros
## trop près prend un gros coup.

var _landed: bool = false


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	_landed = false
	var aim: Vector3 = muet.target.global_position if muet.target else muet.global_position + muet.facing()
	var distance: float = minf(tuning.shielder_bash_distance, muet.flat_distance_to(aim))
	muet.hop(muet.flat_direction_to(aim) * distance, tuning.shielder_bash_time, tuning.shielder_bash_height, _on_land)


func physics_update(delta: float) -> void:
	muet.body.set_motion(true, 0.0, 0.0, false, false)
	muet.move(Vector3.ZERO, delta)
	if _landed or not muet.is_hopping():
		machine.transition_to(&"Hop")


func _on_land() -> void:
	var tuning: TuningData = Tuning.data
	_landed = true
	var reach: float = muet.stat(&"radius") + tuning.shielder_bash_reach
	muet.strike(reach, CombatMath.FULL_CIRCLE_DEG, muet.facing(), tuning.attack_active_time, muet.damage_of(&"damage"), true)
