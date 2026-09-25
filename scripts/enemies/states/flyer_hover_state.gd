extends MuetState
## Volant, en vol : en chasse, il se tient à distance du héros, un peu sur le côté ; au repos, il
## tourne au-dessus de son poste ; il ondule autour de son altitude. En chasse, chaque temps
## rapproche du piqué, qu'il annonce quand le héros est à portée.

var _time: float = 0.0


func enter(_previous: StringName) -> void:
	_time = muet.rng.randf() * TAU


func on_beat(_index: int) -> void:
	muet.update_target()
	if muet.target == null:
		return
	muet.act_cooldown -= 1
	if muet.act_cooldown <= 0 and muet.act_in_range():
		muet.act_cooldown = muet.act_rest_beats()
		machine.transition_to(&"Telegraph")


func physics_update(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_time += delta
	var goal: Vector3
	if muet.target:
		var hero: Vector3 = muet.target.global_position
		var side: float = tuning.flyer_hover_angle if muet.parity == 1 else -tuning.flyer_hover_angle
		var angle: float = atan2(muet.global_position.z - hero.z, muet.global_position.x - hero.x) + side
		goal = hero + Vector3(cos(angle), 0.0, sin(angle)) * tuning.flyer_hover_distance
		muet.face(muet.flat_direction_to(hero))
	else:
		var angle: float = _time * tuning.flyer_idle_speed + muet.parity * PI
		goal = muet.post + Vector3(cos(angle), 0.0, sin(angle)) * tuning.flyer_idle_radius
	var follow: float = Smoothing.weight(tuning.flyer_follow_rate, delta)
	var flat := Vector3(goal.x - muet.global_position.x, 0.0, goal.z - muet.global_position.z) * follow / delta
	var altitude: float = muet.post.y + tuning.flyer_altitude + sin(_time * tuning.flyer_bob_speed) * tuning.flyer_bob_height
	muet.velocity.y = (altitude - muet.global_position.y) * Smoothing.weight(tuning.flyer_altitude_rate, delta) / delta
	muet.body.set_motion(false, 0.0, 0.0, false, false)
	muet.move(flat, delta)
