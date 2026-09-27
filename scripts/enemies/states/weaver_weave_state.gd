extends MuetState
## Tisserand : il tisse des ronces là où se tient le héros. Un cercle s'annonce sous ses pieds
## pendant quelques temps (le tisserand agite ses pattes), puis les ronces poussent : il faut en
## sortir. Un coup reçu pendant qu'il tisse l'en dissuade.

## Ronces qui poussent.
@export var bramble_scene: PackedScene

var _left: float = 0.0
var _at: Vector3 = Vector3.ZERO


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	_left = muet.beats_to_seconds(tuning.weaver_weave_beats)
	_at = muet.target.global_position if muet.target else muet.global_position + muet.facing()
	_at.y = muet.global_position.y
	muet.telegraph().show_circle(_at, tuning.weaver_bramble_radius, _left)


func interruptible() -> bool:
	return true


func exit() -> void:
	for mark: Node in get_tree().get_nodes_in_group(&"telegraphs"):
		if (mark as Node3D).global_position.distance_to(_at) < 0.5 and _left > 0.0:
			mark.queue_free()


func physics_update(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	muet.face(muet.flat_direction_to(_at))
	muet.body.set_motion(false, 0.0, tuning.spitter_inflate * 0.5, true, false)
	muet.move(Vector3.ZERO, delta)
	_left -= delta
	if _left <= 0.0:
		var bramble: BrambleHazard = bramble_scene.instantiate() as BrambleHazard
		bramble.damage = muet.damage_of(&"damage")
		bramble.source = muet
		muet.get_parent().add_child(bramble)
		bramble.global_position = _at
		machine.transition_to(&"Hop")
