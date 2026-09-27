extends GutTest
## Expédition : clairières générées, vagues de Muets chasseurs, récompense de la clairière (don des
## esprits, soin, plumes d'or), passages qui annoncent la leur, Grand Muet de la dernière
## clairière, fin et résumé ; dons des esprits et forces du héros.

const LevelScene: PackedScene = preload("res://scenes/levels/expedition.tscn")

var tuning: TuningData = Tuning.data
var level: Expedition
var hero: Hero


func before_each() -> void:
	Save.path = "user://test_expedition.json"
	Game.profile = Profile.create()
	Game.start_on_load = false
	Game.run = null


func after_each() -> void:
	get_tree().paused = false
	Game.run = null
	Game.playing = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.path))


func after_all() -> void:
	Game.profile = Profile.new()
	Game.refresh_stats()


func test_une_expedition_se_tire_de_sa_graine() -> void:
	var a := RunState.new(42, 7)
	var b := RunState.new(42, 7)
	assert_eq(a.exit_rewards(2), b.exit_rewards(2), "même graine, mêmes passages")
	assert_eq(a.room_seed(), b.room_seed())
	a.enter_next(RunState.HEAL)
	assert_ne(a.room_seed(), b.room_seed(), "chaque clairière a sa graine")
	assert_eq(a.reward, RunState.HEAL)
	var rewards: Array[StringName] = a.exit_rewards(2)
	assert_eq(rewards.size(), 2)
	assert_ne(rewards[0], rewards[1], "deux passages, deux récompenses")
	a.room = 5
	assert_eq(a.exit_count(2), 1, "un seul passage vers le Grand Muet")
	assert_eq(a.exit_rewards(2), [RunState.BOSS] as Array[StringName])
	a.room = 6
	assert_true(a.is_boss_room())


func test_les_dons_se_prennent_et_montent_de_rang() -> void:
	var run := RunState.new(1, 7)
	run.take_boon(&"ember")
	run.take_boon(&"ember")
	run.take_boon(&"heart")
	assert_eq(Boons.rank(run.boons, &"ember"), 2)
	assert_eq(run.boon_ranks(), 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var maxed: Dictionary[StringName, int] = {}
	for id: StringName in Boons.IDS:
		maxed[id] = tuning.boon_max_rank
	maxed.erase(&"sap")
	assert_eq(Boons.offer(rng, maxed, 3, tuning), [&"sap"] as Array[StringName], "seulement les dons pas au rang maximal")
	var offer: Array[StringName] = Boons.offer(rng, {} as Dictionary[StringName, int], 3, tuning)
	assert_eq(offer.size(), 3)
	assert_ne(offer[0], offer[1])
	assert_ne(offer[1], offer[2])
	for id: StringName in Boons.IDS:
		assert_true(GameTexts.BOON_NAMES.has(id) and GameTexts.BOON_TEXTS.has(id), String(id))
		assert_false(GameTexts.boon_text(id, 1, tuning).contains("%d"))


func test_les_dons_changent_les_forces_du_heros() -> void:
	var profile := Profile.new()
	var base: HeroStats = HeroStats.compute(profile, tuning)
	var boons: Dictionary[StringName, int] = {&"heart": 2, &"fury": 1, &"echo": 1, &"ember": 1, &"thorns": 1}
	var stats: HeroStats = HeroStats.compute(profile, tuning, boons)
	assert_eq(stats.max_health, base.max_health + 2.0 * tuning.boon_values[&"heart"])
	assert_almost_eq(stats.attack, base.attack * (1.0 + tuning.boon_values[&"fury"]), 0.001)
	assert_true(stats.finale, "l'écho du tambour : le 3e coup libère une onde")
	assert_gt(stats.burn, 0.0)
	assert_gt(stats.roll_damage, 0.0)


func test_une_clairiere_garde_ses_passages_degages() -> void:
	var gen := WorldGen.new()
	var gaps := PackedFloat32Array([-0.28, 0.28, PI])
	gen.generate_room(99, tuning.room_radius, gaps)
	assert_eq(gen.border_radius, tuning.room_radius + WorldGen.ROOM_WALL_BEHIND)
	assert_gt(gen.voxel_count(), 0)
	for gap: float in gaps:
		var door: Vector2 = WorldGen.gap_point(gap, tuning.room_radius)
		for s: WorldGen.Solid in gen.solids:
			assert_gt(WorldGen.segment_distance(Vector2(s.x, s.z), Vector2.ZERO, door), s.r, "rien sur le chemin du passage")


func test_le_bord_d_une_clairiere_est_un_mur_d_arbres_visible() -> void:
	var hero_width: float = 2.0 * tuning.hero_radius / tuning.voxel_unit
	for kind: StringName in WorldGen.ROOM_KINDS + [&"arena"] as Array[StringName]:
		var gen := WorldGen.new()
		var radius: float = tuning.room_radius_max
		var gaps := PackedFloat32Array([-0.28, 0.28, PI])
		gen.generate_room(7, radius, gaps, kind)
		var row: float = radius + WorldGen.ROOM_RING_GAP + WorldGen.ROOM_RING_JITTER
		assert_gt(gen.border_radius, row, "le mur invisible est derrière la rangée d'arbres (%s)" % kind)
		assert_lt(gen.border_radius - row, hero_width, "juste derrière : on voit où la clairière s'arrête")
		var a: float = 0.0
		while a < TAU:
			a += 0.05
			var near_gap: bool = false
			for gap: float in gaps:
				near_gap = near_gap or absf(angle_difference(a, gap)) < WorldGen.ROOM_GAP_ANGLE * 2.0
			if near_gap:
				continue
			# Entre deux arbres ou buissons voisins du bord, pas de trou où passer.
			var p: Vector2 = WorldGen.gap_point(a, radius + WorldGen.ROOM_RING_GAP + WorldGen.ROOM_RING_JITTER / 2.0)
			var nearest: float = INF
			for s: WorldGen.Solid in gen.solids:
				nearest = minf(nearest, p.distance_to(Vector2(s.x, s.z)) - s.r)
			assert_lt(nearest, WorldGen.ROOM_TREE_SPACING / 2.0, "un arbre ou un buisson à %.2f rad (%s)" % [a, kind])


func test_chaque_clairiere_a_sa_forme_et_sa_taille() -> void:
	var run := RunState.new(42, 30)
	var again := RunState.new(42, 30)
	var kinds: Dictionary[StringName, bool] = {}
	for room: int in run.room_count - 1:
		run.room = room
		again.room = room
		assert_eq(run.room_kind(), again.room_kind(), "même graine, même forme")
		assert_true(WorldGen.ROOM_KINDS.has(run.room_kind()))
		kinds[run.room_kind()] = true
		var radius: float = run.room_radius(tuning.room_radius_min, tuning.room_radius_max)
		assert_between(radius, tuning.room_radius_min, tuning.room_radius_max)
		assert_eq(radius, again.room_radius(tuning.room_radius_min, tuning.room_radius_max))
		var names: PackedStringArray = GameTexts.room_names(run.room_kind())
		assert_between(run.name_index(names.size()), 0, names.size() - 1)
	assert_gt(kinds.size(), 2, "des clairières variées")
	run.reward = RunState.ENCOUNTER
	run.room = 2
	assert_eq(run.room_kind(), &"clearing", "une rencontre se fait dans une clairière calme")
	run.room = run.room_count - 1
	assert_eq(run.room_kind(), &"arena", "l'arène du Grand Muet")
	for kind: StringName in WorldGen.ROOM_KINDS:
		assert_true(GameTexts.ROOM_NAMES.has(kind), String(kind))
	var gen := WorldGen.new()
	gen.generate_room(3, tuning.room_radius, PackedFloat32Array([0.0]), &"mushrooms")
	assert_eq(gen.pickups.size(), 1, "une plume arc-en-ciel sur le grand champignon")


func test_les_rencontres_ne_se_repetent_pas() -> void:
	var run := RunState.new(5, 7)
	var seen: Dictionary[StringName, bool] = {}
	for i: int in Encounters.IDS.size():
		seen[run.pick_encounter(Encounters.IDS)] = true
	assert_eq(seen.size(), Encounters.IDS.size(), "chacune une fois")
	assert_true(Encounters.IDS.has(run.pick_encounter(Encounters.IDS)), "puis elles peuvent revenir")
	assert_false(Encounters.can_choose(&"merchant", 0, tuning.encounter_merchant_price - 1, tuning), "le marchand veut ses plumes")
	assert_true(Encounters.can_choose(&"merchant", 0, tuning.encounter_merchant_price, tuning))
	assert_true(Encounters.can_choose(&"merchant", 1, 0, tuning))
	for id: StringName in Encounters.IDS:
		assert_true(GameTexts.ENCOUNTER_NAMES.has(id) and GameTexts.ENCOUNTER_TEXTS.has(id), String(id))
		for i: int in 2:
			var choice: String = GameTexts.encounter_choice(id, i, 12)
			assert_true(choice.contains(BoonScreen.CHOICE_SPLIT), "« action : effet » (%s)" % choice)
			assert_false(choice.contains("%d"), choice)


func _open_level() -> void:
	level = LevelScene.instantiate() as Expedition
	hero = level.get_node("Hero") as Hero
	add_child_autofree(level)
	await get_tree().process_frame
	await get_tree().physics_frame


func _muets() -> Array[Muet]:
	var list: Array[Muet] = []
	for node: Node in get_tree().get_nodes_in_group(&"muets"):
		if not (node as Muet).is_freed():
			list.append(node as Muet)
	return list


func _wait_muets() -> void:
	for i: int in 200:
		await get_tree().physics_frame
		if not _muets().is_empty():
			return


func _free_all() -> void:
	for muet: Muet in _muets():
		var hit := HitData.new()
		hit.damage = muet.health.maximum * 10.0
		hit.direction = Vector3.FORWARD
		# (Le coup chargé passe les boucliers et ne s'esquive pas.)
		hit.move = &"charged"
		muet.hurtbox.receive(hit)
	for i: int in 3:
		await get_tree().physics_frame


func test_l_ecran_titre_s_ouvre_sur_le_camp() -> void:
	await _open_level()
	assert_false(level.in_sortie)
	assert_true(level.get_node("TitleScreen").is_open())
	assert_eq(_muets().size(), 0, "le camp est calme")


func test_une_clairiere_nettoyee_donne_son_don_puis_ouvre_ses_passages() -> void:
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	assert_eq(Game.run.room, 0)
	assert_eq(Game.run.reward, RunState.BOON, "la première clairière promet un don")
	assert_eq(level.current_goal()[&"icon"], RunState.BOON)
	for wave: int in tuning.room_waves:
		await _wait_muets()
		assert_eq(_muets().size(), tuning.room_wave_base, "vague %d" % wave)
		for muet: Muet in _muets():
			assert_true(muet.hunter, "ils poursuivent le héros")
		await _free_all()
	var screen: BoonScreen = level.get_node("BoonScreen") as BoonScreen
	assert_true(screen.is_open(), "un don des esprits à choisir")
	assert_true(get_tree().paused)
	var cards: Array[Node] = screen.get_node("%Cards").get_children()
	assert_eq(cards.size(), tuning.boon_offer)
	var before: float = hero.health.maximum
	(cards[0] as Button).pressed.emit()
	assert_false(get_tree().paused)
	assert_eq(Game.run.boon_ranks(), 1)
	assert_true(before <= hero.health.maximum)
	await get_tree().process_frame
	var gates: Array[Node] = level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n is ExitGate)
	assert_eq(gates.size(), tuning.room_exits, "deux passages")
	var gate: ExitGate = gates[0] as ExitGate
	var promised: StringName = gate.reward
	gate.chosen.emit(promised)
	await get_tree().create_timer(tuning.room_fade_time * 3.0).timeout
	assert_eq(Game.run.room, 1, "la clairière suivante")
	assert_eq(Game.run.reward, promised, "elle promet ce que le passage annonçait")


func test_le_grand_muet_libere_termine_l_expedition() -> void:
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	Game.run.room = Game.run.room_count - 1
	level.call(&"_enter_room")
	await _wait_muets()
	var bosses: Array[Muet] = _muets().filter(func(m: Muet) -> bool: return m.is_boss())
	assert_eq(bosses.size(), 1, "le Grand Muet garde la dernière clairière")
	await _free_all()
	await get_tree().create_timer(tuning.night_summary_delay + 0.3).timeout
	assert_false(level.in_sortie)
	var summary: SummaryScreen = level.get_node("SummaryScreen") as SummaryScreen
	assert_true(summary.is_open())
	assert_eq((summary.get_node("%Title") as Label).text, GameTexts.RUN_WON)
	assert_eq(Game.profile.runs_won, 1)
	assert_eq(Game.profile.best_room, tuning.run_rooms)


func test_tomber_termine_l_expedition_et_garde_les_plumes() -> void:
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	Game.run.feathers = 30
	level.end_sortie(&"faint")
	assert_eq(Game.profile.feathers, 30, "les plumes d'or rapportées restent")
	assert_null(Game.run)
	var summary: SummaryScreen = level.get_node("SummaryScreen") as SummaryScreen
	assert_eq((summary.get_node("%Title") as Label).text, GameTexts.RUN_LOST)
	assert_eq((summary.get_node("%Again") as Button).text, GameTexts.RUN_AGAIN)


## Rencontre (la source, seule qui reste) : pas de Muets, le repère mène au centre, les choix
## s'ouvrent près du personnage, et après le choix, les passages.
func test_une_rencontre_se_parle_puis_ouvre_les_passages() -> void:
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	Game.run.reward = RunState.ENCOUNTER
	Game.run.encounters_seen.assign([&"merchant", &"drummer", &"wounded"])
	level.call(&"_enter_room")
	for i: int in 30:
		await get_tree().physics_frame
	assert_eq(_muets().size(), 0, "pas de combat")
	var goal: Dictionary = level.current_goal()
	assert_eq(goal[&"icon"], RunState.ENCOUNTER)
	assert_eq(goal[&"title"], GameTexts.ENCOUNTER_NAMES[&"spring"])
	assert_eq(goal[&"point"], Vector3.ZERO, "le repère mène au personnage")
	var screen: BoonScreen = level.get_node("BoonScreen") as BoonScreen
	assert_false(screen.is_open(), "loin du personnage, rien ne s'ouvre")
	hero.health.current = 1.0
	hero.global_position = Vector3(0.0, 0.0, tuning.encounter_radius / 2.0)
	for i: int in 3:
		await get_tree().process_frame
	assert_true(screen.is_open(), "on s'approche : la source parle")
	var cards: Array[Node] = screen.get_node("%Cards").get_children()
	assert_eq(cards.size(), 2)
	(cards[0] as Button).pressed.emit()
	assert_eq(hero.health.current, hero.health.maximum, "boire : tous les PV")
	await get_tree().process_frame
	var gates: Array[Node] = level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n is ExitGate)
	assert_eq(gates.size(), tuning.room_exits, "les passages s'ouvrent")


func test_la_troupe_chante_quand_le_combo_tient() -> void:
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(Rhythm.band_amount(), 0.0, "sans combo, elle se tait")
	hero.combo.hits = tuning.combo_band_full
	await get_tree().process_frame
	await get_tree().process_frame
	assert_almost_eq(Rhythm.band_amount(), tuning.combo_band_max, 0.001, "le combo tient : elle chante")


func test_un_elite_libere_offre_son_don_apres_la_recompense() -> void:
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	await _wait_muets()
	var first: Muet = _muets()[0]
	first.elite = Muet.ELITE_GOLDEN
	var feathers: int = Game.run.feathers
	level.on_elite_freed(first)
	assert_eq(Game.run.feathers, feathers + tuning.elite_golden_feathers, "l'élite doré laisse des plumes d'or")
	for wave: int in tuning.room_waves:
		await _wait_muets()
		await _free_all()
	var screen: BoonScreen = level.get_node("BoonScreen") as BoonScreen
	assert_true(screen.is_open(), "le don de la clairière")
	(screen.get_node("%Cards").get_child(0) as Button).pressed.emit()
	assert_true(screen.is_open(), "puis celui de l'élite")
	assert_eq((screen.get_node("%Title") as Label).text, GameTexts.ELITE_BOON_TITLE)
	(screen.get_node("%Cards").get_child(0) as Button).pressed.emit()
	assert_eq(Game.run.boon_ranks(), 2)
	await get_tree().process_frame
	var gates: Array[Node] = level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n is ExitGate)
	assert_eq(gates.size(), tuning.room_exits, "puis les passages")


func test_un_elite_appelant_fait_venir_des_renforts() -> void:
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	await _wait_muets()
	var before: int = _muets().size()
	level.call_help(_muets()[0], tuning.elite_call_count)
	for i: int in 10:
		await get_tree().physics_frame
	assert_eq(_muets().size(), before + tuning.elite_call_count)


func test_les_clairieres_sont_vivantes_sans_depasser_le_budget() -> void:
	for kind: StringName in WorldGen.ROOM_KINDS + [&"arena"] as Array[StringName]:
		var gen := WorldGen.new()
		gen.generate_room(11, tuning.room_radius_max, PackedFloat32Array([-0.28, 0.28, PI]), kind)
		assert_lt(gen.voxel_count(), 20000, "assez peu de cubes pour le téléphone (%s)" % kind)
	var clearing := WorldGen.new()
	clearing.generate_room(11, tuning.room_radius_max, PackedFloat32Array([0.0, PI]), &"clearing")
	assert_eq(clearing.ponds.size(), 3, "une mare dans la clairière")
	var pond := Vector2(clearing.ponds[0], clearing.ponds[1])
	for gap: float in [0.0, PI]:
		assert_gt(WorldGen.segment_distance(pond, Vector2.ZERO, WorldGen.gap_point(gap, tuning.room_radius_max)), clearing.ponds[2], "pas sur le chemin d'un passage")


func test_un_long_titre_d_ecran_ne_se_coupe_pas_au_milieu_d_un_mot() -> void:
	await _open_level()
	var screen: BoonScreen = level.get_node("BoonScreen") as BoonScreen
	screen.open_choices("Le vieux tambourinaire", "…", PackedStringArray(["A : b", "C : d"]), [true, true] as Array[bool])
	assert_eq((screen.get_node("%Title") as Label).theme_type_variation, &"ScreenTitleSmall")
	screen.hide_screen()
	get_tree().paused = false


## Donjons 2.6 : le feu de camp (repos) soigne ou affûte un don déjà pris.
func test_le_feu_de_camp_soigne_ou_affute_un_don() -> void:
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	Game.run.room = 1
	Game.run.reward = RunState.REST
	level.call(&"_enter_room")
	await get_tree().process_frame
	assert_eq(level.current_goal()[&"icon"], RunState.REST)
	assert_true(level.get_node("Pickups").find_child("Flames", true, false) != null, "un feu de camp")
	hero.health.current = 1.0
	hero.global_position = Vector3(0.0, 0.0, tuning.encounter_radius / 2.0)
	for i: int in 3:
		await get_tree().process_frame
	var screen: BoonScreen = level.get_node("BoonScreen") as BoonScreen
	assert_true(screen.is_open())
	var cards: Array[Node] = screen.get_node("%Cards").get_children()
	assert_true((cards[1] as Button).disabled, "aucun don à affûter")
	(cards[0] as Button).pressed.emit()
	assert_almost_eq(hero.health.current, 1.0 + hero.health.maximum * tuning.rest_heal, 0.01, "se reposer")
	# Avec un don pris, le feu l'affûte.
	Game.take_boon(&"ember")
	Game.run.reward = RunState.REST
	level.call(&"_enter_room")
	hero.global_position = Vector3(0.0, 0.0, tuning.encounter_radius / 2.0)
	for i: int in 3:
		await get_tree().process_frame
	cards = screen.get_node("%Cards").get_children()
	assert_false((cards[1] as Button).disabled)
	(cards[1] as Button).pressed.emit()
	assert_eq(Boons.rank(Game.run.boons, &"ember"), 2, "un rang de plus")


func test_le_tresor_et_le_passage_secret() -> void:
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	Game.run.room = 1
	Game.run.reward = RunState.TREASURE
	Game.run.elite_done = true
	level.call(&"_enter_room")
	# (Des renforts peuvent arriver : on libère jusqu'à ce que la clairière soit nettoyée.)
	for i: int in 600:
		if level.get(&"_cleared"):
			break
		if not _muets().is_empty():
			await _free_all()
		await get_tree().physics_frame
	var chests: Array[Node] = level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n.has_signal(&"opened"))
	assert_eq(chests.size(), 1, "un coffre au trésor")
	var feathers: int = Game.run.feathers
	chests[0].emit_signal(&"opened")
	assert_eq(Game.run.feathers, feathers + tuning.treasure_feathers, "des plumes d'or")
	var screen: BoonScreen = level.get_node("BoonScreen") as BoonScreen
	assert_true(screen.is_open(), "et un don")
	(screen.get_node("%Cards").get_child(0) as Button).pressed.emit()
	await get_tree().process_frame
	var gates: Array[Node] = level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n is ExitGate)
	assert_eq(gates.size(), tuning.room_exits)
	level.call(&"_on_secret_revealed", Vector3.ZERO, Vector2(8.0, 0.0))
	gates = level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n is ExitGate)
	assert_eq(gates.size(), tuning.room_exits + 1, "le rocher fêlé ouvre un passage secret")
	assert_eq((gates[gates.size() - 1] as ExitGate).reward, RunState.SECRET)


func test_chaque_region_a_son_gardien_et_s_ouvre_en_le_liberant() -> void:
	Game.profile.regions_won.assign([Regions.UNDERGROWTH])
	Game.profile.region = Regions.SUNKEN
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	assert_eq(Game.run.region, Regions.SUNKEN)
	assert_eq(Rhythm.region(), Regions.SUNKEN, "la musique de la région")
	Game.run.room = Game.run.room_count - 1
	level.call(&"_enter_room")
	await _wait_muets()
	var bosses: Array[Muet] = _muets().filter(func(m: Muet) -> bool: return m.is_boss())
	assert_eq(bosses.size(), 1)
	assert_eq(bosses[0].display_name, GameTexts.GUARDIAN_NAMES[Regions.SUNKEN], "le Gardien des Ruines")
	assert_eq(level.current_goal()[&"title"], GameTexts.GUARDIAN_NAMES[Regions.SUNKEN])
	var s: Dictionary = Game.end_run(&"won")
	assert_eq(s[&"unlocked"], Regions.CANOPY, "la Canopée s'ouvre")
	assert_true(Game.profile.regions_won.has(Regions.SUNKEN))
	var rows: Array = Expedition.summary_of(s)[&"rows"]
	assert_eq(rows[rows.size() - 1][1], GameTexts.REGION_NAMES[Regions.CANOPY], "le résumé l'annonce")
	get_tree().paused = false


func test_l_ecran_titre_choisit_la_region() -> void:
	await _open_level()
	var title: TitleScreen = level.get_node("TitleScreen") as TitleScreen
	assert_true((title.get_node("%Region") as Control).visible)
	assert_eq((title.get_node("%RegionName") as Label).text, GameTexts.REGION_NAMES[Regions.UNDERGROWTH])
	(title.get_node("%RegionNext") as Button).pressed.emit()
	assert_eq((title.get_node("%RegionName") as Label).text, GameTexts.REGION_NAMES[Regions.SUNKEN])
	assert_true((title.get_node("%Play") as Button).disabled, "fermée : on ne peut pas y partir")
	assert_eq(Game.profile.region, Regions.UNDERGROWTH)
	Game.profile.regions_won.assign([Regions.UNDERGROWTH])
	(title.get_node("%RegionPrev") as Button).pressed.emit()
	(title.get_node("%RegionNext") as Button).pressed.emit()
	assert_false((title.get_node("%Play") as Button).disabled)
	assert_eq(Game.profile.region, Regions.SUNKEN, "ouverte : c'est là qu'on partira")
