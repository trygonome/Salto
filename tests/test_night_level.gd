extends GutTest
## Nuit dans le monde voxel : départ au village avec la musique de base, trois sanctuaires gardés
## chacun par un Grand Muet et ses Muets, des errants, les villageois qui dansent, et l'objectif
## qui mène au prochain sanctuaire puis ramène le tambour au village.

const LevelScene: PackedScene = preload("res://scenes/levels/night.tscn")
## Graine fixe : le monde est toujours le même.
const SEED := 12345
## Pas de physique attendus au plus pour qu'une zone voie le héros.
const MAX_OVERLAP_FRAMES := 30

var tuning: TuningData = Tuning.data
var level: VoxelNight
var hero: Hero


func before_each() -> void:
	Game.profile = Profile.new()
	Game.profile.night_seed = SEED
	level = LevelScene.instantiate() as VoxelNight
	hero = level.get_node("Hero") as Hero
	hero.reads_player_input = false
	add_child_autofree(level)
	# Les Muets apparaissent au pas suivant.
	await get_tree().process_frame
	await get_tree().physics_frame


func _spawners() -> Array[EnemySpawner]:
	var found: Array[EnemySpawner] = []
	for node: Node in level.get_node("Foes").get_children():
		if node is EnemySpawner:
			found.append(node as EnemySpawner)
	return found


func test_la_nuit_commence_au_village_avec_la_musique_de_base() -> void:
	assert_eq(Game.progress.drums_returned, 0)
	assert_eq(Rhythm.audible_layers(), 1)
	var village: Area3D = level.get_node("Village/VillageZone") as Area3D
	# Les recouvrements de zones ne sont connus qu'après quelques pas de physique.
	for i: int in MAX_OVERLAP_FRAMES:
		if village.overlaps_body(hero):
			break
		await get_tree().physics_frame
	assert_true(village.overlaps_body(hero), "le héros part du village")


func test_le_monde_est_celui_de_la_graine_de_la_nuit() -> void:
	assert_eq(Game.profile.night_seed, SEED, "la graine reste pour les sorties suivantes")
	assert_eq(level.gen.voxel_count(), 17432)
	assert_eq(level.gen.sanctuaries.size(), 3)


func test_chaque_tambour_est_garde_par_un_grand_muet() -> void:
	assert_eq(level.drums.size(), 3)
	for i: int in level.drums.size():
		var drum: Node3D = level.drums[i]
		var guardian: EnemySpawner = drum.get(&"guardian") as EnemySpawner
		assert_eq(guardian.scene.resource_path, "res://scenes/enemies/grand_muet.tscn")
		assert_not_null(guardian.loot_scene, "le Grand Muet libéré laisse un objet")
		var altar: Vector3 = level.to_world(level.gen.sanctuaries[i])
		var flat := Vector2(drum.global_position.x - altar.x, drum.global_position.z - altar.z)
		assert_almost_eq(flat.length(), 0.0, 0.01, "le tambour est sur son autel")
		assert_gt(drum.global_position.y, 0.0, "posé en haut de l'autel")


func test_une_trentaine_de_muets_gardent_les_sanctuaires_ou_errent() -> void:
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


func test_le_village_danse_autour_du_chef() -> void:
	var villagers: Array[Node] = level.get_node("Village").find_children("*", "Villager", false, false)
	assert_eq(villagers.size(), WorldGen.DANCERS.size() + 1, "six danseurs et le Chef")
	var chief: Node = get_tree().get_first_node_in_group(&"chief")
	assert_not_null(chief)
	assert_true(chief.has_method(&"greet"), "le Chef salue quand il parle")


func test_l_objectif_mene_au_sanctuaire_puis_ramene_le_tambour() -> void:
	assert_eq(level.objective(), Vector2i(0, 1), "d'abord le premier sanctuaire")
	var boss: EnemySpawner = level.drums[0].get(&"guardian") as EnemySpawner
	var hit := HitData.new()
	hit.damage = boss.muet.health.maximum
	hit.direction = Vector3.FORWARD
	boss.muet.hurtbox.receive(hit)
	await get_tree().physics_frame
	assert_true(level.drums[0].call(&"is_available"), "le tambour sort de sa bulle")
	assert_eq(level.objective(), Vector2i(0, 1), "aller prendre le tambour libéré")
	hero.global_position = level.drums[0].global_position
	Game.pick_drum()
	assert_eq(level.objective(), Vector2i(0, -1), "le rapporter au village")
