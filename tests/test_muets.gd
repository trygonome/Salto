extends "res://tests/hero_test_base.gd"
## Les Muets face au héros : bonds et contact du sautillant, charge et assommage du cornu,
## piqué du volant, frappe et onde du Grand Muet, bouclier, crachat, esquive parfaite,
## libération. Les temps de la musique sont envoyés à la main (receive_beat).

const Hopper: PackedScene = preload("res://scenes/enemies/hopper.tscn")
const Flyer: PackedScene = preload("res://scenes/enemies/flyer.tscn")
const Charger: PackedScene = preload("res://scenes/enemies/charger.tscn")
const GrandMuet: PackedScene = preload("res://scenes/enemies/grand_muet.tscn")
const Shielder: PackedScene = preload("res://scenes/enemies/shielder.tscn")
const Spitter: PackedScene = preload("res://scenes/enemies/spitter.tscn")


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


## Attaque prête : le prochain temps la lance si le héros est à portée.
func _ready_to_act(muet: Muet, beat_index: int = 0) -> void:
	muet.act_cooldown = 1
	await _beats_from(muet, beat_index, 1)


func _beats_from(muet: Muet, first: int, count: int) -> void:
	for i: int in count:
		muet.receive_beat(first + i)
		await _step(1)


func _wait_hurt() -> void:
	for i: int in MAX_FRAMES:
		if _hurt():
			return
		await _step(1)


func _hit_from_hero(damage: float, move: StringName, target: Muet) -> HitData:
	var hit := HitData.new()
	hit.attacker = hero
	hit.damage = damage
	hit.move = move
	var flat: Vector3 = target.global_position - hero.global_position
	flat.y = 0.0
	hit.direction = flat.normalized()
	return hit


func test_le_sautillant_bondit_vers_le_heros() -> void:
	await _spawn_on_flat_ground()
	var hopper: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -2.5))
	var before: float = hopper.flat_distance_to(hero.global_position)
	await _beats(hopper, 1)
	await _step(roundi(tuning.hopper_hop_time * Engine.physics_ticks_per_second) + 4)
	assert_almost_eq(before - hopper.flat_distance_to(hero.global_position), tuning.hopper_hop_distance, 0.05)
	assert_almost_eq(hopper.global_position.y, 0.0, 0.05, "retombé au sol")


func test_loin_du_heros_il_revient_vers_son_poste() -> void:
	await _spawn_on_flat_ground()
	hero.global_position = Vector3(20.0, 0.0, 20.0)
	var hopper: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -3.0))
	hopper.global_position = hopper.post + Vector3(tuning.muet_leash_guard, 0.0, 0.0)
	var before: float = hopper.flat_distance_to(hopper.post)
	await _beats(hopper, 1)
	await _step(roundi(tuning.hopper_hop_time * Engine.physics_ticks_per_second) + 4)
	assert_almost_eq(before - hopper.flat_distance_to(hopper.post), tuning.hopper_hop_distance, 0.05)


func test_le_contact_du_sautillant_blesse_et_rend_intouchable_un_moment() -> void:
	await _spawn_on_flat_ground()
	hero.combo.register_hit(hero.clock())
	var hopper: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -0.6))
	await _step(2)
	assert_true(_hurt(), "le héros est touché au contact")
	assert_eq(hero.health.current, hero.health.maximum - tuning.hopper_damage)
	assert_eq(hero.combo.hits, 0, "le combo est perdu")
	assert_eq(_state(), &"Hurt")
	hopper.global_position = hero.global_position + Vector3(0.0, 0.0, -0.5)
	await _step(3)
	assert_eq(hero.health.current, hero.health.maximum - tuning.hopper_damage, "intouchable juste après un coup")


func test_le_heros_qui_passe_au_dessus_n_est_pas_touche() -> void:
	await _spawn_on_flat_ground()
	var hopper: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -3.0))
	hero.global_position = hopper.global_position + Vector3.UP * hopper.body.height
	hero.reset_physics_interpolation()
	await _step(2)
	assert_false(_hurt(), "les pieds au-dessus de sa tête")


func test_esquive_parfaite_en_roulant_dans_le_coup() -> void:
	await _spawn_on_flat_ground()
	var hopper: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -2.0))
	hero.press(&"dodge")
	await _wait_for_state(&"Roll")
	await _step(3)
	assert_true(hero.invulnerable)
	hopper.global_position = hero.global_position + Vector3(0.0, 0.0, -0.5)
	await _step(2)
	assert_false(_hurt(), "la roulade traverse le coup")
	assert_eq(hero.groove.value, tuning.groove_perfect_dodge)
	assert_true(Feedback.is_slowed(), "ralenti")
	var landed: Array[HitData] = []
	hero.hit_landed.connect(func(hit: HitData) -> void: landed.append(hit))
	hopper.queue_free()
	var target: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -3.0))
	await _wait_for_state(&"Ground")
	target.global_position = hero.global_position + hero.facing_direction() * 1.0
	target.set_physics_process(false)
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
	await _ready_to_act(charger)
	assert_eq(_muet_state(charger), &"Telegraph")
	assert_false(_hurt())
	await _wait_muet_state(charger, &"Charge")
	await _wait_hurt()
	assert_eq(hero.health.current, hero.health.maximum - tuning.charger_damage)
	assert_gt(hero.horizontal_velocity().length(), tuning.hero_recoil_speed, "gros coup : recul plus fort")


func test_un_coup_fait_renoncer_le_cornu_a_sa_charge() -> void:
	await _spawn_on_flat_ground()
	var charger: Muet = await _add_muet(Charger, Vector3(0.0, 0.0, -3.0))
	await _ready_to_act(charger)
	assert_eq(_muet_state(charger), &"Telegraph")
	charger.hurtbox.receive(_hit_from_hero(1.0, &"martelo", charger))
	await _step(1)
	assert_eq(_muet_state(charger), &"Hop", "il renonce")
	assert_eq(get_tree().get_nodes_in_group(&"telegraphs").size(), 0, "l'annonce disparaît")


func test_le_cornu_s_assomme_contre_un_obstacle_et_devient_fragile() -> void:
	await _spawn_on_flat_ground()
	_add_block(Vector3(4.0, 2.0, 0.4), Vector3(3.0, 1.0, -1.0))
	var charger: Muet = await _add_muet(Charger, Vector3(0.0, 0.0, -1.0))
	hero.global_position = Vector3(3.5, 0.0, -1.0)
	await _ready_to_act(charger)
	await _wait_muet_state(charger, &"Charge")
	await _wait_muet_state(charger, &"Stunned")
	assert_eq(charger.hurtbox.damage_taken_multiplier, tuning.charger_stunned_damage_multiplier)


func test_le_volant_ne_se_touche_pas_depuis_le_sol_mais_en_sautant() -> void:
	await _spawn_on_flat_ground()
	var flyer: Muet = await _add_muet(Flyer, Vector3(0.0, 0.0, -0.6))
	await _step(60)
	assert_gt(flyer.global_position.y, tuning.flyer_altitude * 0.8, "il vole")
	# Il reste en place : on ne teste que la hauteur.
	flyer.set_physics_process(false)
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
	await _ready_to_act(flyer)
	assert_eq(_muet_state(flyer), &"Telegraph")
	await _wait_muet_state(flyer, &"Dive")
	await _wait_hurt()
	assert_eq(hero.health.current, hero.health.maximum - tuning.flyer_damage)


func test_le_grand_muet_frappe_dans_son_cercle() -> void:
	await _spawn_on_flat_ground()
	var boss: Muet = await _add_muet(GrandMuet, Vector3(0.0, 0.0, -tuning.boss_slam_radius * 0.7))
	await _ready_to_act(boss)
	assert_eq(_muet_state(boss), &"Telegraph")
	await _wait_muet_state(boss, &"Slam")
	await _step(2)
	assert_eq(hero.health.current, hero.health.maximum - tuning.boss_slam_damage)


func test_hors_du_cercle_la_frappe_ne_touche_pas() -> void:
	await _spawn_on_flat_ground()
	var boss: Muet = await _add_muet(GrandMuet, Vector3(0.0, 0.0, -(tuning.boss_slam_radius + tuning.hero_radius + 0.8)))
	await _ready_to_act(boss)
	await _wait_muet_state(boss, &"Slam")
	await _step(3)
	assert_false(_hurt())


func test_un_coup_ne_fait_pas_renoncer_le_grand_muet() -> void:
	await _spawn_on_flat_ground()
	var boss: Muet = await _add_muet(GrandMuet, Vector3(0.0, 0.0, -tuning.boss_slam_radius * 0.7))
	await _ready_to_act(boss)
	boss.hurtbox.receive(_hit_from_hero(1.0, &"martelo", boss))
	await _step(1)
	assert_eq(_muet_state(boss), &"Telegraph")


func test_sous_la_moitie_de_ses_pv_il_enrage() -> void:
	await _spawn_on_flat_ground()
	var boss: Muet = await _add_muet(GrandMuet, Vector3(0.0, 0.0, -3.0))
	boss.hurtbox.receive(_hit_from_hero(boss.health.maximum * (1.0 - tuning.boss_phase2_fraction), &"martelo", boss))
	assert_true(boss.enraged)
	assert_eq(boss.act_cooldown, 1, "il frappe au temps suivant")
	assert_eq(boss.act_rest_beats(), tuning.boss_act_cooldown_enraged)


func test_en_rage_l_onde_se_saute() -> void:
	await _spawn_on_flat_ground()
	var boss: Muet = await _add_muet(GrandMuet, Vector3(0.0, 0.0, -(tuning.boss_slam_radius + 1.5)))
	boss.enraged = true
	await _ready_to_act(boss)
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
	boss.enraged = true
	await _ready_to_act(boss)
	await _wait_muet_state(boss, &"Slam")
	await _step(roundi(tuning.boss_wave_range / tuning.boss_wave_speed * Engine.physics_ticks_per_second))
	assert_almost_eq(hero.health.current, hero.health.maximum - tuning.boss_damage * tuning.boss_wave_damage_factor, 0.01)


func test_le_bouclier_arrete_les_coups_de_face() -> void:
	await _spawn_on_flat_ground()
	var shielder: Muet = await _add_muet(Shielder, Vector3(0.0, 0.0, -1.2))
	shielder.set_physics_process(false)
	shielder.body.target_yaw = EnemyMath.yaw_of(Vector3.BACK)
	shielder.body.rotation.y = shielder.body.target_yaw
	var blocked: bool = not shielder.hurtbox.receive(_hit_from_hero(10.0, &"martelo", shielder))
	assert_true(blocked, "de face : bloqué")
	assert_eq(shielder.health.current, shielder.health.maximum)
	assert_gt(hero.horizontal_velocity().z, 0.0, "le héros est repoussé")
	shielder.body.rotation.y = PI
	assert_true(shielder.hurtbox.receive(_hit_from_hero(10.0, &"martelo", shielder)), "de dos : touché")


func test_un_plongeon_passe_par_dessus_le_bouclier_et_l_etourdit() -> void:
	await _spawn_on_flat_ground()
	var shielder: Muet = await _add_muet(Shielder, Vector3(0.0, 0.0, -1.2))
	shielder.body.rotation.y = EnemyMath.yaw_of(Vector3.BACK)
	assert_true(shielder.hurtbox.receive(_hit_from_hero(10.0, &"dive", shielder)))
	assert_eq(_muet_state(shielder), &"Stunned")


func test_le_porte_bouclier_donne_un_coup_de_bouclier() -> void:
	await _spawn_on_flat_ground()
	var shielder: Muet = await _add_muet(Shielder, Vector3(0.0, 0.0, -1.0))
	await _ready_to_act(shielder)
	assert_eq(_muet_state(shielder), &"Prepare")
	await _wait_muet_state(shielder, &"Bash")
	await _wait_hurt()
	assert_true(_hurt())


func test_le_cracheur_crache_une_bulle_qui_blesse() -> void:
	await _spawn_on_flat_ground()
	var spitter: Muet = await _add_muet(Spitter, Vector3(0.0, 0.0, -2.5))
	spitter.set_physics_process(false)
	spitter.act_cooldown = 1
	spitter.update_target()
	spitter.receive_beat(0)
	assert_eq(_muet_state(spitter), &"Prepare")
	spitter.set_physics_process(true)
	for i: int in MAX_FRAMES:
		if not get_tree().get_nodes_in_group(&"silence_orbs").is_empty():
			break
		await _step(1)
	assert_eq(get_tree().get_nodes_in_group(&"silence_orbs").size(), 1, "une bulle part")
	spitter.set_physics_process(false)
	await _wait_hurt()
	assert_eq(hero.health.current, hero.health.maximum - tuning.spitter_damage)
	await _step(1)
	assert_eq(get_tree().get_nodes_in_group(&"silence_orbs").size(), 0, "la bulle éclate")


func test_plus_loin_du_village_les_muets_sont_plus_forts() -> void:
	await _spawn_on_flat_ground()
	var hopper: Muet = Hopper.instantiate() as Muet
	hopper.tier = 2
	hopper.position = Vector3(0.0, 0.0, -3.0)
	world.add_child(hopper)
	await _step(1)
	assert_eq(hopper.health.maximum, tuning.hopper_health + 2.0 * tuning.muet_health_per_tier)
	assert_eq(hopper.damage_of(&"damage"), tuning.hopper_damage + 2.0 * tuning.muet_damage_per_tier)


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
