extends GutTest
## Règles de mouvement : gravité du saut variable, roulade, directions, lissage.

var tuning: TuningData = Tuning.data


func test_gravite_en_montee_bouton_tenu() -> void:
	assert_eq(HeroMotion.gravity(1.0, true, tuning), tuning.gravity_rise_held)


func test_gravite_en_montee_bouton_relache() -> void:
	assert_eq(HeroMotion.gravity(1.0, false, tuning), tuning.gravity_rise_released)


func test_gravite_en_descente_quel_que_soit_le_bouton() -> void:
	assert_eq(HeroMotion.gravity(-1.0, true, tuning), tuning.gravity_fall)
	assert_eq(HeroMotion.gravity(-1.0, false, tuning), tuning.gravity_fall)


func test_la_roulade_parcourt_exactement_sa_distance() -> void:
	var tail: float = tuning.roll_tail_fraction
	var fast: float = HeroMotion.roll_speed(0.0, tuning) * (1.0 - tail)
	var slow: float = HeroMotion.roll_speed(1.0, tuning) * tail
	assert_almost_eq((fast + slow) * tuning.roll_duration, tuning.roll_distance, 0.0001)


func test_la_fin_de_roulade_est_ralentie() -> void:
	var start: float = HeroMotion.roll_speed(0.0, tuning)
	var end: float = HeroMotion.roll_speed(1.0 - tuning.roll_tail_fraction / 2.0, tuning)
	assert_almost_eq(end, start * tuning.roll_tail_speed_factor, 0.0001)


func test_fenetre_d_invulnerabilite_de_la_roulade() -> void:
	assert_false(HeroMotion.is_roll_invulnerable(tuning.roll_invuln_start / 2.0, tuning))
	assert_true(HeroMotion.is_roll_invulnerable(tuning.roll_invuln_start, tuning))
	assert_true(HeroMotion.is_roll_invulnerable(tuning.roll_invuln_end, tuning))
	assert_false(HeroMotion.is_roll_invulnerable((tuning.roll_invuln_end + 1.0) / 2.0, tuning))


func test_le_haut_de_l_ecran_est_vers_moins_z() -> void:
	assert_eq(HeroMotion.world_direction(Vector2.UP), Vector3.FORWARD)
	assert_eq(HeroMotion.world_direction(Vector2.RIGHT), Vector3.RIGHT)


func test_le_lacet_retrouve_la_direction() -> void:
	for direction: Vector3 in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT, Vector3(1, 0, 1).normalized()]:
		var back: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, HeroMotion.yaw_of(direction))
		assert_almost_eq(back, direction, Vector3.ONE * 0.0001)


func test_lissage_nul_sans_temps_ni_vitesse() -> void:
	assert_eq(Smoothing.weight(10.0, 0.0), 0.0)
	assert_eq(Smoothing.weight(0.0, 1.0), 0.0)


func test_lissage_independant_du_decoupage_du_temps() -> void:
	var one_step: float = Smoothing.weight(11.0, 0.1)
	var half: float = Smoothing.weight(11.0, 0.05)
	var two_steps: float = 1.0 - (1.0 - half) * (1.0 - half)
	assert_almost_eq(two_steps, one_step, 0.000001)
