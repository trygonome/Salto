extends MuetState
## Totem chanteur : il se gonfle un temps, puis chante : un anneau de notes s'élargit autour de lui ;
## les Muets à portée sont protégés un moment (ils brillent), un peu soignés, et leur attaque
## approche d'un temps. Il faut l'abattre d'abord. Un coup reçu pendant qu'il se gonfle l'en dissuade.

## Son du chant.
@export var sound: AudioStreamPlayer3D

var _left: float = 0.0


func enter(_previous: StringName) -> void:
	_left = muet.beats_to_seconds(Tuning.data.totem_sing_beats)


func interruptible() -> bool:
	return true


func physics_update(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	var progress: float = 1.0 - _left / muet.beats_to_seconds(tuning.totem_sing_beats)
	muet.body.set_motion(false, 0.0, tuning.totem_inflate * progress, false, false)
	muet.move(Vector3.ZERO, delta)
	_left -= delta
	if _left <= 0.0:
		_sing()
		machine.transition_to(&"Hop")


func _sing() -> void:
	var tuning: TuningData = Tuning.data
	muet.body.squash(-tuning.muet_squash_spit)
	if sound:
		sound.play()
	var fx: Effects = muet.effects()
	if fx:
		fx.ring(muet.global_position, tuning.totem_aura_radius, fx.cyan, tuning.fx_break_ring_time, true)
	for node: Node in get_tree().get_nodes_in_group(&"muets"):
		var other: Muet = node as Muet
		if other == muet or other.is_freed() or muet.flat_distance_to(other.global_position) > tuning.totem_aura_radius:
			continue
		other.ward(tuning.totem_ward_time, tuning.totem_ward_multiplier)
		other.health.heal(other.health.maximum * tuning.totem_heal)
		other.act_cooldown = maxi(other.act_cooldown - 1, 1)
