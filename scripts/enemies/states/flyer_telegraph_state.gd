extends MuetState
## Volant, annonce : une ligne rouge au sol, de sous lui jusqu'au-delà du héros, qui se remplit
## pendant le temps d'annonce ; puis il pique le long de cette ligne.

var _left: float = 0.0


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	var ground: float = muet.post.y
	var start := Vector3(muet.global_position.x, ground, muet.global_position.z)
	var aim: Vector3 = muet.target.global_position if muet.target else muet.post
	var target := Vector3(aim.x, ground, aim.z)
	var end := Vector3(2.0 * target.x - start.x, ground, 2.0 * target.z - start.z)
	_left = muet.beats_to_seconds(tuning.flyer_telegraph_beats)
	muet.telegraph().show_line(start, end, tuning.flyer_line_width, _left)
	(machine.get_node(^"Dive") as FlyerDiveState).plan(muet.global_position, target)


func physics_update(delta: float) -> void:
	muet.velocity.y = 0.0
	muet.move(Vector3.ZERO, delta)
	_left -= delta
	if _left <= 0.0:
		machine.transition_to(&"Dive")
