extends GutTest
## Règles des Muets : bond, piqué du volant, rage du Grand Muet, laisse ; PV du héros.

var tuning: TuningData = Tuning.data


func test_le_bond_monte_a_la_hauteur_voulue() -> void:
	var speed: float = EnemyMath.hop_speed(0.35, 11.8)
	assert_almost_eq(speed * speed / (2.0 * 11.8), 0.35, 0.0001)
	assert_almost_eq(EnemyMath.hop_duration(0.35, 11.8), 2.0 * speed / 11.8, 0.0001)


func test_le_pique_part_passe_au_ras_du_point_vise_et_remonte() -> void:
	var start := Vector3(0.0, 2.0, 0.0)
	var target := Vector3(3.0, 0.0, 1.0)
	assert_almost_eq(EnemyMath.swoop_position(start, target, 0.0), start, Vector3.ONE * 0.0001)
	assert_almost_eq(EnemyMath.swoop_position(start, target, 0.5), target, Vector3.ONE * 0.0001)
	assert_almost_eq(EnemyMath.swoop_position(start, target, 1.0), Vector3(6.0, 2.0, 2.0), Vector3.ONE * 0.0001)


func test_le_grand_muet_enrage_a_mi_vie() -> void:
	assert_false(EnemyMath.boss_enraged(tuning.boss_phase2_fraction + 0.01, tuning))
	assert_true(EnemyMath.boss_enraged(tuning.boss_phase2_fraction, tuning))


func test_laisse() -> void:
	assert_false(EnemyMath.beyond_leash(Vector3.ZERO, Vector3(3.0, 5.0, 0.0), 4.0), "la hauteur ne compte pas")
	assert_true(EnemyMath.beyond_leash(Vector3.ZERO, Vector3(3.0, 0.0, 3.0), 4.0))


func test_points_de_vie_du_heros() -> void:
	assert_eq(CombatMath.hero_max_health(1, tuning), tuning.hero_health_base)
	assert_eq(CombatMath.hero_max_health(2, tuning), tuning.hero_health_base + tuning.hero_health_per_level)
