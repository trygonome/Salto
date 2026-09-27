extends MuetState
## Brute, annonce : elle lève les poings (elle se gonfle) et une ligne s'annonce vers le héros
## pendant quelques temps ; elle suit le héros jusqu'au dernier temps. Puis elle bondit (Lunge).
## Un coup ne l'arrête pas (trop lourde) ; le coup chargé brise son équilibre plus vite.

var _elapsed: float = 0.0
var _duration: float = 0.0
var _mark: Telegraph
var _direction: Vector3 = Vector3.FORWARD


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	_elapsed = 0.0
	_duration = muet.beats_to_seconds(tuning.brute_telegraph_beats)
	_direction = muet.flat_direction_to(muet.target.global_position) if muet.target else muet.facing()
	_mark = muet.telegraph()
	_mark.show_line(muet.global_position, muet.global_position + _direction * tuning.brute_lunge_distance, tuning.brute_line_width, _duration)


func physics_update(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_elapsed += delta
	if muet.target and _elapsed < _duration - muet.beats_to_seconds(1):
		_direction = muet.flat_direction_to(muet.target.global_position)
		if is_instance_valid(_mark):
			_mark.move_line(muet.global_position, muet.global_position + _direction * tuning.brute_lunge_distance, tuning.brute_line_width)
	muet.face(_direction)
	muet.body.set_motion(false, 0.0, tuning.brute_inflate * minf(_elapsed / _duration, 1.0), false, false)
	muet.move(Vector3.ZERO, delta)
	if _elapsed >= _duration:
		(machine.get_node(^"Lunge") as BruteLungeState).direction = _direction
		machine.transition_to(&"Lunge")
