extends MuetState
## Grand Muet, annonce : un cercle rouge autour de lui qui se remplit pendant le temps d'annonce.

var _left: float = 0.0


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	_left = muet.beats_to_seconds(tuning.boss_telegraph_beats)
	muet.telegraph().show_circle(muet.global_position, tuning.boss_slam_radius, _left)


func physics_update(delta: float) -> void:
	muet.move(Vector3.ZERO, delta)
	_left -= delta
	if _left <= 0.0:
		machine.transition_to(&"Slam")
