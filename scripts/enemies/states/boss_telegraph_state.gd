extends MuetState
## Grand Muet, annonce : un cercle rouge autour de lui qui se remplit pendant le temps d'annonce,
## et il se gonfle peu à peu.

var _elapsed: float = 0.0
var _duration: float = 0.0


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	_elapsed = 0.0
	_duration = muet.beats_to_seconds(tuning.boss_telegraph_beats)
	muet.telegraph().show_circle(muet.global_position, tuning.boss_slam_radius, _duration)


func physics_update(delta: float) -> void:
	_elapsed += delta
	var progress: float = minf(_elapsed / _duration, 1.0)
	muet.body.set_motion(false, 0.0, Tuning.data.boss_slam_inflate * progress, false, false)
	muet.move(Vector3.ZERO, delta)
	if _elapsed >= _duration:
		machine.transition_to(&"Slam")
