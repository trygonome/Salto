extends GutTest
## Règles de combat : zone touchée, visée automatique, dégâts, combo, plongeon.

var tuning: TuningData = Tuning.data


func test_l_attaque_de_base_est_celle_du_niveau_1() -> void:
	assert_eq(CombatMath.hero_attack(1, tuning), tuning.hero_attack_base)
	assert_eq(CombatMath.hero_attack(3, tuning), tuning.hero_attack_base + 2.0 * tuning.hero_attack_per_level)


func test_le_combo_augmente_puis_plafonne() -> void:
	assert_eq(CombatMath.combo_multiplier(0, tuning), 1.0)
	assert_almost_eq(CombatMath.combo_multiplier(5, tuning), 1.0 + 5.0 * tuning.combo_bonus_per_hit, 0.0001)
	assert_almost_eq(CombatMath.combo_multiplier(1000, tuning), 1.0 + tuning.combo_bonus_max, 0.0001)


func test_les_degats_multiplient_tout() -> void:
	var normal: float = CombatMath.damage(10.0, 1.5, 1.2, false, tuning)
	assert_almost_eq(normal, 18.0, 0.0001)
	assert_almost_eq(CombatMath.damage(10.0, 1.5, 1.2, true, tuning), normal * tuning.crit_multiplier, 0.0001)


func test_la_portee_s_ajoute_au_rayon_de_la_cible() -> void:
	var origin := Vector3.ZERO
	assert_true(CombatMath.in_strike_zone(origin, Vector3.FORWARD, Vector3(0, 0, -1.1), 0.35, 0.8, 120.0))
	assert_false(CombatMath.in_strike_zone(origin, Vector3.FORWARD, Vector3(0, 0, -1.2), 0.35, 0.8, 120.0))


func test_une_cible_derriere_n_est_pas_touchee_par_un_coup_frontal() -> void:
	assert_false(CombatMath.in_strike_zone(Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, 0.8), 0.35, 0.8, 120.0))


func test_une_cible_au_bord_de_l_arc_est_touchee_grace_a_sa_largeur() -> void:
	# À 65° du regard, hors d'un arc de 120° (±60°), mais la cible déborde dans l'arc.
	var target: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(65.0)) * 1.0
	assert_true(CombatMath.in_strike_zone(Vector3.ZERO, Vector3.FORWARD, target, 0.35, 0.8, 120.0))
	var far_side: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(90.0)) * 1.0
	assert_false(CombatMath.in_strike_zone(Vector3.ZERO, Vector3.FORWARD, far_side, 0.35, 0.8, 120.0))


func test_un_coup_tournoyant_touche_tout_autour() -> void:
	assert_true(CombatMath.in_strike_zone(Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, 1.2), 0.35, 1.0, 360.0))


func test_la_hauteur_est_ignoree() -> void:
	assert_true(CombatMath.in_strike_zone(Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0.5, -1.0), 0.35, 0.8, 120.0))


func test_visee_automatique_prend_la_plus_proche_dans_le_cone() -> void:
	var targets := PackedVector3Array([Vector3(0, 0, -1.3), Vector3(0.3, 0, -0.9), Vector3(0, 0, 0.5)])
	assert_eq(CombatMath.pick_target(Vector3.ZERO, Vector3.FORWARD, targets, 1.4, 80.0), 1)


func test_visee_automatique_ignore_hors_cone_et_trop_loin() -> void:
	var targets := PackedVector3Array([Vector3(1.0, 0, -0.2), Vector3(0, 0, -2.0)])
	assert_eq(CombatMath.pick_target(Vector3.ZERO, Vector3.FORWARD, targets, 1.4, 80.0), -1)


func test_onde_du_plongeon_grandit_avec_la_chute_puis_plafonne() -> void:
	assert_eq(CombatMath.dive_radius(0.0, tuning), tuning.dive_radius_base)
	assert_almost_eq(CombatMath.dive_radius(1.0, tuning), tuning.dive_radius_base + tuning.dive_radius_per_meter, 0.0001)
	assert_almost_eq(CombatMath.dive_radius(100.0, tuning), tuning.dive_radius_base + tuning.dive_radius_bonus_max, 0.0001)
	assert_eq(CombatMath.dive_radius(-1.0, tuning), tuning.dive_radius_base, "une « chute » vers le haut ne réduit pas l'onde")


func test_degats_du_plongeon_grandissent_avec_la_chute_puis_plafonnent() -> void:
	assert_eq(CombatMath.dive_multiplier(0.0, tuning), tuning.dive_multiplier_base)
	assert_almost_eq(CombatMath.dive_multiplier(1.0, tuning), tuning.dive_multiplier_base + tuning.dive_multiplier_per_meter, 0.0001)
	assert_almost_eq(CombatMath.dive_multiplier(100.0, tuning), tuning.dive_multiplier_base + tuning.dive_multiplier_bonus_max, 0.0001)
