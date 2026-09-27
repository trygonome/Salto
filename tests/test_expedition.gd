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
	assert_eq(gen.border_radius, tuning.room_radius)
	assert_gt(gen.voxel_count(), 0)
	for gap: float in gaps:
		var door: Vector2 = WorldGen.gap_point(gap, tuning.room_radius)
		for s: WorldGen.Solid in gen.solids:
			assert_gt(WorldGen.segment_distance(Vector2(s.x, s.z), Vector2.ZERO, door), s.r, "rien sur le chemin du passage")


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
