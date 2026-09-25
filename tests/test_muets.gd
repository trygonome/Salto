extends "res://tests/hero_test_base.gd"
## Les Muets face au héros : bonds et contact du sautillant, charge et assommage du cornu,
## piqué du volant, frappe et onde du Grand Muet, esquive parfaite, libération.
## Les temps de la musique sont envoyés à la main (receive_beat).

const Hopper: PackedScene = preload("res://scenes/enemies/hopper.tscn")
const Flyer: PackedScene = preload("res://scenes/enemies/flyer.tscn")
const Charger: PackedScene = preload("res://scenes/enemies/charger.tscn")
const GrandMuet: PackedScene = preload("res://scenes/enemies/grand_muet.tscn")


func _add_muet(scene: PackedScene, at: Vector3) -> Muet:
	var muet: Muet = scene.instantiate() as Muet
	muet.position = at
	world.add_child(muet)
	await _step(2)
	return muet


func _muet_state(muet: Muet) -> StringName:
	return muet.state_machine.current.name


func _beats(muet: Muet, count: int) -> void:
	for i: int in count:
		muet.receive_beat(i)
		await _step(1)


func _wait_muet_state(muet: Muet, state_name: StringName) -> void:
	for i: int in MAX_FRAMES:
		if _muet_state(muet) == state_name:
			return
		await _step(1)
	fail_test("le Muet n'est jamais passé dans l'état %s" % state_name)


func _hurt() -> bool:
	return hero.health.current < hero.health.maximum


func test_le_sautillant_bondit_vers_le_heros() -> void:
	await _spawn_on_flat_ground()
	var hopper: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -3.0))
	var before: float = hopper.flat_distance_to(hero.global_position)
	await _beats(hopper, 1)
	await _step(roundi(EnemyMath.hop_duration(tuning.hopper_hop_height, tuning.muet_gravity) * Engine.physics_ticks_per_second) + 4)
	assert_almost_eq(before - hopper.flat_distance_to(hero.global_position), tuning.hopper_hop_distance, 0.08)


func test_le_contact_du_sautillant_blesse_et_rend_intouchable_un_moment() -> void:
	await _spawn_on_flat_ground()
	var hopper: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -0.75))
	hero.combo.register_hit(hero.clock())
	await _beats(hopper, 1)
	await _step(3)
	assert_true(_hurt(), "le héros est touché")
	assert_eq(hero.health.current, hero.health.maximum - tuning.hopper_damage)
	assert_eq(hero.combo.hits, 0, "le combo est perdu")
	assert_eq(_state(), &"Hurt")
	await _beats(hopper, 1)
	await _step(3)
	assert_eq(hero.health.current, hero.health.maximum - tuning.hopper_damage, "invulnérable juste après un coup")


func test_esquive_parfaite_en_roulant_dans_le_coup() -> void:
	await _spawn_on_flat_ground()
	var hopper: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -0.9))
	hero.press(&"dodge")
	await _wait_for_state(&"Roll")
	await _step(3)
	assert_true(hero.invulnerable)
	await _beats(hopper, 1)
	await _step(2)
	assert_false(_hurt(), "la roulade traverse le coup")
	assert_eq(hero.groove.value, tuning.groove_perfect_dodge)
	assert_true(Feedback.is_slowed(), "ralenti")
	var landed: Array[HitData] = []
	hero.hit_landed.connect(func(hit: HitData) -> void: landed.append(hit))
	await _wait_for_state(&"Ground")
	hero.press(&"attack")
	for i: int in MAX_FRAMES:
		if not landed.is_empty():
			break
		await _step(1)
	assert_eq(landed.size(), 1)
	assert_true(landed[0].critical, "le coup suivant est critique")


func test_le_cornu_annonce_puis_charge_en_gros_coup() -> void:
	await _spawn_on_flat_ground()
	var charger: Muet = await _add_muet(Charger, Vector3(0.0, 0.0, -3.0))
	await _beats(charger, tuning.charger_rest_beats)
	assert_eq(_muet_state(charger), &"Telegraph")
	assert_false(_hurt())
	await _wait_muet_state(charger, &"Charge")
	for i: int in MAX_FRAMES:
		if _hurt():
			break
		await _step(1)
	assert_eq(hero.health.current, hero.health.maximum - tuning.charger_damage)
	assert_gt(hero.horizontal_velocity().length(), tuning.hero_recoil_speed, "gros coup : recul plus fort")


func test_le_cornu_s_assomme_contre_un_obstacle_et_devient_fragile() -> void:
	await _spawn_on_flat_ground()
	_add_block(Vector3(4.0, 2.0, 0.4), Vector3(3.0, 1.0, -1.0))
	var charger: Muet = await _add_muet(Charger, Vector3(0.0, 0.0, -1.0))
	hero.global_position = Vector3(3.5, 0.0, -1.0)
	await _beats(charger, tuning.charger_rest_beats)
	await _wait_muet_state(charger, &"Charge")
	await _wait_muet_state(charger, &"Stunned")
	assert_eq(charger.hurtbox.damage_taken_multiplier, tuning.charger_stunned_damage_multiplier)


func test_le_volant_ne_se_touche_pas_depuis_le_sol_mais_en_sautant() -> void:
	await _spawn_on_flat_ground()
	var flyer: Muet = await _add_muet(Flyer, Vector3(0.0, 0.0, -0.6))
	await _step(60)
	assert_gt(flyer.global_position.y, tuning.flyer_altitude * 0.8, "il vole")
	var start: float = flyer.health.current
	hero.global_position = Vector3(flyer.global_position.x, 0.0, flyer.global_position.z + 0.6)
	hero.press(&"attack")
	await _wait_for_state(&"Ground")
	await _step(30)
	assert_eq(flyer.health.current, start, "hors de portée depuis le sol")
	hero.global_position = Vector3(flyer.global_position.x, 0.0, flyer.global_position.z + 0.6)
	hero.input_jump_held = true
	hero.press(&"jump")
	await _step(1)
	while hero.velocity.y > 0.0:
		await _step(1)
	hero.press(&"attack")
	await _step(2)
	assert_lt(flyer.health.current, start, "touché en sautant")


func test_le_volant_annonce_puis_pique_sur_le_heros() -> void:
	await _spawn_on_flat_ground()
	var flyer: Muet = await _add_muet(Flyer, Vector3(0.0, 0.0, -1.5))
	await _step(40)
	await _beats(flyer, tuning.flyer_dive_every_beats)
	assert_eq(_muet_state(flyer), &"Telegraph")
	await _wait_muet_state(flyer, &"Dive")
	for i: int in MAX_FRAMES:
		if _hurt():
			break
		await _step(1)
	assert_eq(hero.health.current, hero.health.maximum - tuning.flyer_damage)


func test_le_grand_muet_frappe_dans_son_cercle() -> void:
	await _spawn_on_flat_ground()
	var boss: Muet = await _add_muet(GrandMuet, Vector3(0.0, 0.0, -tuning.boss_slam_radius * 0.7))
	await _beats(boss, tuning.boss_attack_every_beats)
	assert_eq(_muet_state(boss), &"Telegraph")
	await _wait_muet_state(boss, &"Slam")
	await _step(2)
	assert_eq(hero.health.current, hero.health.maximum - tuning.boss_slam_damage)


func test_hors_du_cercle_la_frappe_ne_touche_pas() -> void:
	await _spawn_on_flat_ground()
	var boss: Muet = await _add_muet(GrandMuet, Vector3(0.0, 0.0, -(tuning.boss_slam_radius + tuning.hero_radius + 0.8)))
	await _beats(boss, tuning.boss_attack_every_beats)
	await _wait_muet_state(boss, &"Slam")
	await _step(3)
	assert_false(_hurt())


func test_en_rage_l_onde_se_saute() -> void:
	await _spawn_on_flat_ground()
	var boss: Muet = await _add_muet(GrandMuet, Vector3(0.0, 0.0, -(tuning.boss_slam_radius + 1.5)))
	boss.health.current = boss.health.maximum * tuning.boss_phase2_fraction
	await _beats(boss, tuning.boss_attack_every_beats)
	await _wait_muet_state(boss, &"Slam")
	# Le front de l'onde arrive sur le héros : il saute juste avant.
	var distance: float = boss.flat_distance_to(hero.global_position)
	var travel_frames: int = floori(distance / tuning.boss_wave_speed * Engine.physics_ticks_per_second)
	await _step(travel_frames - 12)
	hero.input_jump_held = true
	hero.press(&"jump")
	await _step(30)
	assert_false(_hurt(), "l'onde passe sous le héros")
	assert_eq(hero.groove.value, tuning.groove_wave_jumped)


func test_en_rage_l_onde_touche_qui_reste_au_sol() -> void:
	await _spawn_on_flat_ground()
	var boss: Muet = await _add_muet(GrandMuet, Vector3(0.0, 0.0, -(tuning.boss_slam_radius + 1.5)))
	boss.health.current = boss.health.maximum * tuning.boss_phase2_fraction
	await _beats(boss, tuning.boss_attack_every_beats)
	await _wait_muet_state(boss, &"Slam")
	await _step(roundi(tuning.boss_wave_range / tuning.boss_wave_speed * Engine.physics_ticks_per_second))
	assert_eq(hero.health.current, hero.health.maximum - tuning.boss_wave_damage)


func test_un_muet_a_zero_pv_est_libere() -> void:
	await _spawn_on_flat_ground()
	var hopper: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -1.0))
	var hit := HitData.new()
	hit.damage = tuning.hopper_health
	hit.direction = Vector3.FORWARD
	hopper.hurtbox.receive(hit)
	await _step(1)
	assert_eq(_muet_state(hopper), &"Freed")
	assert_eq(hero.groove.value, tuning.groove_enemy_freed)
	await _step(roundi(tuning.muet_freed_time * Engine.physics_ticks_per_second) + 5)
	assert_false(is_instance_valid(hopper), "il disparaît")


func test_a_zero_pv_le_heros_revient_au_depart() -> void:
	await _spawn_on_flat_ground()
	hero.global_position = Vector3(2.0, 0.0, 2.0)
	var hit := HitData.new()
	hit.damage = hero.health.maximum
	hit.direction = Vector3.FORWARD
	hero.hurtbox.receive(hit)
	assert_eq(hero.health.current, hero.health.maximum)
	assert_almost_eq(hero.global_position, Vector3.ZERO, Vector3.ONE * TOLERANCE)
