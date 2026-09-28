extends GutTest
## Confort mobile 2.9 : reprendre une expédition interrompue, première expédition qui apprend sans
## texte (et conseils de réponse près des boutons), pactes de difficulté.

const LevelScene: PackedScene = preload("res://scenes/levels/expedition.tscn")

var tuning: TuningData = Tuning.data
var level: Expedition
var hero: Hero


func before_each() -> void:
	Save.path = "user://test_comfort.json"
	Game.profile = Profile.create()
	Game.start_on_load = false
	Game.village_on_load = false
	Game.last_summary = {}
	Game.run = null


func after_each() -> void:
	get_tree().paused = false
	Game.run = null
	Game.playing = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.path))


func after_all() -> void:
	Game.profile = Profile.new()
	Game.refresh_stats()


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


func test_une_expedition_se_sauvegarde_et_se_relit() -> void:
	var run := RunState.new(77, 7, Regions.SUNKEN)
	run.room = 3
	run.reward = RunState.TREASURE
	run.take_boon(&"fury", 2)
	run.feathers = 21
	run.pacts.assign([Pacts.STINGY])
	run.weapon = &"hammer"
	run.encounters_seen.assign([&"spring"])
	var draws: Array[StringName] = run.exit_rewards(2)
	run.rng.seed = 77
	var copy: RunState = RunState.from_dict(JSON.parse_string(JSON.stringify(run.to_dict())))
	assert_eq(copy.room, 3)
	assert_eq(copy.region, Regions.SUNKEN)
	assert_eq(copy.reward, RunState.TREASURE)
	assert_eq(Boons.rank(copy.boons, &"fury"), 2)
	assert_eq(copy.feathers, 21)
	assert_eq(copy.weapon, &"hammer")
	assert_eq(copy.pacts, [Pacts.STINGY] as Array[StringName])
	assert_eq(copy.exit_rewards(2), run.exit_rewards(2), "mêmes tirages")
	assert_false(draws.has(RunState.HEAL) or draws.has(RunState.REST), "jungle avare : ni soin ni repos")
	assert_null(RunState.from_dict({}), "une sauvegarde abîmée ne se reprend pas")


func test_on_reprend_l_expedition_interrompue() -> void:
	Game.profile.expeditions = 1
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	Game.run.enter_next(RunState.FEATHERS)
	level.call(&"_enter_room")
	assert_true(Game.has_saved_run(), "sauvegardée en entrant dans la clairière")
	hero.health.current = 40.0
	Game.snapshot_run(hero.health.current)
	var saved: Dictionary = Game.profile.saved_run.duplicate(true)
	# L'application se ferme : on relit le profil sauvegardé.
	Game.run = null
	var reloaded: Profile = Profile.from_dict(JSON.parse_string(JSON.stringify(Game.profile.to_dict())))
	assert_eq(reloaded.saved_run.get("room"), saved.get("room"))
	Game.profile = reloaded
	var title: TitleScreen = level.get_node("TitleScreen") as TitleScreen
	title.refresh()
	assert_eq((title.get_node("%Play") as Button).text, GameTexts.EXPEDITION_RESUME % [2, tuning.run_rooms])
	level.in_sortie = false
	level.resume_sortie()
	assert_true(level.in_sortie)
	assert_eq(Game.run.room, 1, "la même clairière")
	assert_eq(Game.run.reward, RunState.FEATHERS)
	assert_eq(hero.health.current, 40.0, "les mêmes PV")
	Game.end_run(&"quit")
	assert_false(Game.has_saved_run(), "finie : plus rien à reprendre")
	get_tree().paused = false


func test_la_premiere_expedition_apprend_une_espece_a_la_fois() -> void:
	assert_eq(WaveComposer.tutorial(0, 0), [&"hopper"] as Array[StringName])
	assert_eq(WaveComposer.tutorial(1, 0), [&"shielder"] as Array[StringName])
	assert_true(WaveComposer.tutorial(5, 0).is_empty(), "ensuite, les vagues composées")
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	assert_true(Game.run.tutorial, "la toute première expédition")
	await _wait_muets()
	assert_eq(_muets().size(), 1, "un seul sautillant")
	assert_eq(_muets()[0].species, &"hopper")
	assert_eq(_muets()[0].elite, &"", "pas d'élite")
	Game.end_run(&"quit")
	get_tree().paused = false
	Game.start_run(1, 7)
	assert_false(Game.run.tutorial, "la suivante est normale")


func test_un_conseil_apprend_la_reponse_d_une_espece() -> void:
	Game.profile.mark_hint_done(&"move")
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	await _wait_muets()
	var muet: Muet = _muets()[0]
	muet.set_physics_process(false)
	muet.global_position = hero.global_position + Vector3(0.0, 0.0, -2.0)
	var coach: ExpeditionCoach = level.get(&"_coach")
	Game.profile.mark_hint_done(&"attack")
	Game.profile.mark_hint_done(&"dodge")
	for i: int in 5:
		await get_tree().process_frame
	assert_eq(coach.current(), &"answer_hopper", "près d'un sautillant : sa réponse")
	var hud: Hud = level.get_node("HUD") as Hud
	assert_eq(hud.current_coach(), GameTexts.HINTS[&"answer_hopper"])
	hero.answered.emit(&"hopper")
	assert_true(Game.profile.is_hint_done(&"answer_hopper"), "appris : il ne revient plus")
	for id: StringName in [&"answer_weaver", &"answer_totem", &"answer_dancer", &"answer_brute", &"grace", &"charge"]:
		assert_true(GameTexts.HINTS.has(id), String(id))


func test_les_pactes_rendent_plus_rude_contre_plus_de_plumes() -> void:
	var pacts: Array[StringName] = Pacts.toggle([] as Array[StringName], Pacts.FRAGILE)
	assert_eq(pacts, [Pacts.FRAGILE] as Array[StringName])
	assert_true(Pacts.toggle(pacts, Pacts.FRAGILE).is_empty(), "on le retire")
	pacts.append(Pacts.THICK_SKIN)
	assert_almost_eq(Pacts.feather_multiplier(pacts, tuning), 1.0 + tuning.pact_bonus[Pacts.FRAGILE] + tuning.pact_bonus[Pacts.THICK_SKIN], 0.001)
	var profile := Profile.create()
	var base: HeroStats = HeroStats.compute(profile, tuning)
	var fragile: HeroStats = HeroStats.compute(profile, tuning, {} as Dictionary[StringName, int], [Pacts.FRAGILE, Pacts.HARD_HITS] as Array[StringName])
	assert_lt(fragile.max_health, base.max_health, "cœur fragile")
	assert_gt(fragile.damage_taken, base.damage_taken, "coups rudes")
	Game.profile.pacts.assign([Pacts.FRAGILE])
	Game.profile.expeditions = 1
	Game.start_run(3, 7)
	assert_eq(Game.run.pacts, [Pacts.FRAGILE] as Array[StringName], "pris au départ")
	Game.run.feathers = 100
	var s: Dictionary = Game.end_run(&"won")
	assert_eq(s[&"feathers"], roundi(100 * (1.0 + tuning.pact_bonus[Pacts.FRAGILE])), "plus de plumes rapportées")
	get_tree().paused = false


func test_la_pierre_des_pactes_au_village() -> void:
	Game.profile.expeditions = 1
	await _open_level()
	level.enter_village()
	await get_tree().process_frame
	var stone: Vector2 = WorldGen.VILLAGE_PACTS * tuning.voxel_unit
	hero.global_position = Vector3(stone.x, 0.0, stone.y) + Vector3(0.0, 0.0, tuning.village_plot_radius * 0.5)
	await get_tree().process_frame
	await get_tree().process_frame
	var screen: DepartScreen = level.get_node("DepartScreen") as DepartScreen
	assert_true(screen.is_open(), "la pierre ouvre la page de départ")
	assert_true(get_tree().paused)
	assert_eq(screen.get_node("%PactCards").get_child_count(), Pacts.IDS.size())
	(screen.get_node("%PactCards").get_child(0) as Button).pressed.emit()
	assert_eq(Game.profile.pacts, [Pacts.IDS[0]] as Array[StringName])
	assert_true(screen.is_open(), "elle reste ouverte")
	var bonus: String = "%d" % roundi(tuning.pact_bonus[Pacts.IDS[0]] * 100.0)
	assert_true((screen.get_node("%Go") as Button).text.contains(bonus), "le bonus s'affiche sur « Partir »")
	screen.go_back()
	assert_false(screen.is_open(), "c'est décidé")
	assert_false(get_tree().paused, "on reprend la marche au village")
	assert_true(String(level.current_goal()[&"sub"]).contains(bonus), "le bonus s'affiche")
