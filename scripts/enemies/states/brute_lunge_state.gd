class_name BruteLungeState
extends MuetState
## Brute, bond : elle saute sur la ligne annoncée ; à l'atterrissage, le héros à portée de ses
## poings est pris et jeté au loin (gros coup). Qu'elle ait pris ou non, elle reste essoufflée,
## sonnée et plus fragile, un moment (sa réponse : frapper quand elle est sonnée).

## Direction du bond, fixée à la fin de l'annonce.
var direction: Vector3 = Vector3.FORWARD
var _landed: bool = false


func enter(_previous: StringName) -> void:
	var tuning: TuningData = Tuning.data
	_landed = false
	muet.hop(direction * tuning.brute_lunge_distance, tuning.brute_lunge_time, tuning.brute_lunge_height, _on_land)


func allows_contact() -> bool:
	return false


func physics_update(delta: float) -> void:
	muet.body.set_motion(true, 0.0, 0.0, false, false)
	muet.move(Vector3.ZERO, delta)
	if _landed:
		muet.stun(Tuning.data.brute_winded_time)


func _on_land() -> void:
	var tuning: TuningData = Tuning.data
	_landed = true
	Feedback.shake(tuning.shake_trauma_hit, direction)
	var fx: Effects = muet.effects()
	if fx:
		fx.dust(muet.global_position, tuning.fx_impact_dust, tuning.fx_impact_dust_speed)
	var hero: Hero = muet.get_tree().get_first_node_in_group(&"hero") as Hero
	if hero == null:
		return
	var reach: float = muet.stat(&"radius") + hero.hurtbox.radius + tuning.brute_grab_reach
	if muet.flat_distance_to(hero.global_position) > reach or hero.global_position.y > muet.global_position.y + muet.body.height:
		return
	var hit := HitData.new()
	hit.attacker = muet
	hit.damage = muet.damage_of(&"damage")
	hit.big = true
	hit.launch = 1.0
	hit.move = &"grab"
	var flat := Vector3(hero.global_position.x - muet.global_position.x, 0.0, hero.global_position.z - muet.global_position.z)
	hit.direction = flat.normalized() if not flat.is_zero_approx() else direction
	hit.point = hero.hurtbox.center()
	hero.hurtbox.receive(hit)
