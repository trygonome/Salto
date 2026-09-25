extends "res://tests/hero_test_base.gd"
## Le héros frappe des mannequins : enchaînement, dégâts, annulations, fin écourtée,
## orientation automatique, coup roulé, plongeon et arrêt sur image.

var landed: Array[HitData] = []


func before_each() -> void:
	super.before_each()
	landed = []


func _spawn_fighter() -> void:
	await _spawn_on_flat_ground()
	hero.hit_landed.connect(func(hit: HitData) -> void: landed.append(hit))


func _moves() -> Array[StringName]:
	var moves: Array[StringName] = []
	for hit: HitData in landed:
		moves.append(hit.move)
	return moves


## Attaque du coup, hors combo et hors critique.
func _base_damage(hit: HitData) -> float:
	return hit.damage / (tuning.crit_multiplier if hit.critical else 1.0)


## Attend la fin de tous les coups en cours (retour au sol, au plus MAX_FRAMES images).
func _wait_until_idle() -> void:
	await _step(1)
	for i: int in MAX_FRAMES:
		if _state() == &"Ground":
			return
		await _step(1)
	fail_test("le héros n'est jamais revenu au sol")


func test_trois_frappes_font_martelo_meia_lua_armada() -> void:
	await _spawn_fighter()
	var dummy: TrainingDummy = _add_dummy(Vector3(0.0, 0.0, -1.0))
	for i: int in tuning.combo_attacks.size():
		hero.press(&"attack")
		await _step(12)
	await _wait_until_idle()
	assert_eq(_moves(), [&"martelo", &"meia_lua", &"armada"] as Array[StringName])
	assert_eq(dummy.hits_taken, 3, "chaque coup touche une seule fois")


func test_les_degats_suivent_le_coup_et_le_combo() -> void:
	await _spawn_fighter()
	_add_dummy(Vector3(0.0, 0.0, -1.0))
	hero.press(&"attack")
	await _step(12)
	hero.press(&"attack")
	await _wait_until_idle()
	var attack: float = CombatMath.hero_attack(tuning.hero_start_level, tuning)
	assert_almost_eq(_base_damage(landed[0]), attack * tuning.combo_attacks[0].damage_multiplier, 0.001)
	var second_expected: float = attack * tuning.combo_attacks[1].damage_multiplier * CombatMath.combo_multiplier(1, tuning)
	assert_almost_eq(_base_damage(landed[1]), second_expected, 0.001)
	assert_eq(hero.combo.hits, 2)


func test_un_coup_qui_touche_fige_le_jeu_un_instant() -> void:
	await _spawn_fighter()
	_add_dummy(Vector3(0.0, 0.0, -1.0))
	hero.press(&"attack")
	for i: int in MAX_FRAMES:
		if not landed.is_empty():
			break
		await _step(1)
	assert_true(Feedback.is_frozen(), "arrêt sur image au moment du coup")
	await get_tree().create_timer(tuning.hit_stop_hit * 2.0, true, false, true).timeout
	await get_tree().process_frame
	assert_false(Feedback.is_frozen(), "le jeu repart")


func test_apres_une_pause_l_enchainement_repart_du_debut() -> void:
	await _spawn_fighter()
	_add_dummy(Vector3(0.0, 0.0, -1.0))
	hero.press(&"attack")
	await _wait_until_idle()
	await _step(roundi(tuning.combo_chain_window * 1.5 * Engine.physics_ticks_per_second))
	hero.press(&"attack")
	await _wait_until_idle()
	assert_eq(_moves(), [&"martelo", &"martelo"] as Array[StringName])


func test_frappe_juste_apres_un_coup_continue_l_enchainement() -> void:
	await _spawn_fighter()
	_add_dummy(Vector3(0.0, 0.0, -1.0))
	hero.press(&"attack")
	await _wait_until_idle()
	hero.press(&"attack")
	await _wait_until_idle()
	assert_eq(_moves(), [&"martelo", &"meia_lua"] as Array[StringName])


func test_l_esquive_interrompt_un_coup() -> void:
	await _spawn_fighter()
	hero.press(&"attack")
	await _wait_for_state(&"Attack")
	await _step(2)
	hero.press(&"dodge")
	await _step(1)
	assert_eq(_state(), &"Roll")


func test_le_saut_interrompt_un_coup() -> void:
	await _spawn_fighter()
	hero.press(&"attack")
	await _wait_for_state(&"Attack")
	await _step(2)
	hero.input_jump_held = true
	hero.press(&"jump")
	await _step(1)
	assert_eq(_state(), &"Air")
	assert_gt(hero.velocity.y, 0.0)


func test_pousser_le_joystick_ecourte_la_fin_du_coup() -> void:
	await _spawn_fighter()
	var martelo: AttackData = tuning.combo_attacks[0]
	hero.press(&"attack")
	await _wait_for_state(&"Attack")
	hero.input_move = Vector2.RIGHT
	var cancel_frame: int = ceili((martelo.chain_from + tuning.move_cancel_delay) * Engine.physics_ticks_per_second)
	var end_frame: int = ceili(martelo.duration * Engine.physics_ticks_per_second)
	await _step(cancel_frame + 1)
	assert_eq(_state(), &"Ground", "fin écourtée avant la fin normale (image %d)" % end_frame)


func test_sans_joystick_le_coup_va_jusqu_au_bout() -> void:
	await _spawn_fighter()
	var martelo: AttackData = tuning.combo_attacks[0]
	hero.press(&"attack")
	await _wait_for_state(&"Attack")
	await _step(ceili((martelo.chain_from + tuning.move_cancel_delay) * Engine.physics_ticks_per_second) + 1)
	assert_eq(_state(), &"Attack")


func test_orientation_automatique_vers_le_mannequin_proche() -> void:
	await _spawn_fighter()
	var side: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(tuning.auto_aim_cone_deg * 0.4))
	_add_dummy(side * tuning.auto_aim_range * 0.8)
	hero.press(&"attack")
	await _wait_for_state(&"Attack")
	assert_almost_eq(hero.facing_direction(), side, Vector3.ONE * 0.02)
	await _wait_until_idle()
	assert_eq(landed.size(), 1)


func test_pas_d_orientation_vers_un_mannequin_hors_du_cone() -> void:
	await _spawn_fighter()
	_add_dummy(Vector3.RIGHT * tuning.auto_aim_range * 0.8)
	hero.press(&"attack")
	await _wait_for_state(&"Attack")
	assert_almost_eq(hero.facing_direction(), Vector3.FORWARD, Vector3.ONE * 0.02)


func test_frappe_pendant_la_roulade_donne_le_coup_roule() -> void:
	await _spawn_fighter()
	var dummy: TrainingDummy = _add_dummy(Vector3(0.0, 0.0, -2.2))
	hero.press(&"dodge")
	await _wait_for_state(&"Roll")
	await _step(5)
	hero.press(&"attack")
	await _wait_until_idle()
	assert_eq(_moves(), [&"rolling_kick"] as Array[StringName])
	assert_eq(dummy.hits_taken, 1)


func test_frappe_juste_apres_la_roulade_donne_encore_le_coup_roule() -> void:
	await _spawn_fighter()
	_add_dummy(Vector3(0.0, 0.0, -2.8))
	hero.press(&"dodge")
	await _wait_for_state(&"Roll")
	await _wait_for_state(&"Ground")
	hero.press(&"attack")
	await _wait_until_idle()
	assert_eq(_moves(), [&"rolling_kick"] as Array[StringName])


func test_le_coup_roule_s_elance_plus_loin() -> void:
	await _spawn_fighter()
	var start: Vector3 = hero.global_position
	hero.press(&"dodge")
	await _wait_for_state(&"Roll")
	await _step(5)
	var before_kick: Vector3 = hero.global_position
	hero.press(&"attack")
	await _wait_until_idle()
	var kick_distance: float = (hero.global_position - before_kick).length()
	assert_almost_eq(kick_distance, tuning.rolling_kick.lunge, TOLERANCE * 2.0)
	assert_gt((hero.global_position - start).length(), tuning.rolling_kick.lunge)


func test_le_plongeon_frappe_autour_du_point_de_chute() -> void:
	await _spawn_fighter()
	var fall: float = _expected_apex(tuning.jump_speed, tuning.gravity_rise_held)
	var radius: float = CombatMath.dive_radius(fall, tuning) + tuning.dummy_radius
	var near: TrainingDummy = _add_dummy(Vector3.LEFT * radius * 0.85)
	var far: TrainingDummy = _add_dummy(Vector3.RIGHT * radius * 1.25)
	hero.input_jump_held = true
	hero.press(&"jump")
	await _step(1)
	while hero.velocity.y > 0.0:
		await _step(1)
	hero.press(&"attack")
	await _wait_for_state(&"Dive")
	await _wait_until_idle()
	assert_eq(near.hits_taken, 1, "mannequin dans l'onde")
	assert_eq(far.hits_taken, 0, "mannequin hors de l'onde")
	assert_eq(_moves(), [&"dive"] as Array[StringName])
	var expected: float = CombatMath.hero_attack(tuning.hero_start_level, tuning) * CombatMath.dive_multiplier(fall, tuning)
	assert_almost_eq(_base_damage(landed[0]), expected, expected * 0.1)


func test_le_mannequin_se_releve() -> void:
	await _spawn_fighter()
	var dummy: TrainingDummy = _add_dummy(Vector3(0.0, 0.0, -1.0))
	var hit := HitData.new()
	hit.damage = tuning.dummy_health * 2.0
	dummy.hurtbox.receive(hit)
	assert_eq(dummy.health.current, tuning.dummy_health)
