extends GutTest
## Village vivant 2.7 : les plumes d'or rebâtissent les cases (prix, rangs, effets), le Chef
## commente l'expédition, et le village se parcourt à pied (chantiers, départ au nord).

const LevelScene: PackedScene = preload("res://scenes/levels/expedition.tscn")

var tuning: TuningData = Tuning.data
var level: Expedition
var hero: Hero


func before_each() -> void:
	Save.path = "user://test_village.json"
	Game.profile = Profile.create()
	Game.start_on_load = false
	Game.village_on_load = false
	Game.last_summary = {}
	Game.run = null


func after_each() -> void:
	get_tree().paused = false
	Game.run = null
	Game.playing = false
	Game.last_summary = {}
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


func test_les_plumes_rebatissent_les_cases() -> void:
	var profile := Profile.create()
	for id: StringName in Village.IDS:
		assert_eq(Village.rank(profile, id), 0)
		assert_gt(Village.cost(profile, id, tuning), 0, "un prix pour %s" % id)
		assert_true(GameTexts.BUILDING_NAMES.has(id) and GameTexts.BUILDING_TEXTS.has(id) and GameTexts.BUILDING_LINES.has(id))
		assert_true(WorldGen.VILLAGE_PLOTS.has(id), "sa place au village")
	assert_false(Village.build(profile, Village.ALTAR, tuning), "pas assez de plumes")
	profile.feathers = 1000
	var price: int = Village.cost(profile, Village.ALTAR, tuning)
	assert_true(Village.build(profile, Village.ALTAR, tuning))
	assert_eq(profile.feathers, 1000 - price, "les plumes partent")
	assert_eq(Village.rank(profile, Village.ALTAR), 1)
	assert_eq(Village.cost(profile, Village.ALTAR, tuning), -1, "un seul rang")
	assert_false(Village.build(profile, Village.ALTAR, tuning))
	for i: int in Village.max_rank(Village.SPRING, tuning):
		assert_true(Village.build(profile, Village.SPRING, tuning))
	assert_eq(Village.rank(profile, Village.SPRING), 3, "la source a trois rangs")
	assert_eq(Village.built_count(profile), 2)
	var saved: Profile = Profile.from_dict(JSON.parse_string(JSON.stringify(profile.to_dict())))
	assert_eq(Village.rank(saved, Village.SPRING), 3, "gardé dans la sauvegarde")
	assert_eq(Village.rank(saved, Village.ALTAR), 1)


func test_chaque_case_change_quelque_chose() -> void:
	var profile := Profile.create()
	var base: HeroStats = HeroStats.compute(profile, tuning)
	profile.village = {Village.ALTAR: 1, Village.DRUM_HUT: 1, Village.SPRING: 2, Village.STAGE: 1} as Dictionary[StringName, int]
	assert_eq(Village.extra_boons(profile), 1, "l'autel : un don de plus au choix")
	assert_eq(HeroStats.compute(profile, tuning).max_health, base.max_health + 2.0 * tuning.village_spring_health, "la source : des PV")
	assert_eq(Village.music_layers(profile), 2, "la scène : une couche de plus")
	assert_gt(Village.band_floor(profile, tuning), 0.0, "et la troupe")
	var plain := RunState.new(5, 7)
	var drummed := RunState.new(5, 7)
	drummed.extra_encounters = Village.extra_encounters(profile)
	var plain_count: int = 0
	var drummed_count: int = 0
	for i: int in 300:
		var a: Array[StringName] = plain.exit_rewards(2)
		var b: Array[StringName] = drummed.exit_rewards(2)
		assert_ne(b[0], b[1], "toujours deux récompenses différentes")
		plain_count += a.count(RunState.ENCOUNTER)
		drummed_count += b.count(RunState.ENCOUNTER)
	assert_gt(drummed_count, plain_count, "la case du tambourinaire : plus de rencontres")


func test_le_chef_commente_l_expedition() -> void:
	var profile := Profile.create()
	var welcome: PackedStringArray = Village.chief_lines({}, profile, tuning)
	assert_eq(welcome[0], GameTexts.CHIEF_WELCOME, "la première fois")
	profile.best_room = 3
	profile.runs_won = 1
	var won: Dictionary = {&"kind": &"won", &"region": Regions.UNDERGROWTH, &"unlocked": &""}
	assert_eq(Village.chief_lines(won, profile, tuning)[0], GameTexts.CHIEF_FIRST_WIN)
	won[&"unlocked"] = Regions.SUNKEN
	assert_true(Village.chief_lines(won, profile, tuning)[0].contains(GameTexts.REGION_NAMES[Regions.SUNKEN]), "la route ouverte")
	var close: Dictionary = {&"kind": &"faint", &"room": 7, &"rooms": 7, &"boss_left": 0.1, &"region": Regions.SUNKEN}
	assert_eq(Village.chief_lines(close, profile, tuning)[0], GameTexts.CHIEF_BOSS_CLOSE % GameTexts.GUARDIAN_NAMES[Regions.SUNKEN], "il vacillait")
	close[&"boss_left"] = 0.8
	assert_eq(Village.chief_lines(close, profile, tuning)[0], GameTexts.CHIEF_BOSS_LOST % GameTexts.GUARDIAN_NAMES[Regions.SUNKEN])
	var fallen: Dictionary = {&"kind": &"faint", &"room": 4, &"rooms": 7, &"boss_left": -1.0, &"fallen_to": &"shielder"}
	assert_eq(Village.chief_lines(fallen, profile, tuning)[0], GameTexts.CHIEF_FALLEN[&"shielder"], "il rappelle la réponse")
	fallen[&"record"] = true
	assert_eq(Village.chief_lines(fallen, profile, tuning)[0], GameTexts.CHIEF_RECORD % 4, "un record d'abord")
	assert_eq(Village.chief_lines({&"kind": &"faint", &"room": 1, &"rooms": 7}, profile, tuning)[0], GameTexts.CHIEF_EARLY)
	assert_eq(Village.chief_lines({&"kind": &"quit"}, profile, tuning)[0], GameTexts.CHIEF_QUIT)
	assert_eq(Village.chief_lines({&"kind": &"quit"}, profile, tuning).size(), 1, "pas assez de plumes : rien de plus")
	profile.feathers = 500
	var lines: PackedStringArray = Village.chief_lines({&"kind": &"quit"}, profile, tuning)
	assert_eq(lines.size(), 2, "puis il rappelle de rebâtir")
	assert_eq(lines[1], GameTexts.CHIEF_BUILD % 500)
	for species: StringName in [&"hopper", &"flyer", &"shielder", &"charger", &"spitter", &"weaver", &"totem", &"dancer", &"brute"]:
		assert_true(GameTexts.CHIEF_FALLEN.has(species), String(species))


func test_on_marche_au_village_et_on_y_rebatit() -> void:
	Game.profile.feathers = 200
	Game.last_summary = {&"kind": &"faint", &"room": 1, &"rooms": 7, &"feathers": 12}
	await _open_level()
	level.enter_village()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(level.in_village)
	assert_false(level.get_node("TitleScreen").is_open())
	assert_eq(level.current_goal()[&"icon"], &"home")
	var hud: Hud = level.get_node("HUD") as Hud
	assert_eq(hud.current_bubble(), GameTexts.CHIEF_EARLY, "le Chef commente la partie")
	assert_true(Game.last_summary.is_empty(), "une seule fois")
	var gates: Array[Node] = level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n is ExitGate)
	assert_eq(gates.size(), 1, "le passage du nord")
	assert_eq((gates[0] as ExitGate).reward, &"depart")
	var plot: Vector2 = WorldGen.VILLAGE_PLOTS[Village.ALTAR] * tuning.voxel_unit
	hero.global_position = Vector3(plot.x, 0.0, plot.y) + Vector3(0.0, 0.0, tuning.village_plot_radius * 0.5)
	await get_tree().process_frame
	await get_tree().process_frame
	var screen: BoonScreen = level.get_node("BoonScreen") as BoonScreen
	assert_true(screen.is_open(), "le chantier parle")
	var cards: Array[Node] = screen.get_node("%Cards").get_children()
	assert_false((cards[0] as Button).disabled, "assez de plumes")
	var price: int = Village.cost(Game.profile, Village.ALTAR, tuning)
	(cards[0] as Button).pressed.emit()
	assert_eq(Village.rank(Game.profile, Village.ALTAR), 1, "l'autel est rebâti")
	assert_eq(Game.profile.feathers, 200 - price)
	assert_eq(level.call(&"_boon_offer"), tuning.boon_offer + 1, "un don de plus au choix")
	assert_eq(hud.current_toast(), GameTexts.BUILD_DONE % GameTexts.BUILDING_NAMES[Village.ALTAR])
	await get_tree().process_frame
	assert_false(screen.is_open(), "il ne reparle pas tout de suite")
	gates = level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n is ExitGate)
	(gates[0] as ExitGate).chosen.emit(&"depart")
	await get_tree().create_timer(tuning.room_fade_time * 3.0).timeout
	assert_false(level.in_village)
	assert_true(level.in_sortie, "on part en expédition")
	assert_eq(Game.run.room, 0)


func test_la_pause_s_ouvre_au_village() -> void:
	await _open_level()
	level.enter_village()
	await get_tree().process_frame
	var pause: Node = level.get_node("PauseMenu")
	pause.call(&"open")
	assert_true(pause.call(&"is_open"), "on peut ouvrir la pause au village")
	assert_eq((pause.get_node("%Quit") as Button).text, GameTexts.QUIT_TO_TITLE)
	pause.call(&"close")


func test_les_endroits_du_village_ne_se_chevauchent_pas() -> void:
	var places: Array[Vector2] = [WorldGen.VILLAGE_RACK, WorldGen.VILLAGE_PACTS, WorldGen.VILLAGE_CHIEF]
	for id: StringName in WorldGen.VILLAGE_PLOTS:
		places.append(WorldGen.VILLAGE_PLOTS[id])
	# Dans la zone de l'un (Tuning.village_plot_radius), jamais dans celle d'un autre.
	var apart: float = 2.0 * tuning.village_plot_radius / tuning.voxel_unit
	for i: int in places.size():
		assert_lt(places[i].length(), tuning.room_radius - 3.0, "dans la clairière")
		for j: int in range(i + 1, places.size()):
			if i == 2 or j == 2:
				continue
			assert_gt(places[i].distance_to(places[j]), apart, "deux endroits trop proches (%d, %d)" % [i, j])
