class_name MuetHopState
extends MuetState
## Bonds du prototype, pour toutes les espèces au sol : à chaque temps (ou un temps sur deux
## pour les plus lourds), un bond vers le héros repéré, vers son poste, ou au hasard. En
## chasse, chaque temps rapproche de l'attaque ; quand elle est prête et le héros à portée, le
## Muet passe dans l'état d'attaque de l'espèce.

## État d'attaque de l'espèce (vide : il n'attaque qu'au contact).
@export var act_state: StringName


func on_beat(index: int) -> void:
	muet.update_target()
	if muet.is_hopping():
		return
	if muet.target:
		muet.act_cooldown -= 1
		if act_state != &"" and muet.act_cooldown <= 0 and muet.act_in_range():
			muet.act_cooldown = muet.act_rest_beats()
			machine.transition_to(act_state)
			return
	if posmod(index + muet.parity, int(muet.stat(&"hop_every"))) != 0:
		return
	var offset: Vector3 = muet.next_hop(index)
	if offset.length() <= Tuning.data.muet_min_hop:
		return
	muet.hop(offset, muet.stat(&"hop_time"), muet.stat(&"hop_height"))


func physics_update(delta: float) -> void:
	if muet.target:
		muet.face(muet.flat_direction_to(muet.target.global_position))
	muet.body.set_motion(muet.is_hopping(), 0.0, 0.0, false, false)
	muet.move(Vector3.ZERO, delta)
