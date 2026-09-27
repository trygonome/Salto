extends "res://tests/hero_test_base.gd"
## Donjons 2.6 : régions (ordre, ouverture, formes de clairière, gardien), eau qui ralentit (sauf
## sur les ponts), pièges au tempo (annonce puis frappe, héros comme Muets), tambour de guerre,
## jarres et rocher fêlé.

const Hopper: PackedScene = preload("res://scenes/enemies/hopper.tscn")
const TelegraphScene: PackedScene = preload("res://scenes/fx/telegraph.tscn")
const DrumModel: PackedScene = preload("res://scenes/levels/props/drum_model.tscn")
const PropMaterial: Material = preload("res://scenes/world/voxel_actor.tres")


func _add_muet(at: Vector3) -> Muet:
	var muet: Muet = Hopper.instantiate() as Muet
	muet.position = at
	world.add_child(muet)
	await _step(2)
	return muet


func _hero_hit(target: Hurtbox) -> HitData:
	var hit := HitData.new()
	hit.attacker = hero
	hit.target = target
	hit.damage = 5.0
	hit.move = &"martelo"
	hit.direction = Vector3.FORWARD
	return hit


func test_les_regions_s_ouvrent_l_une_apres_l_autre() -> void:
	assert_eq(Regions.unlocked([] as Array[StringName]), [Regions.UNDERGROWTH] as Array[StringName], "au début : le Sous-bois")
	assert_eq(Regions.unlocked([Regions.UNDERGROWTH] as Array[StringName]), [Regions.UNDERGROWTH, Regions.SUNKEN] as Array[StringName])
	assert_eq(Regions.unlocked([Regions.UNDERGROWTH, Regions.SUNKEN] as Array[StringName]).size(), 3)
	assert_eq(Regions.next(Regions.CANOPY), &"", "la dernière")
	for region: StringName in Regions.IDS:
		assert_true(GameTexts.REGION_NAMES.has(region) and GameTexts.GUARDIAN_NAMES.has(region), String(region))
		assert_true(Regions.KINDS.has(region) and Regions.GRASS.has(region) and Regions.FOG_HUE.has(region))
		assert_true(Rhythm.REGION_LAYERS.has(region) or region == Regions.UNDERGROWTH, "sa couche de musique")


func test_chaque_region_a_ses_clairieres() -> void:
	var seen: Dictionary[StringName, bool] = {}
	for seed_value: int in 40:
		var run := RunState.new(seed_value, 7, Regions.SUNKEN)
		run.room = 1
		run.reward = RunState.BOON
		var kind: StringName = run.room_kind()
		assert_true(Regions.KINDS[Regions.SUNKEN].has(kind), "une forme des Ruines englouties")
		seen[kind] = true
	assert_true(seen.has(&"flooded"), "des rivières à franchir")
	var rest := RunState.new(3, 7, Regions.CANOPY)
	rest.room = 2
	rest.reward = RunState.REST
	assert_eq(rest.room_kind(), &"clearing", "un repos : une clairière calme")
	assert_true(RunState.REWARDS.has(RunState.REST) and RunState.REWARDS.has(RunState.TREASURE))


func test_la_riviere_ralentit_sauf_sur_les_ponts() -> void:
	var gen := WorldGen.new()
	gen.generate_room(5, tuning.room_radius_max, PackedFloat32Array([0.0, PI]), &"flooded")
	assert_false(gen.waters.is_empty(), "une rivière")
	assert_false(gen.bridges.is_empty(), "et des ponts")
	var water: Rect2 = gen.waters[0]
	var bridge: Rect2 = gen.bridges[0]
	assert_true(gen.water_at(Vector2(water.get_center().x, water.get_center().y + water.size.y * 0.3)) or gen.water_at(water.position + water.size * 0.1), "dans l'eau")
	assert_false(gen.water_at(bridge.get_center()), "sur le pont, on marche")
	assert_lt(gen.voxel_count(), 20000)
	var heights := WorldGen.new()
	heights.generate_room(5, tuning.room_radius_max, PackedFloat32Array([0.0, PI]), &"heights")
	assert_false(heights.boxes.is_empty(), "des plateformes")
	assert_true(heights.traps.any(func(t: Dictionary) -> bool: return t[&"kind"] == BeatTrap.WHIP), "des lianes fouets")
	assert_lt(heights.voxel_count(), 20000)


func test_les_epines_s_annoncent_puis_frappent_au_temps() -> void:
	await _spawn_on_flat_ground()
	var trap := BeatTrap.new()
	trap.kind = BeatTrap.SPIKES
	trap.telegraph_scene = TelegraphScene
	trap.material = PropMaterial
	trap.position = hero.global_position
	world.add_child(trap)
	var muet: Muet = await _add_muet(hero.global_position + Vector3(tuning.trap_spike_radius * 0.5, 0.0, 0.0))
	muet.set_physics_process(false)
	var far: Muet = await _add_muet(hero.global_position + Vector3(0.0, 0.0, -tuning.trap_spike_radius - 3.0))
	far.set_physics_process(false)
	assert_true(trap.covers(hero.global_position))
	assert_false(trap.covers(far.global_position))
	var period: int = tuning.trap_spike_period
	# (Le sautillant a pu toucher le héros en arrivant : on oublie ce coup et son invulnérabilité.)
	hero.health.restore()
	hero.hurtbox.can_be_hit = true
	trap.receive_beat(period - 1)
	assert_eq(hero.health.current, hero.health.maximum, "le temps d'avant : l'annonce, sans dégâts")
	assert_eq(world.get_children().filter(func(n: Node) -> bool: return n is Telegraph).size(), 1, "une annonce au sol")
	trap.receive_beat(period)
	assert_almost_eq(hero.health.current, hero.health.maximum - tuning.trap_damage, 0.01, "sur le temps : les épines")
	assert_lt(muet.health.current, muet.health.maximum, "les Muets aussi")
	assert_eq(far.health.current, far.health.maximum, "pas plus loin")


func test_la_liane_fouet_balaie_sa_ligne() -> void:
	var trap := BeatTrap.new()
	trap.kind = BeatTrap.WHIP
	trap.angle = PI / 2.0
	add_child_autofree(trap)
	var east: Vector3 = trap.whip_direction()
	assert_almost_eq(east.x, 1.0, 0.001, "vers l'est")
	assert_true(trap.covers(east * tuning.trap_whip_length * 0.5))
	assert_false(trap.covers(-east * 1.0), "derrière le pied")
	assert_false(trap.covers(east * 2.0 + Vector3(0.0, 0.0, tuning.trap_whip_width)), "à côté de la ligne")


func test_le_tambour_de_guerre_etourdit_les_muets_autour() -> void:
	await _spawn_on_flat_ground()
	var drum := WarDrum.new()
	drum.model_scene = DrumModel
	drum.position = hero.global_position + Vector3(0.0, 0.0, -2.0)
	world.add_child(drum)
	var near: Muet = await _add_muet(drum.position + Vector3(tuning.war_drum_reach * 0.5, 0.0, 0.0))
	var far: Muet = await _add_muet(drum.position + Vector3(tuning.war_drum_reach + 3.0, 0.0, 0.0))
	var groove: float = hero.groove.value
	assert_true(drum.is_ready())
	(drum.get_node("Hurtbox") as Hurtbox).receive(_hero_hit(drum.get_node("Hurtbox") as Hurtbox))
	assert_false(drum.is_ready(), "il se recharge")
	assert_eq(near.state_machine.current.name, &"Stunned", "l'onde étourdit")
	assert_lt(near.poise, near.poise_max, "et ébranle")
	assert_ne(far.state_machine.current.name, &"Stunned", "pas trop loin")
	assert_gt(hero.groove.value, groove, "le groove monte")


func test_une_jarre_se_brise_et_le_rocher_fele_cache_un_passage() -> void:
	await _spawn_on_flat_ground()
	Game.run = RunState.new(1, 7)
	var jar := Breakable.new()
	jar.kind = Breakable.JAR
	jar.material = PropMaterial
	jar.rng.seed = 1
	jar.position = hero.global_position + Vector3(0.0, 0.0, -1.5)
	world.add_child(jar)
	var feathers: int = Game.run.feathers
	var hp: float = hero.health.current
	hero.health.current = hp * 0.5
	(jar.get_node("Hurtbox") as Hurtbox).receive(_hero_hit(jar.get_node("Hurtbox") as Hurtbox))
	assert_true(jar.is_broken(), "un coup suffit")
	assert_true(Game.run.feathers > feathers or hero.health.current > hp * 0.5, "des plumes d'or ou un peu de soin")
	var boulder := Breakable.new()
	boulder.kind = Breakable.BOULDER
	boulder.material = PropMaterial
	boulder.position = hero.global_position + Vector3(3.0, 0.0, 0.0)
	world.add_child(boulder)
	var revealed: Array[Vector3] = []
	boulder.revealed.connect(func(at: Vector3) -> void: revealed.append(at))
	var box: Hurtbox = boulder.get_node("Hurtbox") as Hurtbox
	for i: int in tuning.boulder_hits - 1:
		box.receive(_hero_hit(box))
	assert_false(boulder.is_broken(), "il résiste")
	box.receive(_hero_hit(box))
	assert_true(boulder.is_broken())
	assert_eq(revealed.size(), 1, "un passage secret")
	Game.run = null
