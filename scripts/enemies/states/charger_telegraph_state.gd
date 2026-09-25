extends MuetState
## Cornu, annonce : une ligne rouge de toute la longueur de la charge ; pendant le premier temps
## elle suit le héros, puis elle se fige. Le cornu charge à la fin de l'annonce.

var _elapsed: float = 0.0
var _duration: float = 0.0
var _track_time: float = 0.0
var _direction: Vector3 = Vector3.FORWARD
var _mark: Telegraph


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	_elapsed = 0.0
	_duration = muet.beats_to_seconds(tuning.charger_telegraph_beats)
	_track_time = muet.beats_to_seconds(tuning.charger_track_beats)
	_aim()
	_mark = muet.telegraph()
	_mark.show_line(muet.global_position, _end(), tuning.charger_line_width, _duration)


func physics_update(delta: float) -> void:
	_elapsed += delta
	if _elapsed <= _track_time:
		_aim()
		if is_instance_valid(_mark):
			_mark.move_line(muet.global_position, _end(), Tuning.data.charger_line_width)
	muet.move(Vector3.ZERO, delta)
	if _elapsed >= _duration:
		(machine.get_node(^"Charge") as ChargerChargeState).direction = _direction
		machine.transition_to(&"Charge")


func _aim() -> void:
	if muet.target:
		_direction = muet.flat_direction_to(muet.target.global_position)
	muet.face(_direction)


func _end() -> Vector3:
	return muet.global_position + _direction * Tuning.data.charger_distance
