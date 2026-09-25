class_name ChargerChargeState
extends MuetState
## Cornu, charge : tout droit, vite, sur une distance fixe ; un gros coup pour qui est sur le
## chemin. S'il heurte un obstacle, il s'assomme (et devient plus fragile).

## Direction de la charge, fixée à la fin de l'annonce.
var direction: Vector3 = Vector3.FORWARD

var _travelled: float = 0.0


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	_travelled = 0.0
	muet.face(direction)
	var duration: float = tuning.charger_distance / tuning.charger_speed
	muet.strike(tuning.charger_radius, CombatMath.FULL_CIRCLE_DEG, direction, duration, tuning.charger_damage, true)


func exit() -> void:
	muet.hitbox.deactivate()


func physics_update(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	var before: Vector3 = muet.global_position
	muet.move(direction * tuning.charger_speed, delta)
	_travelled += Vector2(muet.global_position.x - before.x, muet.global_position.z - before.z).length()
	if muet.is_on_wall():
		muet.stun(tuning.charger_stun_time)
	elif _travelled >= tuning.charger_distance:
		machine.transition_to(&"Walk")
