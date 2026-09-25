extends "res://tests/hero_test_base.gd"
## Éléments du niveau avec le héros : tambour à rapporter, champignon-trampoline, coffre,
## cercle des gongs, soin au village.

const Drum: PackedScene = preload("res://scenes/levels/props/drum.tscn")
const DrumStand: PackedScene = preload("res://scenes/levels/props/drum_stand.tscn")
const Mushroom: PackedScene = preload("res://scenes/levels/props/mushroom.tscn")
const Chest: PackedScene = preload("res://scenes/levels/props/chest.tscn")
const GongScene: PackedScene = preload("res://scenes/levels/props/gong.tscn")
const Spawner: GDScript = preload("res://scripts/levels/enemy_spawner.gd")
const GrandMuet: PackedScene = preload("res://scenes/enemies/grand_muet.tscn")


func before_each() -> void:
	super.before_each()
	Game.start_night()


func _walk_to(point: Vector3) -> void:
	for i: int in MAX_FRAMES:
		var flat := Vector3(point.x - hero.global_position.x, 0.0, point.z - hero.global_position.z)
		if flat.length() < 0.3:
			hero.input_move = Vector2.ZERO
			return
		hero.input_move = Vector2(flat.x, flat.z).normalized()
		await _step(1)
	hero.input_move = Vector2.ZERO


func test_le_tambour_se_libere_avec_son_gardien_et_se_rapporte() -> void:
	await _spawn_on_flat_ground()
	var spawner: Marker3D = Marker3D.new()
	spawner.set_script(Spawner)
	spawner.set(&"scene", GrandMuet)
	spawner.position = Vector3(8.0, 0.0, -8.0)
	world.add_child(spawner)
	var drum: Node3D = Drum.instantiate() as Node3D
	drum.set(&"guardian", spawner)
	drum.position = Vector3(0.0, 0.0, -3.0)
	world.add_child(drum)
	var stand: Node3D = DrumStand.instantiate() as Node3D
	stand.position = Vector3(0.0, 0.0, 4.0)
	world.add_child(stand)
	await _step(2)
	await _walk_to(drum.global_position)
	await _step(10)
	assert_false(Game.progress.carrying_drum, "enfermé dans sa bulle tant que le gardien n'est pas libéré")
	var boss: Muet = world.find_children("*", "Muet", true, false)[0] as Muet
	var hit := HitData.new()
	hit.damage = boss.health.maximum
	hit.direction = Vector3.FORWARD
	boss.hurtbox.receive(hit)
	await _step(2)
	# Le héros sort de la zone du tambour puis y revient.
	await _walk_to(drum.global_position + Vector3.BACK * 2.5)
	await _walk_to(drum.global_position)
	await _step(5)
	assert_true(Game.progress.carrying_drum, "le héros emporte le tambour")
	var layers: Array[int] = []
	Game.drum_returned.connect(func(count: int) -> void: layers.append(count))
	await _walk_to(stand.global_position)
	await _step(5)
	assert_eq(layers, [1] as Array[int])
	assert_true(Game.progress.is_complete(), "la tranche verticale n'a qu'un tambour")


func test_tomber_ramene_le_tambour_a_son_sanctuaire() -> void:
	await _spawn_on_flat_ground()
	Game.pick_drum()
	var dropped: Array[bool] = []
	Game.drum_dropped.connect(func() -> void: dropped.append(true))
	hero.global_position = Vector3(0.0, -tuning.respawn_fall_depth - 1.0, 0.0)
	await _step(2)
	assert_eq(dropped, [true] as Array[bool])
	assert_false(Game.progress.carrying_drum)


func test_le_champignon_relance_tres_haut() -> void:
	await _spawn_on_flat_ground()
	var mushroom: Node3D = Mushroom.instantiate() as Node3D
	mushroom.position = Vector3(0.0, 0.0, -2.0)
	world.add_child(mushroom)
	hero.global_position = Vector3(0.0, 3.0, -2.0)
	await _wait_for_state(&"Air")
	var apex: float = hero.global_position.y
	var bounced: bool = false
	for i: int in MAX_FRAMES:
		await _step(1)
		if hero.velocity.y > 0.0 and not bounced:
			bounced = true
			assert_eq(hero.jumps_used, 1, "le salto reste possible")
			# On s'écarte du chapeau pour ne pas rebondir indéfiniment.
			hero.input_move = Vector2.RIGHT
		apex = maxf(apex, hero.global_position.y)
		if bounced and hero.velocity.y < 0.0:
			break
	assert_true(bounced, "le héros rebondit")
	assert_gt(apex, 1.3 + _expected_apex(tuning.mushroom_bounce_speed, tuning.gravity_rise_released) * 0.8, "rebond bien plus haut qu'un saut")


func test_le_coffre_donne_une_page_et_un_objet() -> void:
	await _spawn_on_flat_ground()
	var chest: Node3D = Chest.instantiate() as Node3D
	chest.set(&"page", 5)
	chest.position = Vector3(0.0, 0.0, -2.0)
	world.add_child(chest)
	await _walk_to(chest.global_position + Vector3.BACK * 0.6)
	await _step(10)
	assert_eq(Game.progress.pages, [5] as Array[int])
	var loot: Array[Node] = world.find_children("LootDrop*", "Node3D", true, false)
	assert_eq(loot.size(), 1, "un objet jaillit")
	await _step(40)
	await _walk_to(chest.global_position + Vector3.RIGHT * 0.9)
	await _walk_to(chest.global_position + Vector3.BACK * 0.6)
	await _step(10)
	assert_eq(Game.progress.items.size(), 1, "l'objet est ramassé")


func test_le_village_soigne() -> void:
	await _spawn_on_flat_ground()
	var zone := Area3D.new()
	zone.set_script(load("res://scripts/levels/props/village_zone.gd"))
	zone.collision_layer = 0
	zone.collision_mask = 2
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10.0, 4.0, 10.0)
	shape.shape = box
	zone.add_child(shape)
	world.add_child(zone)
	hero.health.current = hero.health.maximum / 2.0
	var before: float = hero.health.current
	await _step(Engine.physics_ticks_per_second)
	assert_almost_eq(hero.health.current - before, tuning.village_heal_rate, 0.5)


func _gong_circle(melody: PackedInt32Array) -> Node3D:
	var circle := Node3D.new()
	circle.set_script(load("res://scripts/levels/props/gong_circle.gd"))
	var zone := Area3D.new()
	zone.name = "Zone"
	zone.collision_layer = 0
	zone.collision_mask = 2
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 4.0
	cylinder.height = 3.0
	shape.shape = cylinder
	zone.add_child(shape)
	circle.add_child(zone)
	var gongs: Array[Gong] = []
	for i: int in 3:
		var gong: Gong = GongScene.instantiate() as Gong
		gong.index = i
		gong.position = Vector3.FORWARD.rotated(Vector3.UP, TAU * i / 3.0) * 3.0
		circle.add_child(gong)
		gongs.append(gong)
	var chest: Node3D = Chest.instantiate() as Node3D
	chest.set(&"hidden", true)
	chest.set(&"page", 5)
	circle.add_child(chest)
	circle.set(&"melody", melody)
	circle.set(&"gongs", gongs)
	circle.set(&"chest", chest)
	circle.set(&"wait_beats", 1)
	world.add_child(circle)
	return circle


func _strike(gong: Gong) -> void:
	var hit := HitData.new()
	hit.direction = Vector3.FORWARD
	(gong.get_node(^"Hurtbox") as Hurtbox).receive(hit)


func test_rejouer_la_melodie_des_gongs_fait_surgir_le_coffre() -> void:
	await _spawn_on_flat_ground()
	var circle: Node3D = _gong_circle(PackedInt32Array([2, 0, 1]))
	var gongs: Array[Gong] = circle.get(&"gongs")
	var chest: Node3D = circle.get(&"chest")
	await _step(3)
	assert_false(chest.visible, "le coffre est caché")
	# Démonstration : un temps d'attente, puis une note par temps.
	for beat: int in 4:
		circle.call(&"receive_beat", beat)
	assert_eq(circle.get(&"phase"), 2, "à l'écoute du joueur")
	_strike(gongs[2])
	_strike(gongs[1])
	assert_eq(circle.get(&"phase"), 0, "une erreur fait tout recommencer")
	for beat: int in 4:
		circle.call(&"receive_beat", beat)
	for index: int in [2, 0, 1]:
		_strike(gongs[index])
	assert_eq(circle.get(&"phase"), 3, "mélodie rejouée")
	assert_true(chest.visible, "le coffre surgit")
