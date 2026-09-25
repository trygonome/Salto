extends GutTest
## Règles des Muets : forces, bonds, distances du cracheur, piqué du volant, bouclier, rage du
## Grand Muet, laisse ; PV du héros.

var tuning: TuningData = Tuning.data


func test_les_muets_sont_plus_forts_loin_du_village_et_nuit_apres_nuit() -> void:
	assert_eq(EnemyMath.scaled(30.0, 9.0, 0, 0.25, 1), 30.0, "sautillant du premier sanctuaire, nuit 1")
	assert_eq(EnemyMath.scaled(30.0, 9.0, 2, 0.25, 1), 48.0, "troisième sanctuaire")
	assert_eq(EnemyMath.scaled(170.0, 80.0, 1, 0.25, 3), 375.0, "Grand Muet du deuxième sanctuaire, nuit 3")
	assert_eq(EnemyMath.scaled(9.0, 3.0, 0, 0.15, 0), 9.0, "hors d'une nuit : comme la nuit 1")


func test_le_bond_part_vite_et_arrive_en_douceur() -> void:
	assert_eq(EnemyMath.ease_out(0.0), 0.0)
	assert_eq(EnemyMath.ease_out(1.0), 1.0)
	assert_gt(EnemyMath.ease_out(0.5), 0.5)


func test_un_corps_voxel_regarde_vers_sa_direction() -> void:
	var yaw: float = EnemyMath.yaw_of(Vector3(1.0, 0.0, 0.0))
	assert_almost_eq(Vector3(sin(yaw), 0.0, cos(yaw)), Vector3(1.0, 0.0, 0.0), Vector3.ONE * 0.0001)
	assert_almost_eq(EnemyMath.yaw_of(Vector3.BACK), 0.0, 0.0001, "de face (+z) : pas de rotation")


func test_le_cracheur_garde_ses_distances() -> void:
	var toward := Vector3(0.0, 0.0, -1.0)
	assert_eq(EnemyMath.keep_distance(toward, tuning.spitter_keep_min * 0.5, 0, 0, tuning), -toward, "trop près : il recule")
	assert_eq(EnemyMath.keep_distance(toward, tuning.spitter_keep_max * 2.0, 0, 0, tuning), toward, "trop loin : il avance")
	var middle: float = (tuning.spitter_keep_min + tuning.spitter_keep_max) / 2.0
	var side: Vector3 = EnemyMath.keep_distance(toward, middle, 0, 0, tuning)
	assert_almost_eq(side.dot(toward), 0.0, 0.0001, "entre les deux : il tourne autour")
	var later: Vector3 = EnemyMath.keep_distance(toward, middle, tuning.spitter_strafe_beats, 0, tuning)
	assert_eq(later, -side, "et change de sens tous les quelques temps")


func test_le_pique_part_rase_le_sol_a_mi_chemin_et_remonte() -> void:
	var start := Vector3(0.0, 2.0, 0.0)
	var direction := Vector3(1.0, 0.0, 0.0)
	assert_almost_eq(EnemyMath.swoop_position(start, direction, 4.0, 0.0, 0.3, 0.0, 1.6), start, Vector3.ONE * 0.0001)
	assert_almost_eq(EnemyMath.swoop_position(start, direction, 4.0, 0.0, 0.3, 0.5, 1.6), Vector3(2.0, 0.3, 0.0), Vector3.ONE * 0.0001)
	assert_almost_eq(EnemyMath.swoop_position(start, direction, 4.0, 0.0, 0.3, 1.0, 1.6), Vector3(4.0, 2.0, 0.0), Vector3.ONE * 0.0001)


func test_le_bouclier_arrete_les_coups_de_face_mais_pas_les_plongeons() -> void:
	var facing := Vector3.BACK
	assert_true(EnemyMath.shield_blocks(facing, Vector3.FORWARD, tuning.shielder_block_angle), "héros devant lui")
	assert_false(EnemyMath.shield_blocks(facing, Vector3.BACK, tuning.shielder_block_angle), "héros derrière lui")
	assert_false(EnemyMath.shield_blocks(facing, Vector3.LEFT, tuning.shielder_block_angle), "héros sur le côté")
	assert_true(EnemyMath.goes_over_shield(&"dive"))
	assert_true(EnemyMath.goes_over_shield(&"rainbow"))
	assert_false(EnemyMath.goes_over_shield(&"martelo"))


func test_le_grand_muet_enrage_a_mi_vie() -> void:
	assert_false(EnemyMath.boss_enraged(tuning.boss_phase2_fraction + 0.01, tuning))
	assert_true(EnemyMath.boss_enraged(tuning.boss_phase2_fraction, tuning))


func test_laisse() -> void:
	assert_false(EnemyMath.beyond_leash(Vector3.ZERO, Vector3(3.0, 5.0, 0.0), 4.0), "la hauteur ne compte pas")
	assert_true(EnemyMath.beyond_leash(Vector3.ZERO, Vector3(3.0, 0.0, 3.0), 4.0))


func test_points_de_vie_du_heros() -> void:
	assert_eq(CombatMath.hero_max_health(1, tuning), tuning.hero_health_base)
	assert_eq(CombatMath.hero_max_health(2, tuning), tuning.hero_health_base + tuning.hero_health_per_level)
