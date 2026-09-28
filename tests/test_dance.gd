extends "res://tests/hero_test_base.gd"
## Voie de l'Onde (version 4.1) : quatrième voie de talents ; danses à distance qui dépensent le
## groove (onde de paume, spirale, pluie de pas, fil d'écho) ; visée au pouce ou automatique.

const Hopper: PackedScene = preload("res://scenes/enemies/hopper.tscn")
const TouchScene: PackedScene = preload("res://scenes/ui/touch_controls.tscn")


func after_each() -> void:
	Game.profile.talents.clear()
	Game.refresh_stats()


func after_all() -> void:
	Game.profile = Profile.new()
	Game.refresh_stats()


func _add_muet(at: Vector3) -> Muet:
	var muet: Muet = Hopper.instantiate() as Muet
	muet.position = at
	world.add_child(muet)
	await _step(2)
	muet.set_physics_process(false)
	return muet


## Le héros apprend les figures `ranks` (talent → rang), la jauge de groove pleine.
func _learn(ranks: Dictionary) -> void:
	Game.profile.talents.clear()
	for id: StringName in ranks:
		Game.profile.talents[id] = ranks[id]
	hero.stats = HeroStats.compute(Game.profile, tuning)
	hero.groove.value = tuning.groove_max


func _wait_hurt(muet: Muet) -> bool:
	for i: int in MAX_FRAMES:
		await _step(1)
		if muet.health.current < muet.health.maximum:
			return true
	return false


func test_une_quatrieme_voie_de_quatre_talents() -> void:
	assert_eq(TalentTree.Branch.values().size(), 4)
	var onde: Array[Dictionary] = TalentTree.branch_talents(TalentTree.Branch.ONDE)
	assert_eq(onde.size(), 4)
	assert_eq(onde[0][&"id"], DanceMath.PALM, "on commence par l'onde de paume")
	assert_false(TalentTree.can_buy(DanceMath.SPIRAL, {}, 5), "la spirale demande 2 points dans l'Onde")
	assert_true(TalentTree.can_buy(DanceMath.SPIRAL, {DanceMath.PALM: 2}, 5))
	assert_eq(GameTexts.BRANCH_NAMES[TalentTree.Branch.ONDE], "Onde")
	for t: Dictionary in onde:
		assert_true(GameTexts.TALENT_NAMES.has(t[&"id"]) and GameTexts.TALENT_EFFECTS.has(t[&"id"]))
	assert_string_contains(GameTexts.talent_effect(DanceMath.PALM, 2, tuning), "135 %")


func test_les_figures_s_enchainent_et_coutent_du_groove() -> void:
	var ranks: Dictionary = {DanceMath.PALM: 1}
	assert_true(DanceMath.can_dance(ranks))
	assert_false(DanceMath.can_dance({}))
	assert_eq(DanceMath.figure(0, ranks), DanceMath.PALM)
	assert_eq(DanceMath.figure(1, ranks), DanceMath.PALM, "rien d'autre d'appris : toujours la paume")
	ranks[DanceMath.SPIRAL] = 1
	ranks[DanceMath.RAIN] = 1
	assert_eq([DanceMath.figure(0, ranks), DanceMath.figure(1, ranks), DanceMath.figure(2, ranks), DanceMath.figure(3, ranks)],
		[DanceMath.PALM, DanceMath.SPIRAL, DanceMath.RAIN, DanceMath.PALM])
	assert_gt(DanceMath.cost(DanceMath.RAIN, tuning), DanceMath.cost(DanceMath.PALM, tuning), "la pluie coûte plus que la paume")
	assert_lt(DanceMath.cost(DanceMath.PALM, tuning), tuning.groove_max, "on peut danser plusieurs fois avec une jauge pleine")
	assert_gt(DanceMath.damage(DanceMath.PALM, 3, tuning), DanceMath.damage(DanceMath.PALM, 1, tuning), "chaque rang frappe plus fort")


func test_la_visee_au_pouce_et_la_visee_automatique() -> void:
	assert_eq(DanceMath.aim_direction(Vector2(0.0, -0.5)), Vector3.FORWARD, "le haut de l'écran, c'est devant")
	assert_eq(DanceMath.aim_direction(Vector2.ZERO), Vector3.ZERO)
	assert_almost_eq(DanceMath.rain_distance(Vector2.ZERO, tuning), tuning.dance_rain_min, 0.001)
	assert_almost_eq(DanceMath.rain_distance(Vector2(1.0, 0.0), tuning), tuning.dance_rain_max, 0.001, "plus on glisse, plus elle tombe loin")
	var targets := PackedVector3Array([Vector3(0, 0, 9), Vector3(4, 0, 0), Vector3(30, 0, 0)])
	assert_eq(DanceMath.auto_target(Vector3.ZERO, targets, tuning.dance_range), 1, "la plus proche, même sur le côté")
	assert_eq(DanceMath.auto_target(Vector3.ZERO, PackedVector3Array([Vector3(30, 0, 0)]), tuning.dance_range), -1, "trop loin")
	assert_almost_eq(DanceMath.distance_to_segment(Vector3(1, 0, -3), Vector3.ZERO, Vector3(0, 0, -9)), 1.0, 0.001)
	assert_almost_eq(DanceMath.distance_to_segment(Vector3(0, 0, 4), Vector3.ZERO, Vector3(0, 0, -9)), 4.0, 0.001, "derrière le rayon")


func test_sans_la_voie_de_l_onde_on_ne_danse_pas() -> void:
	await _spawn_on_flat_ground()
	_learn({})
	hero.request_dance(Vector2.ZERO, false)
	await _step(3)
	assert_ne(_state(), &"Dance")


func test_l_onde_de_paume_part_du_bout_des_doigts_et_traverse() -> void:
	await _spawn_on_flat_ground()
	_learn({DanceMath.PALM: 1})
	var near: Muet = await _add_muet(hero.global_position + Vector3(0.0, 0.0, -4.0))
	var far: Muet = await _add_muet(hero.global_position + Vector3(0.0, 0.0, -9.0))
	hero.request_dance(Vector2(0.0, -1.0), true)
	await _step(1)
	assert_eq(_state(), &"Dance", "il danse")
	assert_almost_eq(hero.groove.value, tuning.groove_max - tuning.dance_cost_palm, 0.01, "la danse dépense le groove")
	var groove_after_cost: float = hero.groove.value
	assert_true(await _wait_hurt(near), "l'onde touche la première Sourdine")
	assert_true(await _wait_hurt(far), "et traverse jusqu'à la suivante")
	assert_lte(hero.groove.value, groove_after_cost, "les coups dansés ne rendent pas de groove")


func test_un_toucher_bref_vise_la_sourdine_la_plus_proche() -> void:
	await _spawn_on_flat_ground()
	_learn({DanceMath.PALM: 1})
	hero.face_now(Vector3.FORWARD)
	var behind: Muet = await _add_muet(hero.global_position + Vector3(0.0, 0.0, 5.0))
	hero.request_dance(Vector2.ZERO, false)
	assert_true(await _wait_hurt(behind), "la visée automatique se retourne vers elle")


func test_sans_assez_de_groove_un_pas_manque() -> void:
	await _spawn_on_flat_ground()
	_learn({DanceMath.PALM: 1})
	hero.groove.value = tuning.dance_cost_palm * 0.5
	watch_signals(hero)
	hero.request_dance(Vector2.ZERO, false)
	await _step(3)
	assert_signal_emitted(hero, "dance_fizzled")
	assert_ne(_state(), &"Dance", "rien ne part")
	assert_almost_eq(hero.groove.value, tuning.dance_cost_palm * 0.5, 0.001, "le groove n'est pas dépensé")


func test_la_spirale_puis_la_pluie_de_pas_ou_l_on_vise() -> void:
	await _spawn_on_flat_ground()
	_learn({DanceMath.PALM: 2, DanceMath.SPIRAL: 1, DanceMath.RAIN: 1})
	hero.request_dance(Vector2(0.0, -1.0), true)
	await _wait_for_state(&"Dance")
	assert_eq((hero.state_machine.current as Node).get(&"figure"), DanceMath.PALM)
	await _step(roundi(tuning.dance_release_time * 60.0) + 2)
	hero.request_dance(Vector2(0.0, -1.0), true)
	await _step(2)
	assert_eq((hero.state_machine.current as Node).get(&"figure"), DanceMath.SPIRAL, "la deuxième danse enchaîne la spirale")
	await _step(roundi(tuning.dance_release_time * 60.0) + 2)
	var orbs: int = world.get_children().filter(func(n: Node) -> bool: return n is DanceWave and (n as DanceWave).figure == DanceMath.SPIRAL).size()
	assert_eq(orbs, tuning.dance_spiral_orbs, "trois orbes")
	for wave: Node in world.get_children().filter(func(n: Node) -> bool: return n is DanceWave and (n as DanceWave).figure == DanceMath.SPIRAL):
		assert_lt((wave as Node3D).global_position.distance_to(hero.global_position), 4.0, "les orbes partent du héros")
	var target: Muet = await _add_muet(hero.global_position + Vector3(6.0, 0.0, 0.0))
	hero.request_dance(Vector2(0.4, 0.0), true)
	await _step(2)
	assert_eq((hero.state_machine.current as Node).get(&"figure"), DanceMath.RAIN, "puis la pluie de pas")
	await _step(roundi(tuning.dance_release_time * 60.0) + 2)
	var rains: Array[Node] = world.get_children().filter(func(n: Node) -> bool: return n is DanceRain)
	assert_eq(rains.size(), 1)
	var point: Vector3 = (rains[0] as Node3D).global_position
	assert_almost_eq(point.x - hero.global_position.x, DanceMath.rain_distance(Vector2(0.4, 0.0), tuning), 0.3, "elle tombe là où pointe le pouce")
	assert_true(await _wait_hurt(target), "et frappe la Sourdine qui s'y trouve")


func test_le_fil_d_echo_se_tient_et_boit_le_groove() -> void:
	await _spawn_on_flat_ground()
	_learn({DanceMath.PALM: 3, DanceMath.SPIRAL: 2, DanceMath.RAIN: 1, DanceMath.THREAD: 1})
	hero.face_now(Vector3.FORWARD)
	var muet: Muet = await _add_muet(hero.global_position + Vector3(0.0, 0.0, -5.0))
	hero.thread_held = true
	await _wait_for_state(&"Dance")
	assert_eq((hero.state_machine.current as Node).get(&"figure"), DanceMath.THREAD)
	assert_true(await _wait_hurt(muet), "le rayon frappe ce qu'il traverse")
	var before: float = hero.groove.value
	await _step(10)
	assert_lt(hero.groove.value, before, "il boit le groove")
	hero.thread_held = false
	await _step(2)
	assert_ne(_state(), &"Dance", "on lâche : il s'arrête")
	assert_eq(world.get_children().filter(func(n: Node) -> bool: return n is DanceThread).size(), 0, "le rayon s'éteint")


func test_le_bouton_danse_n_apparait_qu_avec_la_voie_de_l_onde() -> void:
	await _spawn_on_flat_ground()
	hero.reads_player_input = true
	var controls: TouchControls = TouchScene.instantiate() as TouchControls
	add_child_autofree(controls)
	var pad: DancePad = controls.get_node("Buttons/Dance") as DancePad
	_learn({})
	await get_tree().process_frame
	await get_tree().process_frame
	assert_false(pad.visible, "pas de bouton sans la voie")
	_learn({DanceMath.PALM: 1})
	await get_tree().process_frame
	assert_true(pad.visible, "le bouton Danse apparaît")
	# Glisser vers la droite puis relâcher : la danse part vers la droite. (Les touches sont données
	# au bouton directement, en coordonnées du canevas : la fenêtre de test est minuscule.)
	var center: Vector2 = pad.center()
	var down := InputEventScreenTouch.new()
	down.index = 3
	down.pressed = true
	down.position = center
	pad._input(down)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = center + Vector2(tuning.dance_pad_reach_px, 0.0)
	pad._input(drag)
	await get_tree().process_frame
	assert_true(hero.dance_aiming, "on vise")
	assert_true(hero.dance_manual)
	var up := InputEventScreenTouch.new()
	up.index = 3
	up.pressed = false
	up.position = drag.position
	pad._input(up)
	await _step(2)
	assert_eq(_state(), &"Dance")
	assert_gt(hero.facing_direction().x, 0.9, "tourné vers la droite")
	hero.reads_player_input = false
