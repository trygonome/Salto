extends MuetState
## Volant : tourne au-dessus du héros repéré (ou plane au-dessus de son poste) ; tous les
## quelques temps, il annonce un piqué.

var _beats: int = 0
var _angle: float = 0.0


func enter(_previous: StringName) -> void:
	_beats = 0


func on_beat(_index: int) -> void:
	muet.update_target()
	if muet.target == null:
		_beats = 0
		return
	_beats += 1
	if _beats >= Tuning.data.flyer_dive_every_beats:
		machine.transition_to(&"Telegraph")


func physics_update(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	var center: Vector3 = muet.target.global_position if muet.target else muet.post
	var radius: float = tuning.flyer_orbit_radius if muet.target else 0.0
	_angle += tuning.flyer_orbit_speed * delta
	var desired: Vector3 = Vector3(center.x, muet.post.y + tuning.flyer_altitude, center.z) + Vector3(cos(_angle), 0.0, sin(_angle)) * radius
	var velocity: Vector3 = (desired - muet.global_position) * tuning.flyer_follow_rate
	muet.velocity.y = velocity.y
	muet.move(Vector3(velocity.x, 0.0, velocity.z), delta)
	muet.face(muet.flat_direction_to(center))
