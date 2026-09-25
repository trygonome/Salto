extends MuetState
## Volant, annonce : une ligne rouge au sol, de sous lui jusqu'au-delà du héros ; pendant la
## première moitié elle suit le héros, puis elle se fige. Il pique ensuite le long de la ligne.
## Un coup reçu pendant l'annonce l'en dissuade.

var _elapsed: float = 0.0
var _duration: float = 0.0
var _aim: Vector3 = Vector3.ZERO
var _mark: Telegraph


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	_elapsed = 0.0
	_duration = muet.beats_to_seconds(tuning.flyer_telegraph_beats)
	_track()
	_mark = muet.telegraph()
	_mark.show_line(_start(), _end(), tuning.flyer_line_width, _duration)


func exit() -> void:
	if is_instance_valid(_mark) and _elapsed < _duration:
		_mark.queue_free()


func interruptible() -> bool:
	return true


func physics_update(delta: float) -> void:
	_elapsed += delta
	if _elapsed < _duration / 2.0:
		_track()
		if is_instance_valid(_mark):
			_mark.move_line(_start(), _end(), Tuning.data.flyer_line_width)
	muet.velocity.y = 0.0
	muet.body.set_motion(false, 0.0, 0.0, false, false)
	muet.move(Vector3.ZERO, delta)
	if _elapsed >= _duration:
		var direction: Vector3 = muet.flat_direction_to(_aim)
		(machine.get_node(^"Dive") as FlyerDiveState).plan(muet.global_position, direction, muet.flat_distance_to(_aim) + Tuning.data.flyer_dive_overshoot)
		machine.transition_to(&"Dive")


func _track() -> void:
	if muet.target:
		_aim = muet.target.global_position
	muet.face(muet.flat_direction_to(_aim))


func _start() -> Vector3:
	return Vector3(muet.global_position.x, muet.post.y, muet.global_position.z)


func _end() -> Vector3:
	var direction: Vector3 = muet.flat_direction_to(_aim)
	return _start() + direction * (muet.flat_distance_to(_aim) + Tuning.data.flyer_dive_overshoot)
