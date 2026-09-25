extends MuetState
## Grand Muet, frappe au sol : tout le cercle annoncé est touché (gros coup) ; anneau rouge,
## cubes qui jaillissent, la caméra tremble. En rage, la frappe lance aussi une onde de choc qui
## s'élargit : il faut sauter par-dessus.

## Onde de choc de la phase 2.
@export var wave_scene: PackedScene
## Grondement de la frappe.
@export var sound: AudioStreamPlayer3D

var _left: float = 0.0


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	_left = muet.beats_to_seconds(1)
	muet.strike(tuning.boss_slam_radius, CombatMath.FULL_CIRCLE_DEG, muet.facing(), tuning.attack_active_time, muet.damage_of(&"slam_damage"), true)
	muet.body.squash(-tuning.muet_squash_slam)
	Feedback.shake(tuning.shake_trauma_dive, Vector3.ZERO)
	var fx: Effects = muet.effects()
	if fx:
		fx.slam(muet.global_position, tuning.boss_slam_radius)
	if sound:
		sound.play()
	if muet.enraged:
		var wave: ShockWaveHazard = wave_scene.instantiate() as ShockWaveHazard
		wave.damage = muet.damage_of(&"damage") * tuning.boss_wave_damage_factor
		muet.get_parent().add_child(wave)
		wave.global_position = muet.global_position


func physics_update(delta: float) -> void:
	muet.body.set_motion(false, 0.0, 0.0, false, false)
	muet.move(Vector3.ZERO, delta)
	_left -= delta
	if _left <= 0.0:
		machine.transition_to(&"Hop")
