extends MuetState
## Cracheur : il se gonfle un temps, puis crache une bulle de silence vers le héros. Un coup reçu
## pendant qu'il se gonfle l'en dissuade.

## Bulle de silence crachée.
@export var orb_scene: PackedScene
## Bruit du crachat.
@export var sound: AudioStreamPlayer3D

var _left: float = 0.0


func enter(_previous: StringName) -> void:
	_left = muet.beats_to_seconds(Tuning.data.spitter_prepare_beats)


func interruptible() -> bool:
	return true


func physics_update(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	if muet.target:
		muet.face(muet.flat_direction_to(muet.target.global_position))
	muet.body.set_motion(false, 0.0, tuning.spitter_inflate, false, false)
	muet.move(Vector3.ZERO, delta)
	_left -= delta
	if _left <= 0.0:
		_spit()
		machine.transition_to(&"Hop")


func _spit() -> void:
	var tuning: TuningData = Tuning.data
	var direction: Vector3 = muet.flat_direction_to(muet.target.global_position) if muet.target else muet.facing()
	var orb: SilenceOrb = orb_scene.instantiate() as SilenceOrb
	orb.direction = direction
	orb.damage = muet.damage_of(&"damage")
	orb.source = muet
	muet.get_parent().add_child(orb)
	orb.global_position = muet.global_position + direction * tuning.spitter_orb_spawn_distance + Vector3.UP * tuning.spitter_orb_height
	muet.body.squash(-tuning.muet_squash_spit)
	if sound:
		sound.play()
