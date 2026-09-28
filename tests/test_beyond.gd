extends GutTest
## Au-delà (version 4.2) : le gardien libéré, on rentre au village ou l'on continue dans la région
## suivante, étape après étape, sans fin ; chaque gardien libéré compte.

const LevelScene: PackedScene = preload("res://scenes/levels/expedition.tscn")

var tuning: TuningData = Tuning.data
var level: Expedition
var hero: Hero


func before_each() -> void:
	Save.path = "user://test_beyond.json"
	Game.profile = Profile.create()
	Game.profile.expeditions = 1
	Game.start_on_load = false
	Game.village_on_load = false
	Game.run = null


func after_each() -> void:
	get_tree().paused = false
	Game.run = null
	Game.playing = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.path))


func after_all() -> void:
	Game.profile = Profile.new()
	Game.refresh_stats()


func _gates() -> Array[Node]:
	return level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n is ExitGate)


func test_chez_le_gardien_deux_portes_rentrer_ou_au_dela() -> void:
	var run := RunState.new(5, 7)
	run.room = run.room_count - 1
	assert_eq(run.exit_count(2), 2)
	assert_eq(run.exit_rewards(2), [RunState.HOME, RunState.BEYOND] as Array[StringName])
	for reward: StringName in [RunState.HOME, RunState.BEYOND]:
		assert_true(GameTexts.REWARD_NAMES.has(reward))
		assert_true(VoxelIcons.ART.has(reward), "une icône pour %s" % reward)


func test_au_dela_la_jungle_continue_dans_la_region_suivante() -> void:
	var run := RunState.new(5, 7, Regions.UNDERGROWTH)
	run.room = run.room_count - 1
	run.elite_done = true
	assert_false(run.is_beyond())
	run.go_beyond(tuning.beyond_leg_rooms)
	run.enter_next(RunState.BOON)
	assert_true(run.is_beyond())
	assert_eq(run.region, Regions.SUNKEN, "la région suivante")
	assert_eq(run.guardians, [Regions.UNDERGROWTH] as Array[StringName])
	assert_eq(run.room, 7)
	assert_eq(run.leg_first, 7)
	assert_eq(run.room_count, 7 + tuning.beyond_leg_rooms, "une nouvelle étape")
	assert_false(run.is_boss_room())
	assert_false(run.elite_done, "un nouvel élite par étape")
	assert_almost_eq(run.leg_progress(), 0.0, 0.001, "la région retrouve ses couleurs depuis le début")
	run.room = run.room_count - 1
	assert_true(run.is_boss_room(), "au bout de l'étape, son gardien")
	assert_almost_eq(run.leg_progress(), 1.0, 0.001)
	assert_eq(Regions.beyond(Regions.CANOPY), Regions.UNDERGROWTH, "les régions tournent sans fin")
	var saved: RunState = RunState.from_dict(run.to_dict())
	assert_eq(saved.guardians, run.guardians, "gardé dans la sauvegarde")
	assert_eq(saved.leg_first, run.leg_first)
	assert_eq(saved.room_count, run.room_count)


func test_chaque_gardien_libere_compte_meme_si_l_on_tombe_plus_loin() -> void:
	Game.start_run(9, 7, Regions.UNDERGROWTH)
	Game.run.room = 6
	Game.run.go_beyond(tuning.beyond_leg_rooms)
	Game.run.enter_next(RunState.BOON)
	var s: Dictionary = Game.end_run(&"faint")
	assert_true(Game.profile.regions_won.has(Regions.UNDERGROWTH), "le premier gardien compte")
	assert_eq(s[&"unlocked"], Regions.SUNKEN)
	assert_eq(s[&"guardians"], 1)
	assert_true(s[&"beyond"])
	var rows: Array = Expedition.summary_of(s)[&"rows"]
	assert_true(rows.any(func(row: Array) -> bool: return row[0] == GameTexts.RUN_GUARDIANS), "le résumé compte les gardiens")


func test_libere_le_gardien_puis_va_au_dela() -> void:
	level = LevelScene.instantiate() as Expedition
	hero = level.get_node("Hero") as Hero
	add_child_autofree(level)
	await get_tree().process_frame
	level.start_sortie()
	hero.reads_player_input = false
	Game.run.room = Game.run.room_count - 1
	level.call(&"_enter_room")
	level.call(&"_on_boss_freed", null)
	assert_true(level.in_sortie, "le gardien libéré, on ne rentre pas encore")
	await get_tree().create_timer(tuning.beyond_gates_delay + 0.3).timeout
	var rewards: Array = _gates().map(func(g: Node) -> StringName: return (g as ExitGate).reward)
	assert_true(rewards.has(RunState.HOME) and rewards.has(RunState.BEYOND), "deux portes : %s" % [rewards])
	var beyond: ExitGate = _gates().filter(func(g: Node) -> bool: return (g as ExitGate).reward == RunState.BEYOND)[0]
	var region: StringName = Game.run.region
	beyond.chosen.emit(RunState.BEYOND)
	await get_tree().create_timer(tuning.room_fade_time * 1.5).timeout
	assert_true(level.in_sortie, "l'expédition continue")
	assert_eq(Game.run.region, Regions.beyond(region), "dans la région suivante")
	assert_eq(Game.run.reward, RunState.BOON, "la première clairière offre un don")
	assert_true(Game.run.events.has(&"beyond"), "le Chef en parlera")
	assert_eq(level.ambience.place, Game.run.region, "son ambiance")
	assert_eq(Village.reaction({&"firsts": [&"beyond", &"stele"]}), GameTexts.CHIEF_FIRSTS[&"beyond"], "la première fois au-delà compte plus que tout")


func test_au_dela_les_vagues_ne_grossissent_plus() -> void:
	assert_lte(tuning.room_wave_base + roundi(tuning.room_wave_per_room * (tuning.run_rooms - 2)), tuning.room_wave_max, "une expédition ordinaire n'atteint pas la limite")
	assert_gt(tuning.room_wave_base + roundi(tuning.room_wave_per_room * 30), tuning.room_wave_max, "au-delà, la limite tient")
