extends "res://tests/hero_test_base.gd"
## Bestiaire 2.4 : vagues composées, élite de l'expédition, tisserand (ronces), totem chanteur
## (protection), danseur (esquive, vrille), brute (saisie, essoufflement), élites (cuirassé,
## éclatant, rapide), phases du Grand Muet.

const Hopper: PackedScene = preload("res://scenes/enemies/hopper.tscn")
const Weaver: PackedScene = preload("res://scenes/enemies/weaver.tscn")
const Totem: PackedScene = preload("res://scenes/enemies/totem.tscn")
const Dancer: PackedScene = preload("res://scenes/enemies/dancer.tscn")
const Brute: PackedScene = preload("res://scenes/enemies/brute.tscn")
const GrandMuet: PackedScene = preload("res://scenes/enemies/grand_muet.tscn")
const NEW_SPECIES: Array[StringName] = [&"weaver", &"totem", &"dancer", &"brute"]


func _add_muet(scene: PackedScene, at: Vector3, elite: StringName = &"") -> Muet:
	var muet: Muet = scene.instantiate() as Muet
	muet.position = at
	muet.elite = elite
	world.add_child(muet)
	await _step(2)
	return muet


func _hit(target: Muet, damage: float, move: StringName) -> HitData:
	var hit := HitData.new()
	hit.attacker = hero
	hit.damage = damage
	hit.move = move
	var flat: Vector3 = target.global_position - hero.global_position
	flat.y = 0.0
	hit.direction = flat.normalized()
	return hit


func _wait_until(condition: Callable, frames: int = MAX_FRAMES) -> bool:
	for i: int in frames:
		if condition.call():
			return true
		await _step(1)
	return false


func _state_of(muet: Muet) -> StringName:
	return muet.state_machine.current.name


func _act(muet: Muet) -> void:
	muet.act_cooldown = 1
	muet.receive_beat(0)
	await _step(1)


func test_les_vagues_sont_composees_de_roles() -> void:
	assert_eq(WaveComposer.available(0).size(), 1, "la première clairière : la meute")
	assert_gt(WaveComposer.available(4).size(), WaveComposer.available(1).size(), "plus loin, plus de modèles")
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 7
	b.seed = 7
	var wave: Dictionary = WaveComposer.compose(3, 6, a)
	assert_eq(wave, WaveComposer.compose(3, 6, b), "même graine, même vague")
	assert_eq((wave[&"foes"] as Array).size(), 6, "complétée jusqu'au compte")
	for i: int in 20:
		var next: Dictionary = WaveComposer.compose(4, 3, a, wave[&"id"])
		assert_ne(next[&"id"], wave[&"id"], "pas deux fois de suite le même modèle")
		wave = next
	var seen: Dictionary[StringName, bool] = {}
	for template: Dictionary in WaveComposer.TEMPLATES:
		for species: StringName in template[&"foes"]:
			seen[species] = true
	for species: StringName in NEW_SPECIES:
		assert_true(seen.has(species), "%s paraît dans une vague" % species)
	assert_true(WaveComposer.back_row(&"totem"))
	assert_false(WaveComposer.back_row(&"brute"))


func test_l_elite_de_l_expedition_se_tire_de_la_graine() -> void:
	for seed_value: int in [1, 42, 999, 123456]:
		var run := RunState.new(seed_value, 7)
		var room: int = run.elite_room(tuning.elite_first_room)
		assert_between(room, tuning.elite_first_room, 5, "ni la première, ni l'arène")
		assert_true(Muet.ELITES.has(run.elite_affix(Muet.ELITES)))
		assert_eq(room, RunState.new(seed_value, 7).elite_room(tuning.elite_first_room))


func test_chaque_nouvelle_espece_a_son_corps_sa_reponse_et_son_nom() -> void:
	await _spawn_on_flat_ground()
	var scenes: Array[PackedScene] = [Weaver, Totem, Dancer, Brute]
	for i: int in scenes.size():
		var muet: Muet = await _add_muet(scenes[i], Vector3(-6.0 + i * 4.0, 0.0, -12.0))
		assert_eq(muet.species, NEW_SPECIES[i])
		assert_gt(muet.body.height, 0.0)
		assert_gt(muet.poise_max, 0.0, "un équilibre")
		assert_true(tuning.muet_answers.has(muet.species), "une réponse attendue")
		assert_true(GameTexts.SPECIES_NAMES.has(muet.species))
	var totem: Muet = get_tree().get_nodes_in_group(&"muets").filter(func(m: Node) -> bool: return (m as Muet).species == &"totem")[0]
	var hopper: Muet = await _add_muet(Hopper, Vector3(8.0, 0.0, -12.0))
	assert_gt(totem.body.height / tuning.totem_scale, hopper.body.height / tuning.hopper_scale, "le totem est une colonne")


func test_le_tisserand_fait_pousser_des_ronces_sous_le_heros() -> void:
	await _spawn_on_flat_ground()
	var weaver: Muet = await _add_muet(Weaver, Vector3(0.0, 0.0, -3.0))
	await _act(weaver)
	assert_eq(_state_of(weaver), &"Weave")
	var grown: bool = await _wait_until(func() -> bool: return not get_tree().get_nodes_in_group(&"hazards").is_empty())
	assert_true(grown, "les ronces poussent")
	var bramble: BrambleHazard = get_tree().get_nodes_in_group(&"hazards")[0] as BrambleHazard
	assert_true(bramble.covers(hero.global_position), "là où se tenait le héros")
	var hurt: bool = await _wait_until(func() -> bool: return hero.health.current < hero.health.maximum)
	assert_true(hurt, "elles piquent")
	await get_tree().create_timer(tuning.weaver_bramble_time + 0.2).timeout
	assert_eq(get_tree().get_nodes_in_group(&"hazards").size(), 0, "puis elles fanent")


func test_le_totem_chanteur_protege_les_muets_autour() -> void:
	await _spawn_on_flat_ground()
	var totem: Muet = await _add_muet(Totem, Vector3(0.0, 0.0, -6.0))
	var hopper: Muet = await _add_muet(Hopper, Vector3(1.5, 0.0, -6.0))
	var far: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -6.0 - tuning.totem_aura_radius - 3.0))
	hopper.health.current = hopper.health.maximum / 2.0
	totem.hunter = true
	await _act(totem)
	assert_eq(_state_of(totem), &"Sing")
	var sung: bool = await _wait_until(func() -> bool: return hopper.is_warded())
	assert_true(sung, "il chante : le sautillant est protégé")
	assert_false(far.is_warded(), "trop loin")
	assert_gt(hopper.health.current, hopper.health.maximum / 2.0, "un peu soigné")
	var hit: HitData = _hit(hopper, 10.0, &"martelo")
	hopper.hurtbox.receive(hit)
	assert_almost_eq(hit.damage, 10.0 * tuning.totem_ward_multiplier, 0.01, "les coups portent moins")


func test_le_danseur_esquive_puis_contre_d_une_vrille() -> void:
	await _spawn_on_flat_ground()
	var chance: float = tuning.dancer_evade_chance
	tuning.dancer_evade_chance = 1.0
	var dancer: Muet = await _add_muet(Dancer, Vector3(0.0, 0.0, -1.2))
	var before: Vector3 = dancer.global_position
	assert_false(dancer.hurtbox.receive(_hit(dancer, 10.0, &"martelo")), "il esquive")
	assert_eq(dancer.health.current, dancer.health.maximum)
	await _step(roundi(tuning.dancer_evade_time * Engine.physics_ticks_per_second) + 2)
	assert_gt(dancer.global_position.distance_to(before), tuning.dancer_evade_distance * 0.5, "un pas de côté")
	assert_true(dancer.hurtbox.receive(_hit(dancer, 10.0, &"martelo")), "pas deux esquives d'affilée")
	assert_true(dancer.hurtbox.receive(_hit(dancer, 1.0, &"charged")), "le coup chargé ne s'esquive pas")
	tuning.dancer_evade_chance = chance
	dancer.global_position = hero.global_position + Vector3(0.0, 0.0, -1.0)
	await _act(dancer)
	assert_eq(_state_of(dancer), &"Twirl", "il contre d'une vrille")
	var hurt: bool = await _wait_until(func() -> bool: return hero.health.current < hero.health.maximum)
	assert_true(hurt, "la vrille touche qui reste")


func test_la_brute_saisit_jette_puis_reste_essoufflee() -> void:
	await _spawn_on_flat_ground()
	var brute: Muet = await _add_muet(Brute, Vector3(0.0, 0.0, -2.2))
	await _act(brute)
	assert_eq(_state_of(brute), &"Telegraph")
	await _wait_until(func() -> bool: return _state_of(brute) == &"Lunge")
	var caught: bool = await _wait_until(func() -> bool: return hero.health.current < hero.health.maximum)
	assert_true(caught, "pris")
	assert_gt(hero.horizontal_velocity().length(), tuning.hero_recoil_big_speed, "et jeté au loin")
	await _wait_until(func() -> bool: return _state_of(brute) == &"Stunned")
	assert_eq(_state_of(brute), &"Stunned", "essoufflée")
	assert_eq(brute.hurtbox.damage_taken_multiplier, tuning.brute_stunned_damage_multiplier, "et plus fragile")


func test_un_elite_est_plus_fort_et_cuirasse() -> void:
	await _spawn_on_flat_ground()
	var normal: Muet = await _add_muet(Hopper, Vector3(-2.0, 0.0, -8.0))
	var elite: Muet = await _add_muet(Hopper, Vector3(2.0, 0.0, -8.0), Muet.ELITE_ARMORED)
	assert_almost_eq(elite.health.maximum, normal.health.maximum * tuning.elite_health, 1.0)
	assert_gt(elite.poise_max, normal.poise_max)
	assert_gt(elite.body.height, normal.body.height, "plus gros")
	assert_true(elite.is_in_group(&"bosses"), "sa barre, avec son nom")
	assert_eq(elite.display_name, GameTexts.elite_name(&"hopper", Muet.ELITE_ARMORED))
	var hit: HitData = _hit(elite, 10.0, &"martelo")
	elite.hurtbox.receive(hit)
	assert_almost_eq(hit.damage, 10.0 * tuning.elite_armor, 0.01, "cuirassé")
	var swift: Muet = await _add_muet(Hopper, Vector3(6.0, 0.0, -8.0), Muet.ELITE_SWIFT)
	assert_lt(float(swift.stat(&"hop_time")), tuning.hopper_hop_time, "le vif bondit plus vite")


func test_l_elite_eclatant_eclate_en_etant_libere() -> void:
	await _spawn_on_flat_ground()
	var elite: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -1.2), Muet.ELITE_VOLATILE)
	elite.set_physics_process(false)
	var hit: HitData = _hit(elite, elite.health.maximum * 10.0, &"martelo")
	elite.hurtbox.receive(hit)
	assert_true(elite.is_freed())
	assert_eq(hero.health.current, hero.health.maximum, "pas tout de suite : le cercle s'annonce")
	var hurt: bool = await _wait_until(func() -> bool: return hero.health.current < hero.health.maximum)
	assert_true(hurt, "puis il éclate")


func test_le_grand_muet_a_trois_phases() -> void:
	await _spawn_on_flat_ground()
	var boss: Muet = await _add_muet(GrandMuet, Vector3(0.0, 0.0, -8.0))
	assert_eq(boss.phase(), 1)
	boss.hurtbox.receive(_hit(boss, boss.health.maximum * 0.55, &"martelo"))
	assert_eq(boss.phase(), 2, "en rage sous la moitié")
	boss.hurtbox.receive(_hit(boss, boss.health.maximum * 0.25, &"martelo"))
	assert_eq(boss.phase(), 3, "dernière phase sous le quart")
	assert_eq(boss.act_rest_beats(), tuning.boss_act_cooldown_phase3, "il attaque plus souvent")
