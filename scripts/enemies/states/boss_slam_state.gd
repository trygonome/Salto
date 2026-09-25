extends MuetState
## Grand Muet, frappe au sol : tout le cercle annoncé est touché (gros coup). En rage, la frappe
## lance aussi une onde de choc qui s'élargit : il faut sauter par-dessus.

## Onde de choc de la phase 2.
@export var wave_scene: PackedScene
## Grondement de la frappe.
@export var sound: AudioStreamPlayer3D

var _left: float = 0.0


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	_left = muet.beats_to_seconds(1)
	var forward: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, muet.body.rotation.y)
	muet.strike(tuning.boss_slam_radius, CombatMath.FULL_CIRCLE_DEG, forward, tuning.attack_active_time, tuning.boss_slam_damage, true)
	Feedback.shake(tuning.shake_trauma_dive, Vector3.ZERO)
	if sound:
		sound.play()
	if EnemyMath.boss_enraged(muet.health.current / muet.health.maximum, tuning):
		var wave: Node3D = wave_scene.instantiate() as Node3D
		muet.get_parent().add_child(wave)
		wave.global_position = muet.global_position


func physics_update(delta: float) -> void:
	muet.move(Vector3.ZERO, delta)
	_left -= delta
	if _left <= 0.0:
		machine.transition_to(&"Walk")
