class_name FlyerDiveState
extends MuetState
## Volant, piqué : il file tout droit le long de la ligne annoncée, passe au ras du sol à
## mi-chemin puis remonte, en blessant au contact.

var _start: Vector3 = Vector3.ZERO
var _direction: Vector3 = Vector3.FORWARD
var _length: float = 0.0
var _elapsed: float = 0.0


## Prépare le piqué : départ (en vol), direction et longueur.
func plan(start: Vector3, direction: Vector3, length: float) -> void:
	_start = start
	_direction = direction
	_length = length


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	_elapsed = 0.0
	muet.face(_direction)
	muet.strike(tuning.flyer_radius, CombatMath.FULL_CIRCLE_DEG, _direction, tuning.flyer_dive_time, muet.damage_of(&"damage"), false)


func exit() -> void:
	muet.hitbox.deactivate()


func physics_update(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_elapsed += delta
	var fraction: float = minf(_elapsed / tuning.flyer_dive_time, 1.0)
	muet.velocity = Vector3.ZERO
	muet.body.set_motion(false, tuning.flyer_swoop_lean, 0.0, false, true)
	muet.global_position = EnemyMath.swoop_position(_start, _direction, _length, muet.post.y, tuning.flyer_dive_low, fraction, tuning.flyer_dive_curve)
	if fraction >= 1.0:
		machine.transition_to(&"Hover")
