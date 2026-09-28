extends "res://tests/hero_test_base.gd"
## Bugs trouvés par le robot joueur (version 4.2.1).

const Hopper: PackedScene = preload("res://scenes/enemies/hopper.tscn")


func test_on_ne_tient_pas_debout_sur_une_sourdine() -> void:
	await _spawn_on_flat_ground()
	var muet: Muet = Hopper.instantiate() as Muet
	muet.position = Vector3(3.0, 0.0, 0.0)
	world.add_child(muet)
	await _step(2)
	muet.set_physics_process(false)
	hero.global_position = muet.global_position + Vector3(0.05, 1.2, 0.0)
	hero.velocity = Vector3.ZERO
	await _step(90)
	var flat: float = Vector2(hero.global_position.x - muet.global_position.x, hero.global_position.z - muet.global_position.z).length()
	assert_gt(flat, muet.hurtbox.radius, "le héros a glissé de la tête du sautillant")
	assert_lt(hero.global_position.y, 0.3, "et il est revenu au sol, à portée de coup")
