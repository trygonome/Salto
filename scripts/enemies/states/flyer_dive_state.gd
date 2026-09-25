class_name FlyerDiveState
extends MuetState
## Volant, piqué : il passe au ras du sol à l'endroit annoncé puis remonte de l'autre côté,
## en blessant au contact.

var _start: Vector3 = Vector3.ZERO
var _target: Vector3 = Vector3.ZERO
var _elapsed: float = 0.0


## Prépare le piqué : départ (en vol) et point visé au sol.
func plan(start: Vector3, target: Vector3) -> void:
	_start = start
	_target = target


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	_elapsed = 0.0
	var direction: Vector3 = muet.flat_direction_to(_target)
	muet.face(direction)
	muet.strike(tuning.flyer_radius, CombatMath.FULL_CIRCLE_DEG, direction, tuning.flyer_dive_time, tuning.flyer_damage, false)


func physics_update(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_elapsed += delta
	var fraction: float = minf(_elapsed / tuning.flyer_dive_time, 1.0)
	muet.velocity = Vector3.ZERO
	muet.global_position = EnemyMath.swoop_position(_start, _target, fraction)
	if fraction >= 1.0:
		machine.transition_to(&"Orbit")
