extends MuetState
## Libéré : le Muet retrouve sa voix, reprend ses couleurs, puis disparaît.

var _left: float = 0.0


func enter(_previous: StringName) -> void:
	_left = Tuning.data.muet_freed_time
	muet.release()


func physics_update(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		muet.queue_free()
