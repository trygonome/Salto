extends GutTest
## Hub vivant et récit réactif (version 3.7) : le Chef réagit aux premières fois, aux chutes, à la
## famille de dons et à l'instrument ; les habitants des cases vivent et parlent ; chaque gardien
## libéré rend une couche à la musique du village.

const LevelScene: PackedScene = preload("res://scenes/levels/expedition.tscn")

var tuning: TuningData = Tuning.data
var level: Expedition
var hero: Hero


func before_each() -> void:
	Save.path = "user://test_hub.json"
	Game.profile = Profile.create()
	Game.profile.expeditions = 1
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


func _open_level() -> void:
	level = LevelScene.instantiate() as Expedition
	hero = level.get_node("Hero") as Hero
	add_child_autofree(level)
	await get_tree().process_frame
	await get_tree().physics_frame


func test_le_chef_reagit_d_abord_a_une_premiere_fois() -> void:
	var summary: Dictionary = {&"kind": &"faint", &"firsts": [&"weapon_hammer", &"stele"], &"family": Boons.FEU, &"faints": 1}
	assert_eq(Village.reaction(summary), GameTexts.CHIEF_FIRSTS[&"stele"], "la stèle compte plus que l'instrument")
	summary[&"firsts"] = [&"weapon_hammer"]
	assert_eq(Village.reaction(summary), GameTexts.CHIEF_FIRST_WEAPON % GameTexts.WEAPON_NAMES[&"hammer"])
	summary[&"firsts"] = []
	summary[&"faints"] = Village.CHIEF_FALLS_FIRST
	assert_eq(Village.reaction(summary), GameTexts.CHIEF_FALLS % Village.CHIEF_FALLS_FIRST, "les chutes qui s'accumulent")
	summary[&"faints"] = 1
	assert_eq(Village.reaction(summary), GameTexts.CHIEF_FAMILY[Boons.FEU], "sinon, la famille qui l'a porté")
	summary[&"family"] = &""
	assert_eq(Village.reaction(summary), "")
	var lines: PackedStringArray = Village.chief_lines({&"kind": &"quit", &"family": Boons.VENT}, Game.profile, tuning)
	assert_eq(lines[0], GameTexts.CHIEF_QUIT)
	assert_eq(lines[1], GameTexts.CHIEF_FAMILY[Boons.VENT], "après ce qu'il pense de l'expédition")


func test_une_premiere_fois_ne_se_dit_qu_une_fois() -> void:
	Game.start_run(4, 7, Regions.UNDERGROWTH)
	Game.run.events.append(&"stele")
	Game.run.boons[&"ember"] = 2
	Game.run.boons[&"tide"] = 1
	var s: Dictionary = Game.end_run(&"faint")
	assert_true((s[&"firsts"] as Array).has(&"stele"))
	assert_true((s[&"firsts"] as Array).has(StringName("weapon_%s" % Game.profile.weapon)), "le premier instrument")
	assert_eq(s[&"family"], Boons.FEU, "le Feu a reçu le plus de rangs")
	assert_eq(s[&"faints"], 1)
	Game.start_run(5, 7, Regions.UNDERGROWTH)
	Game.run.events.append(&"stele")
	s = Game.end_run(&"faint")
	assert_false((s[&"firsts"] as Array).has(&"stele"), "la deuxième fois, on n'en parle plus")
	assert_eq(s[&"faints"], 2)
	var saved: Profile = Profile.from_dict(Game.profile.to_dict())
	assert_true(saved.firsts.has(&"stele"), "gardé dans la sauvegarde")
	assert_eq(saved.faints, 2)


func test_chaque_gardien_libere_rend_une_couche_au_village() -> void:
	var profile := Profile.create()
	assert_true(Village.guardian_layers(profile).is_empty())
	assert_eq(Village.village_band(profile, tuning), Village.band_floor(profile, tuning))
	profile.regions_won.assign([Regions.UNDERGROWTH, Regions.SUNKEN])
	assert_eq(Village.guardian_layers(profile), [Regions.SUNKEN] as Array[StringName], "la couche des Ruines")
	assert_eq(Village.village_band(profile, tuning), tuning.village_guardian_band, "le Grand Muet rend la voix de la troupe")
	Game.profile.regions_won.assign([Regions.UNDERGROWTH, Regions.SUNKEN, Regions.CANOPY])
	await _open_level()
	level.enter_village()
	assert_eq(Rhythm.region_mix(), [Regions.SUNKEN, Regions.CANOPY] as Array[StringName], "au village, les deux couches ensemble")
	assert_eq(Rhythm.band_amount(), tuning.village_guardian_band)


func test_un_habitant_va_et_vient_entre_sa_case_et_le_feu() -> void:
	var villager := Villager.new()
	add_child_autofree(villager)
	villager.setup(VoxelStyles.dancer(3), "test_resident", 1.0, 0.0, 0.0, INF, null, null, tuning.villager_shadow_radius)
	villager.set_route(Vector3.ZERO, Vector3(2.0, 0.0, 0.0))
	villager.set(&"_rest", 0.0)
	for i: int in 30:
		villager.call(&"_walk", 0.1, tuning)
	assert_almost_eq(villager.position.x, minf(2.0, tuning.villager_walk_speed * 3.0), 0.05, "il marche vers le feu")
	villager.set(&"_rest", 0.0)
	for i: int in 100:
		villager.call(&"_walk", 0.1, tuning)
		villager.set(&"_rest", 0.0)
	assert_between(villager.position.x, 0.0, 2.0, "puis revient, et ainsi de suite")


func test_les_habitants_des_cases_rebaties_parlent_au_heros() -> void:
	Game.profile.village[Village.ALTAR] = 1
	Game.profile.village[Village.SPRING] = 1
	await _open_level()
	level.enter_village()
	var residents: Dictionary = level.get(&"_residents")
	assert_eq(residents.size(), 2, "un habitant par case rebâtie")
	# (Le Chef parle d'abord : un message à la fois.)
	level.set(&"_chief_lines", PackedStringArray())
	level.set(&"_line_left", 0.0)
	var resident: Villager = residents[Village.SPRING]
	resident.route = PackedVector3Array()
	# (Du côté opposé à sa case, hors de la zone où la case parle.)
	var plot: Vector2 = WorldGen.VILLAGE_PLOTS[Village.SPRING] * tuning.voxel_unit
	var away := Vector3(resident.global_position.x - plot.x, 0.0, resident.global_position.z - plot.y).normalized()
	hero.global_position = resident.global_position + away * 0.4
	for i: int in 3:
		await get_tree().process_frame
	var hud: Hud = level.get_node("HUD") as Hud
	assert_true((GameTexts.RESIDENT_LINES.get(Village.SPRING) as PackedStringArray).has(hud.current_bubble()), "l'habitante de la source parle : %s" % hud.current_bubble())


func test_le_chef_reagit_a_l_instrument_choisi() -> void:
	await _open_level()
	level.enter_village()
	level.on_weapon_chosen(&"hammer")
	var lines: PackedStringArray = level.get(&"_chief_lines")
	assert_eq(lines[0], GameTexts.CHIEF_WEAPON[&"hammer"])
