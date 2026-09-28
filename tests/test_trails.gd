extends GutTest
## Sentiers qui serpentent (version 3.4) : la zone où l'on marche, les sentiers sinueux, les
## recoins et ce qu'ils cachent.

const LevelScene: PackedScene = preload("res://scenes/levels/expedition.tscn")

var tuning: TuningData = Tuning.data
var level: Expedition
var hero: Hero


func before_each() -> void:
	Save.path = "user://test_trails.json"
	Game.profile = Profile.create()
	Game.profile.expeditions = 1
	Game.start_on_load = false
	Game.run = null


func after_all() -> void:
	Game.profile = Profile.new()
	Game.refresh_stats()


func after_each() -> void:
	get_tree().paused = false
	Game.run = null
	Game.playing = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.path))


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


func _hit(target: Node3D) -> void:
	var hit := HitData.new()
	hit.damage = 1.0
	hit.attacker = hero
	hit.direction = Vector3.FORWARD
	(target.get_node("Hurtbox") as Hurtbox).receive(hit)


func test_la_zone_de_marche_reunit_disques_et_sentiers() -> void:
	var walk := WalkArea.new()
	walk.add_disc(Vector2.ZERO, 10.0)
	walk.add_lane(Vector2(0.0, 8.0), Vector2(0.0, 30.0), 3.0)
	assert_true(walk.contains(Vector2.ZERO))
	assert_true(walk.contains(Vector2(0.0, 25.0)), "sur le sentier")
	assert_false(walk.contains(Vector2(8.0, 25.0)), "à côté du sentier")
	assert_almost_eq(walk.depth(Vector2(0.0, 20.0)), 3.0, 0.001, "au milieu du sentier : sa demi-largeur")
	assert_almost_eq(walk.depth(Vector2(15.0, 0.0)), -5.0, 0.001, "dehors : la distance au bord")
	var edge: PackedVector2Array = walk.outline(1.0, 1.0)
	assert_eq(edge.size(), walk.outline_sizes.size(), "chaque point dit d'où il vient")
	for p: Vector2 in edge:
		assert_almost_eq(walk.depth(p), -1.0, 0.06, "à 1 u du bord")
		assert_false(absf(p.x) < 3.0 and p.y > 10.0 and p.y < 30.0, "le bord s'ouvre où le sentier débouche")
	assert_true(walk.outline_sizes.has(10.0) and walk.outline_sizes.has(3.0))


func test_un_sentier_serpente_d_un_cote_puis_de_l_autre() -> void:
	var rolls := PackedFloat32Array([0.2, 0.5, 0.9, 0.1])
	var path: PackedVector2Array = WalkArea.winding(Vector2(0.0, 10.0), Vector2.DOWN, 30.0, 3, 6.0, rolls)
	assert_eq(path.size(), 4)
	assert_eq(path[0], Vector2(0.0, 10.0), "il part d'où on le demande")
	assert_almost_eq(path[3], Vector2(0.0, 40.0), Vector2.ONE * 0.001, "et arrive dans l'axe, au bout")
	assert_lt(path[1].x * path[2].x, 0.0, "les coudes changent de côté")
	for p: Vector2 in path:
		assert_lte(absf(p.x), 6.0, "sans s'écarter plus que prévu")
	var other: PackedVector2Array = WalkArea.winding(Vector2(0.0, 10.0), Vector2.DOWN, 30.0, 3, 6.0, PackedFloat32Array([0.8, 0.5, 0.9, 0.1]))
	assert_lt(path[1].x * other[1].x, 0.0, "le premier tirage choisit le côté du premier coude")


func test_un_recoin_garde_ou_borde_de_rochers_cache_plus_souvent_du_precieux() -> void:
	var open: Dictionary[StringName, float] = Niches.weights(false, 0, true)
	var hidden: Dictionary[StringName, float] = Niches.weights(true, 0, true)
	var rocky: Dictionary[StringName, float] = Niches.weights(false, 2, true)
	assert_gt(hidden[Niches.STELE], open[Niches.STELE], "derrière un fourré : plus souvent une stèle")
	assert_gt(hidden[Niches.MUET], open[Niches.MUET], "ou un Muet doré")
	assert_lt(hidden[Niches.JARS], open[Niches.JARS], "moins souvent de simples jarres")
	assert_gt(rocky[Niches.FEATHERS], open[Niches.FEATHERS], "bordé de rochers : plus souvent un nid de plumes")
	assert_eq(Niches.weights(true, 2, false)[Niches.MUET], 0.0, "sans combat, pas de Muet caché")
	assert_eq(Niches.pick(0.0, false, 0, true), Niches.JARS)
	assert_eq(Niches.pick(0.999, false, 0, true), Niches.MUET)
	assert_ne(Niches.pick(0.999, false, 0, false), Niches.MUET)


func test_une_clairiere_a_son_sentier_d_entree_ses_sorties_et_ses_recoins() -> void:
	var gen := WorldGen.new()
	var radius: float = tuning.room_radius_max
	var niches: int = 0
	for seed_value: int in 12:
		gen.generate_room(seed_value, radius, PackedFloat32Array([-0.28, 0.28]), &"clearing")
		var start: Vector2 = gen.entry_path[gen.entry_path.size() - 1]
		assert_lt(gen.entry_path[0].length(), radius, "le sentier part de l'arène")
		assert_gt(start.y, radius + WorldGen.TRAIL_LENGTH * 0.8, "et serpente loin vers le sud")
		assert_true(gen.walk.contains(start, WorldGen.TRAIL_HALF * 0.5), "le héros part au milieu du sentier")
		assert_eq(gen.exit_paths.size(), 2, "un sentier par sortie")
		for path: PackedVector2Array in gen.exit_paths:
			assert_lt(path[path.size() - 1].y, -radius, "vers le nord")
		for niche: Dictionary in gen.niches:
			assert_true(gen.walk.contains(niche[&"center"], WorldGen.NICHE_R * 0.5), "on peut entrer dans un recoin")
			assert_true(Niches.KINDS.has(niche[&"reward"]))
		niches += gen.niches.size()
		assert_ne(gen.landmark, Vector2.INF, "un repère visible de loin")
		assert_lt(gen.walk.depth(gen.landmark), -WorldGen.LANDMARK_CLEAR + 0.01, "hors des chemins")
	assert_gt(niches, 12, "des recoins presque partout")
	var again := WorldGen.new()
	again.generate_room(3, radius, PackedFloat32Array([-0.28, 0.28]), &"clearing")
	gen.generate_room(3, radius, PackedFloat32Array([-0.28, 0.28]), &"clearing")
	assert_eq(again.entry_path, gen.entry_path, "même graine, même sentier")
	assert_eq(again.niches.size(), gen.niches.size())


func test_on_marche_sur_les_sentiers_sans_buter_sur_le_decor() -> void:
	var hero_r: float = tuning.hero_radius / tuning.voxel_unit
	for kind: StringName in WorldGen.ROOM_KINDS + [&"arena"] as Array[StringName]:
		var gen := WorldGen.new()
		gen.generate_room(21, tuning.room_radius_max, PackedFloat32Array([-0.28, 0.28]), kind)
		var paths: Array[PackedVector2Array] = [gen.entry_path]
		paths.append_array(gen.exit_paths)
		for path: PackedVector2Array in paths:
			for i: int in range(1, path.size()):
				for k: int in 10:
					var p: Vector2 = path[i - 1].lerp(path[i], k / 10.0)
					if p.length() < gen._arena_r:
						continue
					for s: WorldGen.Solid in gen.solids:
						assert_gt(p.distance_to(Vector2(s.x, s.z)), s.r + hero_r, "rien sur le sentier en %s (%s)" % [p, kind])


func test_le_village_garde_son_cercle() -> void:
	var gen := WorldGen.new()
	gen.generate_room(1, tuning.room_radius, PackedFloat32Array([0.0]), &"village")
	assert_true(gen.walk.is_empty())
	assert_true(gen.fence.is_empty(), "le mur rond du village")
	assert_true(gen.entry_path.is_empty())


func test_les_boss_n_ont_ni_recoins_ni_sorties() -> void:
	var gen := WorldGen.new()
	gen.generate_room(1, tuning.room_radius_max, PackedFloat32Array([0.0]), &"arena")
	assert_true(gen.niches.is_empty())
	assert_true(gen.exit_paths.is_empty())
	assert_false(gen.entry_path.is_empty(), "on y arrive quand même par un sentier")


func test_on_arrive_par_le_sentier_et_les_muets_attendent_dans_l_arene() -> void:
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	var start: Vector2 = level.gen.entry_path[level.gen.entry_path.size() - 1] * tuning.voxel_unit
	assert_almost_eq(Vector2(hero.global_position.x, hero.global_position.z), start, Vector2.ONE * 0.01, "au bout du sentier")
	assert_eq(level.current_goal()[&"point"], Vector3.ZERO, "le repère montre l'arène")
	await get_tree().create_timer(tuning.room_wave_delay * 2.0).timeout
	assert_true(_muets().is_empty(), "sur le sentier, tout est calme")
	hero.global_position = Vector3(0.0, 0.0, tuning.room_radius_min * tuning.voxel_unit * 0.5)
	for i: int in 200:
		await get_tree().physics_frame
		if not _muets().is_empty():
			break
	assert_false(_muets().is_empty(), "dans l'arène, la vague arrive")
	assert_false(level.current_goal().has(&"point"))


func test_un_recoin_cache_derriere_un_fourre_une_stele_qui_offre_un_don() -> void:
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	for node: Node in level.get_node("Pickups").get_children():
		node.free()
	# (Pas de vague pendant ce test : le recoin est posé dans l'arène.)
	level.set(&"_arena_waiting", false)
	var center := Vector2(0.0, -20.0)
	level.gen.niches.assign([{&"center": center, &"mouth": Vector2(0.0, -12.0), &"dir": Vector2.UP, &"hidden": true, &"rocks": 0, &"reward": Niches.STELE}])
	level.call(&"_place_niches")
	var thickets: Array[Node] = level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n is Breakable and n.kind == Breakable.THICKET)
	assert_eq(thickets.size(), 1, "un fourré garde l'entrée")
	for i: int in tuning.thicket_hits:
		_hit(thickets[0] as Node3D)
	assert_true((thickets[0] as Breakable).is_broken(), "tranché en %d coups" % tuning.thicket_hits)
	var steles: Array[Node] = get_tree().get_nodes_in_group(&"steles")
	assert_eq(steles.size(), 1)
	var ranks: int = Game.run.boon_ranks()
	hero.global_position = Vector3(center.x, 0.0, center.y + 2.0) * tuning.voxel_unit
	await get_tree().physics_frame
	await get_tree().physics_frame
	var screen: BoonScreen = level.get_node("BoonScreen") as BoonScreen
	assert_true(screen.is_open(), "la stèle s'éveille")
	assert_eq(screen.get_node("%Cards").get_child_count(), tuning.stele_offer)
	(screen.get_node("%Cards").get_child(0) as Button).pressed.emit()
	assert_gt(Game.run.boon_ranks(), ranks, "un don de plus")
	var gates: Array[Node] = level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n is ExitGate)
	assert_true(gates.is_empty(), "la clairière n'est pas finie pour autant")
	assert_true((steles[0] as SpiritStele).is_used(), "une seule fois")


func test_un_nid_de_plumes_d_or_au_fond_d_un_recoin() -> void:
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	for node: Node in level.get_node("Pickups").get_children():
		node.free()
	# (Pas de vague pendant ce test : le recoin est posé dans l'arène.)
	level.set(&"_arena_waiting", false)
	var center := Vector2(0.0, -20.0)
	level.gen.niches.assign([{&"center": center, &"mouth": Vector2(0.0, -12.0), &"dir": Vector2.UP, &"hidden": false, &"rocks": 2, &"reward": Niches.FEATHERS}])
	level.call(&"_place_niches")
	var nests: Array[Node] = level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n is Breakable and n.kind == Breakable.NEST)
	assert_eq(nests.size(), 1)
	var feathers: int = Game.run.feathers
	_hit(nests[0] as Node3D)
	assert_eq(Game.run.feathers, feathers + tuning.nest_feathers + tuning.nest_feathers_per_room * Game.run.room)


func test_un_muet_dore_dort_dans_un_recoin_et_s_eveille_quand_on_y_entre() -> void:
	await _open_level()
	level.start_sortie()
	hero.reads_player_input = false
	# (Pas de vague pendant ce test : le recoin est posé dans l'arène.)
	level.set(&"_arena_waiting", false)
	var center := Vector2(0.0, -20.0)
	level.gen.niches.assign([{&"center": center, &"mouth": Vector2(0.0, -12.0), &"dir": Vector2.UP, &"hidden": true, &"rocks": 0, &"reward": Niches.MUET}])
	level.call(&"_place_niches")
	for i: int in 5:
		await get_tree().physics_frame
	assert_true(_muets().is_empty(), "il dort tant qu'on n'entre pas")
	hero.global_position = Vector3(center.x, 0.0, center.y + 2.0) * tuning.voxel_unit
	for i: int in 30:
		await get_tree().physics_frame
		if not _muets().is_empty():
			break
	assert_eq(_muets().size(), 1, "il s'éveille")
	var muet: Muet = _muets()[0]
	assert_eq(muet.elite, Muet.ELITE_GOLDEN)
	var feathers: int = Game.run.feathers
	level.on_elite_freed(muet)
	assert_eq(Game.run.feathers, feathers + tuning.elite_golden_feathers, "de l'or")
	assert_false(level.get(&"_elite_boon"), "mais pas de don d'élite")
