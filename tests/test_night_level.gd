extends GutTest
## Niveau de la nuit 1 : les pièces sont reliées entre elles, les coffres et perchoirs sont
## atteignables, et tomber dans le ravin ramène au village.

const LevelScene: PackedScene = preload("res://scenes/levels/night_1.tscn")
const Notebook: NotebookData = preload("res://data/notebook.tres")
## Marge sur la hauteur de saut : une marche de perchoir ne demande pas un saut parfait.
const CLIMB_MARGIN := 0.8
## Écart maximal entre les bords de deux perchoirs voisins (m).
const MAX_PERCH_GAP := 1.5
## Pas de physique attendus au plus pour qu'une zone voie le héros.
const MAX_OVERLAP_FRAMES := 30

var tuning: TuningData = Tuning.data
var level: Node3D
var hero: Hero


func before_each() -> void:
	level = LevelScene.instantiate() as Node3D
	hero = level.get_node("Hero") as Hero
	hero.reads_player_input = false
	add_child_autofree(level)
	await get_tree().physics_frame


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


func test_le_tambour_du_sanctuaire_est_garde_par_le_grand_muet() -> void:
	var drum: Node = level.get_node("Sanctuary/SanctuaryDrum")
	var guardian: Node = drum.get(&"guardian") as Node
	assert_eq(guardian, level.get_node("Sanctuary/GrandMuet"))
	var boss: PackedScene = guardian.get(&"scene") as PackedScene
	assert_eq(boss.resource_path, "res://scenes/enemies/grand_muet.tscn")
	assert_not_null(guardian.get(&"loot_scene"), "le Grand Muet libéré laisse un objet")


func test_le_cercle_a_quatre_gongs_et_une_melodie_jouable() -> void:
	var circle: Node = level.get_node("GongCircle")
	var gongs: Array = circle.get(&"gongs")
	var indices: Array[int] = []
	for gong: Gong in gongs:
		indices.append(gong.index)
	indices.sort()
	assert_eq(indices, [0, 1, 2, 3])
	for note: int in circle.get(&"melody") as PackedInt32Array:
		assert_has(indices, note)
	var chest: Node = circle.get(&"chest") as Node
	assert_true(chest.get(&"hidden"), "le coffre des gongs est caché")


func test_chaque_coffre_donne_une_page_differente_du_carnet() -> void:
	var pages: Array[int] = []
	for chest: Node in [level.get_node("GongCircle/Chest"), level.get_node("PillarChest")]:
		var page: int = chest.get(&"page")
		assert_between(page, 1, Notebook.pages.size())
		assert_does_not_have(pages, page)
		pages.append(page)


func test_les_perchoirs_menent_au_coffre_du_pilier() -> void:
	var climb: float = (pow(tuning.jump_speed, 2.0) + pow(tuning.double_jump_speed, 2.0)) / (2.0 * tuning.gravity_rise_held)
	var steps: Array[CSGCylinder3D] = []
	for name: String in ["Perch1", "Perch2", "Perch3", "Perch4", "ChestPillar"]:
		steps.append(level.get_node("Terrain/" + name) as CSGCylinder3D)
	var previous_top: float = 0.0
	for i: int in steps.size():
		var top: float = steps[i].position.y + steps[i].height / 2.0
		assert_lt(top - previous_top, climb * CLIMB_MARGIN, "marche vers %s" % steps[i].name)
		previous_top = top
		if i > 0:
			var a: Vector3 = steps[i - 1].position
			var b: Vector3 = steps[i].position
			var gap: float = Vector2(b.x - a.x, b.z - a.z).length() - steps[i - 1].radius - steps[i].radius
			assert_lt(gap, MAX_PERCH_GAP, "écart avant %s" % steps[i].name)
	var chest: Node3D = level.get_node("PillarChest") as Node3D
	assert_almost_eq(chest.position.y, previous_top, 0.01, "le coffre est posé sur le pilier")


func test_tomber_dans_le_ravin_ramene_au_village() -> void:
	var spawn: Vector3 = hero.global_position
	var bridge: CSGBox3D = level.get_node("Terrain/Bridge") as CSGBox3D
	var respawns: Array[bool] = []
	hero.respawned.connect(func() -> void: respawns.append(true))
	# Au-dessus du vide, à côté du pont.
	hero.global_position = bridge.position + Vector3(bridge.size.x * 2.0, 0.5, 0.0)
	hero.reset_physics_interpolation()
	for i: int in 180:
		await get_tree().physics_frame
		if not respawns.is_empty():
			break
	assert_eq(respawns.size(), 1, "la chute renvoie au village")
	assert_almost_eq(hero.global_position.x, spawn.x, 0.2)
	assert_almost_eq(hero.global_position.z, spawn.z, 0.2)
	var rig: Node3D = level.get_node("CameraRig") as Node3D
	var feet: Vector3 = Vector3(rig.global_position.x, 0.0, rig.global_position.z)
	assert_lt(feet.distance_to(Vector3(spawn.x, 0.0, spawn.z)), 1.5, "la caméra revient tout de suite")
