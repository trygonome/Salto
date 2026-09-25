extends MuetState
## Sautillant : avance par bonds, un par temps, vers le héros repéré (sinon il revient vers son
## poste, ou sautille sur place). Il blesse au contact pendant tout le bond.

var _hop_left: float = 0.0
var _hop_velocity: Vector3 = Vector3.ZERO


func enter(_previous: StringName) -> void:
	_hop_left = 0.0


func on_beat(_index: int) -> void:
	if _hop_left > 0.0 or not muet.is_on_floor():
		return
	var tuning: TuningData = Tuning.data
	muet.update_target()
	var destination: Vector3 = muet.target.global_position if muet.target else muet.post
	var duration: float = EnemyMath.hop_duration(tuning.hopper_hop_height, tuning.muet_gravity)
	var distance: float = minf(muet.flat_distance_to(destination), tuning.hopper_hop_distance)
	var direction: Vector3 = muet.flat_direction_to(destination)
	_hop_velocity = direction * distance / duration
	_hop_left = duration
	muet.velocity.y = EnemyMath.hop_speed(tuning.hopper_hop_height, tuning.muet_gravity)
	muet.face(direction)
	muet.strike(tuning.hopper_radius, CombatMath.FULL_CIRCLE_DEG, direction, duration, tuning.hopper_damage, false)


func physics_update(delta: float) -> void:
	var hopping: bool = _hop_left > 0.0
	if hopping:
		_hop_left -= delta
	muet.move(_hop_velocity if hopping else Vector3.ZERO, delta)
