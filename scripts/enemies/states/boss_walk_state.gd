extends MuetState
## Grand Muet : s'approche lentement du héros repéré ; tous les quelques temps, il annonce une
## frappe au sol. Sous la moitié de ses points de vie, il enrage.

var _beats: int = 0


func enter(_previous: StringName) -> void:
	_beats = 0


func on_beat(_index: int) -> void:
	var tuning: TuningData = Tuning.data
	muet.update_target()
	muet.body.set_enraged(EnemyMath.boss_enraged(muet.health.current / muet.health.maximum, tuning))
	if muet.target == null:
		_beats = 0
		return
	_beats += 1
	if _beats >= tuning.boss_attack_every_beats:
		machine.transition_to(&"Telegraph")


func physics_update(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	var destination: Vector3 = muet.target.global_position if muet.target else muet.post
	var direction: Vector3 = muet.flat_direction_to(destination)
	var far_enough: bool = muet.flat_distance_to(destination) > tuning.boss_slam_radius / 2.0
	muet.face(direction)
	muet.move(direction * tuning.muet_walk_speed if far_enough else Vector3.ZERO, delta)
