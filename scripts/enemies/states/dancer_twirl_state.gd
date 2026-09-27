extends MuetState
## Danseur, vrille : un petit cercle s'annonce autour de lui pendant un temps, puis il tourne sur
## lui-même en frappant tout autour. Une esquive parfaite dans la vrille ouvre la riposte (sa
## réponse).

var _left: float = 0.0
var _struck: bool = false


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	_left = muet.beats_to_seconds(tuning.dancer_twirl_beats)
	_struck = false
	muet.telegraph().show_circle(muet.global_position, tuning.dancer_twirl_radius, _left)


func exit() -> void:
	muet.hitbox.deactivate()


func physics_update(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	muet.move(Vector3.ZERO, delta)
	_left -= delta
	if not _struck:
		muet.body.set_motion(false, 0.0, 0.0, true, false)
		if _left <= 0.0:
			_struck = true
			_left = muet.beats_to_seconds(1) / 2.0
			muet.strike(tuning.dancer_twirl_radius, CombatMath.FULL_CIRCLE_DEG, muet.facing(), _left, muet.damage_of(&"damage"), false)
			muet.body.squash(tuning.muet_squash_hop)
		return
	muet.body.target_yaw = muet.body.rotation.y + PI
	muet.body.set_motion(true, 0.0, 0.0, false, false)
	if _left <= 0.0:
		machine.transition_to(&"Hop")
