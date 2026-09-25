extends MuetState
## Cornu : marche vers le héros repéré et blesse (moins fort) au simple contact ; après quelques
## temps de repos, il annonce sa charge.

var _beats: int = 0


func enter(_previous: StringName) -> void:
	_beats = 0


func on_beat(_index: int) -> void:
	var tuning: TuningData = Tuning.data
	muet.update_target()
	var forward: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, muet.body.rotation.y)
	muet.strike(tuning.charger_radius, CombatMath.FULL_CIRCLE_DEG, forward, muet.beats_to_seconds(1), tuning.charger_damage * tuning.charger_contact_fraction, false)
	if muet.target == null:
		_beats = 0
		return
	_beats += 1
	if _beats >= tuning.charger_rest_beats:
		machine.transition_to(&"Telegraph")


func physics_update(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	var destination: Vector3 = muet.target.global_position if muet.target else muet.post
	var direction: Vector3 = muet.flat_direction_to(destination)
	var far_enough: bool = muet.flat_distance_to(destination) > tuning.charger_radius * 2.0
	muet.face(direction)
	muet.move(direction * tuning.muet_walk_speed if far_enough else Vector3.ZERO, delta)
