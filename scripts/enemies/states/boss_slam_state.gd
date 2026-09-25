extends MuetState
## Grand Muet, frappe au sol : tout le cercle annoncé est touché (gros coup) ; anneau rouge,
## cubes qui jaillissent, la caméra tremble. En rage (et toujours pour le Roi Muet), la frappe
## lance aussi une onde de choc qui s'élargit : il faut sauter par-dessus. Les nuits suivantes,
## elle appelle des renforts s'il reste peu de gardiens, puis lance une couronne de bulles.

## Onde de choc de la phase 2.
@export var wave_scene: PackedScene
## Grondement de la frappe.
@export var sound: AudioStreamPlayer3D
## Bulle de silence de la couronne.
@export var orb_scene: PackedScene

var _left: float = 0.0


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	_left = muet.beats_to_seconds(1)
	muet.strike(muet.slam_radius(), CombatMath.FULL_CIRCLE_DEG, muet.facing(), tuning.attack_active_time, muet.damage_of(&"slam_damage"), true)
	muet.body.squash(-tuning.muet_squash_slam)
	Feedback.shake(tuning.shake_trauma_dive, Vector3.ZERO)
	var fx: Effects = muet.effects()
	if fx:
		fx.slam(muet.global_position, muet.slam_radius())
	if sound:
		sound.play()
	if muet.enraged or muet.king:
		var wave: ShockWaveHazard = wave_scene.instantiate() as ShockWaveHazard
		wave.damage = muet.damage_of(&"damage") * tuning.boss_wave_damage_factor
		muet.get_parent().add_child(wave)
		wave.global_position = muet.global_position
	if Game.night >= tuning.boss_orb_night or muet.king:
		_orb_crown()
	if Game.night >= tuning.boss_summon_night or muet.king:
		get_tree().call_group(&"night_level", &"summon_guards", muet)


## Couronne de bulles de silence tout autour du Grand Muet.
func _orb_crown() -> void:
	var tuning: TuningData = Tuning.data
	if orb_scene == null:
		return
	var turn: float = muet.rng.randf() * TAU
	for i: int in tuning.boss_orb_count:
		var angle: float = turn + TAU * i / tuning.boss_orb_count
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var orb: SilenceOrb = orb_scene.instantiate() as SilenceOrb
		orb.direction = direction
		orb.speed = tuning.boss_orb_speed
		orb.damage = muet.damage_of(&"damage") * tuning.boss_orb_damage_factor
		orb.source = muet
		muet.get_parent().add_child(orb)
		orb.global_position = muet.global_position + direction * tuning.boss_orb_spawn_distance + Vector3.UP * tuning.spitter_orb_height


func physics_update(delta: float) -> void:
	muet.body.set_motion(false, 0.0, 0.0, false, false)
	muet.move(Vector3.ZERO, delta)
	_left -= delta
	if _left <= 0.0:
		machine.transition_to(&"Hop")
