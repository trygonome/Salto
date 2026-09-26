extends GutTest
## Nuit dans le monde voxel : l'écran titre au-dessus du village qui danse, puis une sortie (trois
## sanctuaires gardés chacun par un Grand Muet et ses Muets, des errants), l'objectif qui mène au
## sanctuaire puis ramène le tambour, les tambours déjà rapportés qui restent au village, les
## plumes des perchoirs, et la fin de sortie avec son résumé.

const LevelScene: PackedScene = preload("res://scenes/levels/night.tscn")
## Graine fixe : le monde est toujours le même.
const SEED := 12345
## Pas de physique attendus au plus pour qu'une zone voie le héros.
const MAX_OVERLAP_FRAMES := 30

var tuning: TuningData = Tuning.data
var level: VoxelNight
var hero: Hero


func before_each() -> void:
	Save.path = "user://test_night_level.json"
	Game.profile = Profile.create()
	Game.profile.night_seed = SEED
	Game.start_on_load = false


func after_each() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.path))


func _open_level() -> void:
	level = LevelScene.instantiate() as VoxelNight
	hero = level.get_node("Hero") as Hero
	add_child_autofree(level)
	await get_tree().process_frame
	await get_tree().physics_frame


func _start() -> void:
	level.start_sortie()
	hero.reads_player_input = false
	# Les Muets apparaissent au pas suivant.
	await get_tree().process_frame
	await get_tree().physics_frame


func _spawners() -> Array[EnemySpawner]:
	var found: Array[EnemySpawner] = []
	for node: Node in level.get_node("Foes").get_children():
		if node is EnemySpawner:
			found.append(node as EnemySpawner)
	return found


func test_l_ecran_titre_s_ouvre_sur_le_village_qui_danse() -> void:
	await _open_level()
	assert_false(level.in_sortie)
	assert_true((level.get_node("TitleScreen") as TitleScreen).is_open())
	assert_false(level.get_node("HUD").visible, "pas de HUD à l'écran titre")
	assert_eq(_spawners().size(), 0, "pas de Muets avant la sortie")
	var villagers: Array[Node] = level.get_node("Village").find_children("*", "Villager", false, false)
	assert_eq(villagers.size(), WorldGen.DANCERS.size() + 1, "six danseurs et le Chef")
	assert_false(hero.reads_player_input, "le héros attend")


func test_une_sortie_part_du_village_avec_la_musique_de_base() -> void:
	await _open_level()
	await _start()
	assert_true(level.in_sortie)
	assert_true(Game.playing)
	assert_false((level.get_node("TitleScreen") as TitleScreen).is_open())
	assert_true(level.get_node("HUD").visible)
	assert_eq(Game.profile.sortie, 1)
	assert_eq(Rhythm.audible_layers(), 1)
	var village: Area3D = level.get_node("Village/VillageZone") as Area3D
	for i: int in MAX_OVERLAP_FRAMES:
		if village.overlaps_body(hero):
			break
		await get_tree().physics_frame
	assert_true(village.overlaps_body(hero), "le héros part du village")


func test_le_monde_est_celui_de_la_graine_de_la_nuit() -> void:
	await _open_level()
	assert_eq(Game.profile.night_seed, SEED, "la graine reste pour les sorties suivantes")
	assert_eq(level.gen.voxel_count(), 17432)
	assert_eq(level.gen.sanctuaries.size(), 3)


func test_une_trentaine_de_muets_gardent_les_sanctuaires_ou_errent() -> void:
	await _open_level()
	await _start()
	var spawners: Array[EnemySpawner] = _spawners()
	var wanderers: int = spawners.filter(func(s: EnemySpawner) -> bool: return s.wanderer).size()
	var guards: int = 0
	for i: int in level.gen.sanctuaries.size():
		guards += tuning.sanctuary_guards + i
	assert_eq(wanderers, tuning.muet_wanderers)
	assert_eq(spawners.size(), level.gen.sanctuaries.size() + guards + tuning.muet_wanderers)
	var village: float = tuning.village_radius
	for spawner: EnemySpawner in spawners:
		assert_gt(Vector2(spawner.position.x, spawner.position.z).length(), village, "aucun Muet au village")
		assert_eq(spawner.safe_zone_radius, village, "les Muets n'entrent pas au village")
	for i: int in level.bosses.size():
		assert_eq(level.bosses[i].scene.resource_path, "res://scenes/enemies/grand_muet.tscn")
		assert_string_contains(level.bosses[i].display_name, level.gen.sanctuary_names[i])


func test_chaque_tambour_attend_sur_son_autel() -> void:
	await _open_level()
	assert_eq(level.drums.size(), 3)
	for i: int in level.drums.size():
		var drum: Node3D = level.drums[i]
		var altar: Vector3 = level.to_world(level.gen.sanctuaries[i])
		var flat := Vector2(drum.global_position.x - altar.x, drum.global_position.z - altar.z)
		assert_almost_eq(flat.length(), 0.0, 0.01, "le tambour est sur son autel")
		assert_gt(drum.global_position.y, 0.0, "posé en haut de l'autel")
		assert_true(drum.visible)


func test_un_tambour_deja_rapporte_reste_au_village() -> void:
	Game.profile.banked[1] = true
	await _open_level()
	await _start()
	assert_false(level.drums[1].visible, "plus sur son autel")
	assert_eq(level.bosses.size(), 2, "son sanctuaire n'est plus gardé")
	assert_eq(Game.progress.drums_returned, 1)
	var goal: Dictionary = level.objective()
	assert_eq(goal[&"index"], 0)
	var stand: Node = level.get_node("Village/VillageDrums")
	assert_true((stand.get(&"slots") as Array)[1].visible, "il est posé au village")


func test_l_objectif_mene_au_sanctuaire_puis_ramene_le_tambour() -> void:
	await _open_level()
	await _start()
	var goal: Dictionary = level.objective()
	assert_eq(goal[&"kind"], &"free", "d'abord libérer le premier sanctuaire")
	assert_eq(goal[&"index"], 0)
	assert_string_contains(goal[&"title"], level.gen.sanctuary_names[0])
	var boss: EnemySpawner = level.bosses[0]
	var hit := HitData.new()
	hit.damage = boss.muet.health.maximum
	hit.direction = Vector3.FORWARD
	boss.muet.hurtbox.receive(hit)
	await get_tree().physics_frame
	assert_true(level.drums[0].call(&"is_available"), "le tambour sort de sa bulle")
	assert_eq(level.objective()[&"kind"], &"pick", "aller prendre le tambour libéré")
	var drops: Array[Node] = level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n is Fruit or n is LootDrop)
	assert_eq(drops.size(), 2, "un fruit et un objet")
	Game.pick_drum(0)
	goal = level.objective()
	assert_eq(goal[&"kind"], &"return", "le rapporter au village")
	assert_eq(goal[&"index"], 0, "le chemin doré part de son sanctuaire")


func test_une_plume_arc_en_ciel_sur_chaque_perchoir_remplit_la_jauge() -> void:
	await _open_level()
	await _start()
	var plumes: Array[Node] = level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n is PlumePickup)
	assert_eq(plumes.size(), level.gen.pickups.size(), "une par perchoir, à chaque sortie")
	hero.groove.empty()
	var plume: PlumePickup = plumes[0] as PlumePickup
	hero.global_position = plume.global_position - Vector3.UP * tuning.perch_pickup_height
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_true(hero.groove.is_full(), "de quoi lancer le Salto arc-en-ciel")


func test_rentrer_au_village_ouvre_le_resume() -> void:
	await _open_level()
	await _start()
	level.end_sortie(&"quit")
	assert_false(level.in_sortie)
	assert_false(Game.playing)
	assert_true(get_tree().paused, "le jeu s'arrête derrière le résumé")
	assert_true((level.get_node("SummaryScreen") as SummaryScreen).is_open())
	assert_false(level.get_node("HUD").visible)


func test_evanoui_la_sortie_se_termine() -> void:
	await _open_level()
	await _start()
	var hit := HitData.new()
	hit.damage = hero.health.maximum
	hit.direction = Vector3.FORWARD
	hero.hurtbox.receive(hit)
	assert_eq(level.get_node("HUD").call(&"current_toast"), GameTexts.TOAST_FAINT)
	await get_tree().create_timer(tuning.faint_summary_delay + 0.1).timeout
	assert_true((level.get_node("SummaryScreen") as SummaryScreen).is_open())
	assert_eq(Game.profile.total_sorties, 1)


func test_les_renforts_arrivent_quand_le_grand_muet_frappe() -> void:
	Game.profile.night = tuning.boss_summon_night
	await _open_level()
	await _start()
	var boss: Muet = level.bosses[0].muet
	for spawner: EnemySpawner in level.guards[0]:
		spawner.muet.health.take(spawner.muet.health.maximum)
	var before: int = level.guards[0].size()
	level.summon_guards(boss)
	assert_eq(level.guards[0].size(), before + tuning.boss_summon_count)
