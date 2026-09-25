extends "res://tests/hero_test_base.gd"
## Le héros dans un petit monde physique : course, saut variable, salto, tolérance de bord,
## mémoire des appuis, roulade, élan aérien, marches. Les commandes sont simulées image par image.


func test_reste_au_sol_au_repos() -> void:
	await _spawn_on_flat_ground()
	await _step(30)
	assert_eq(_state(), &"Ground")
	assert_almost_eq(hero.global_position.y, 0.0, TOLERANCE)


func test_la_course_atteint_la_vitesse_voulue() -> void:
	await _spawn_on_flat_ground()
	hero.input_move = Vector2.RIGHT
	await _step(60)
	assert_almost_eq(hero.horizontal_velocity().length(), tuning.run_speed, 0.05)
	assert_almost_eq(hero.facing_direction(), Vector3.RIGHT, Vector3.ONE * 0.05)


func test_le_saut_tenu_monte_a_la_hauteur_prevue() -> void:
	await _spawn_on_flat_ground()
	hero.input_jump_held = true
	hero.press(&"jump")
	var apex: float = await _measure_apex()
	assert_almost_eq(apex, _expected_apex(tuning.jump_speed, tuning.gravity_rise_held), TOLERANCE)


func test_le_saut_relache_tot_est_plus_petit() -> void:
	await _spawn_on_flat_ground()
	hero.input_jump_held = false
	hero.press(&"jump")
	var apex: float = await _measure_apex()
	assert_almost_eq(apex, _expected_apex(tuning.jump_speed, tuning.gravity_rise_released), TOLERANCE)


func test_le_deuxieme_saut_est_un_salto_plus_haut() -> void:
	await _spawn_on_flat_ground()
	hero.input_jump_held = true
	hero.press(&"jump")
	await _step(20)
	hero.press(&"jump")
	var apex: float = await _measure_apex()
	assert_gt(apex, _expected_apex(tuning.jump_speed, tuning.gravity_rise_held) + TOLERANCE * 5.0)


func test_pas_de_troisieme_saut() -> void:
	await _spawn_on_flat_ground()
	hero.input_jump_held = true
	for i: int in tuning.max_jumps + 1:
		hero.press(&"jump")
		await _step(15)
	assert_eq(hero.jumps_used, tuning.max_jumps)
	assert_lt(hero.velocity.y, 0.0, "le troisième appui ne relance pas le héros vers le haut")


func test_saut_appuye_juste_avant_l_atterrissage() -> void:
	await _spawn_on_flat_ground()
	hero.input_jump_held = true
	# Saut puis salto : il ne reste plus de saut en l'air, l'appui suivant attend le sol.
	hero.press(&"jump")
	await _step(15)
	hero.press(&"jump")
	await _step(1)
	while not (hero.velocity.y < 0.0 and hero.global_position.y < 0.2):
		await _step(1)
	hero.press(&"jump")
	await _wait_for_state(&"Ground")
	await _step(1)
	assert_eq(_state(), &"Air", "l'appui mémorisé fait repartir le héros dès l'atterrissage")
	assert_gt(hero.velocity.y, 0.0)


func test_tolerance_de_bord_donne_un_saut_normal() -> void:
	await _spawn_on_ledge()
	await _run_off_ledge()
	assert_gt(hero.coyote_left, 0.0)
	hero.press(&"jump")
	await _step(1)
	assert_eq(hero.jumps_used, 1, "saut normal : il reste le salto")
	assert_gt(hero.velocity.y, 0.0)


func test_apres_la_tolerance_le_saut_en_l_air_est_le_salto() -> void:
	await _spawn_on_ledge()
	await _run_off_ledge()
	await _step(roundi(tuning.coyote_time * Engine.physics_ticks_per_second) + 2)
	hero.press(&"jump")
	await _step(1)
	assert_eq(hero.jumps_used, tuning.max_jumps)
	assert_gt(hero.velocity.y, 0.0)


func _spawn_on_ledge() -> void:
	_add_block(Vector3(4.0, 1.0, 4.0), Vector3(0.0, 0.5, 0.0))
	_add_block(Vector3(60.0, 1.0, 60.0), Vector3(0.0, -3.5, 0.0))
	await _spawn(Vector3(0.0, 1.0, 0.0))


func _run_off_ledge() -> void:
	hero.input_move = Vector2.UP
	await _wait_for_state(&"Air")
	hero.input_move = Vector2.ZERO


func test_la_roulade_parcourt_sa_distance() -> void:
	await _spawn_on_flat_ground()
	var start: Vector3 = hero.global_position
	hero.press(&"dodge")
	await _wait_for_state(&"Roll")
	while _state() == &"Roll":
		await _step(1)
	var travelled: float = (hero.global_position - start).length()
	assert_almost_eq(travelled, tuning.roll_distance, TOLERANCE * 2.0)


func test_la_roulade_rend_invulnerable_en_son_milieu() -> void:
	await _spawn_on_flat_ground()
	hero.press(&"dodge")
	await _wait_for_state(&"Roll")
	var middle: float = (tuning.roll_invuln_start + tuning.roll_invuln_end) / 2.0
	await _step(roundi(middle * tuning.roll_duration * Engine.physics_ticks_per_second))
	assert_true(hero.invulnerable)
	await _wait_for_state(&"Ground")
	assert_false(hero.invulnerable)


func test_sauter_depuis_la_roulade_garde_l_elan() -> void:
	await _spawn_on_flat_ground()
	hero.press(&"dodge")
	await _wait_for_state(&"Roll")
	hero.press(&"jump")
	await _wait_for_state(&"Air")
	assert_almost_eq(hero.horizontal_velocity().length(), tuning.roll_jump_carry_speed, 0.1)
	assert_eq(hero.jumps_used, 1)


func test_l_elan_aerien_file_a_l_horizontale() -> void:
	await _spawn_on_flat_ground()
	hero.input_jump_held = true
	hero.press(&"jump")
	await _step(10)
	var start: Vector3 = hero.global_position
	hero.press(&"dodge")
	await _wait_for_state(&"AirDash")
	await _wait_for_state(&"Air")
	var travelled: Vector3 = hero.global_position - start
	assert_almost_eq(Vector2(travelled.x, travelled.z).length(), tuning.air_dash_speed * tuning.air_dash_duration, TOLERANCE * 3.0)
	assert_almost_eq(travelled.y, 0.0, TOLERANCE, "pas de gravité pendant l'élan")


func test_un_seul_elan_par_saut() -> void:
	await _spawn_on_flat_ground()
	hero.input_jump_held = true
	hero.press(&"jump")
	await _step(5)
	hero.press(&"dodge")
	await _wait_for_state(&"AirDash")
	await _wait_for_state(&"Air")
	hero.press(&"dodge")
	await _step(2)
	assert_eq(_state(), &"Air")
	assert_eq(hero.air_dashes_used, tuning.air_dashes_per_jump)


func test_monte_une_marche_basse_sans_sauter() -> void:
	await _spawn_on_flat_ground()
	var step: float = tuning.step_height * 0.8
	_add_block(Vector3(4.0, step, 4.0), Vector3(0.0, step / 2.0, -2.5))
	hero.input_move = Vector2.UP
	await _step(60)
	assert_lt(hero.global_position.z, -1.5, "le héros avance sur la marche")
	assert_almost_eq(hero.global_position.y, step, TOLERANCE)


func test_une_marche_trop_haute_bloque() -> void:
	await _spawn_on_flat_ground()
	var step: float = tuning.step_height * 2.0
	_add_block(Vector3(4.0, step, 4.0), Vector3(0.0, step / 2.0, -2.5))
	hero.input_move = Vector2.UP
	await _step(60)
	assert_gt(hero.global_position.z, -0.5, "le héros reste devant la marche")
	assert_almost_eq(hero.global_position.y, 0.0, TOLERANCE)


func test_une_chute_ramene_au_depart() -> void:
	await _spawn_on_flat_ground()
	hero.global_position = Vector3(5.0, -tuning.respawn_fall_depth - 1.0, 5.0)
	await _step(2)
	assert_almost_eq(hero.global_position.x, 0.0, TOLERANCE)
	assert_almost_eq(hero.global_position.z, 0.0, TOLERANCE)
