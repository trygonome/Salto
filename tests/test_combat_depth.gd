extends "res://tests/hero_test_base.gd"
## Combat 2.3 : l'équilibre des Muets (il se brise, ils chancellent, le coup de grâce les libère),
## la projection (contre un obstacle, contre un autre Muet), le coup chargé (Frappe maintenue),
## la garde qui cède, la riposte après une esquive parfaite.

const Hopper: PackedScene = preload("res://scenes/enemies/hopper.tscn")
const Charger: PackedScene = preload("res://scenes/enemies/charger.tscn")
const Shielder: PackedScene = preload("res://scenes/enemies/shielder.tscn")
const GrandMuet: PackedScene = preload("res://scenes/enemies/grand_muet.tscn")


func _add_muet(scene: PackedScene, at: Vector3) -> Muet:
	var muet: Muet = scene.instantiate() as Muet
	muet.position = at
	world.add_child(muet)
	await _step(2)
	return muet


func _hit(target: Muet, damage: float, move: StringName, poise: float, launch: float = 0.0) -> HitData:
	var hit := HitData.new()
	hit.attacker = hero
	hit.damage = damage
	hit.move = move
	hit.poise = poise
	hit.launch = launch
	hit.power = hero.stats.attack
	var flat: Vector3 = target.global_position - hero.global_position
	flat.y = 0.0
	hit.direction = flat.normalized()
	hit.point = target.hurtbox.center()
	return hit


func _wait_until(condition: Callable) -> bool:
	for i: int in MAX_FRAMES:
		if condition.call():
			return true
		await _step(1)
	return false


func test_les_regles_de_l_equilibre_et_de_la_charge() -> void:
	assert_almost_eq(EnemyMath.max_poise(20.0, 0.15, 2), 26.0, 0.001, "plus fort plus loin")
	assert_eq(EnemyMath.recovered_poise(5.0, 20.0, 0.5, 1.4, 0.35, 0.1), 5.0, "pas tout de suite")
	assert_almost_eq(EnemyMath.recovered_poise(5.0, 20.0, 1.5, 1.4, 0.35, 0.1), 5.7, 0.001, "puis il revient")
	assert_eq(EnemyMath.recovered_poise(19.9, 20.0, 5.0, 1.4, 0.35, 1.0), 20.0, "sans dépasser")
	assert_gt(EnemyMath.knockback_speed(1.0, 1.0, tuning), EnemyMath.knockback_speed(0.0, 1.0, tuning), "projeté plus vite")
	assert_true(EnemyMath.is_launched(1.0, 1.0, tuning))
	assert_false(EnemyMath.is_launched(1.0, tuning.charger_knockback_factor, tuning), "le cornu est lourd")
	for move: StringName in [&"charged", &"grace", &"riposte", &"impact"]:
		assert_true(EnemyMath.breaks_guard(move), String(move))
	assert_false(EnemyMath.breaks_guard(&"martelo"))
	assert_eq(CombatMath.charge_level(0.0, tuning), 0.0)
	assert_eq(CombatMath.charge_level(tuning.charge_full_time * 2.0, tuning), 1.0)
	assert_eq(CombatMath.charge_multiplier(1.0, tuning), tuning.charge_max_multiplier)
	assert_almost_eq(CombatMath.lunge_to(4.0, 0.5, 1.0, 6.0), 3.0, 0.001)
	assert_eq(CombatMath.lunge_to(0.5, 0.5, 1.0, 6.0), 0.0, "déjà au contact : pas de recul")


func test_l_equilibre_se_brise_le_muet_chancelle_puis_se_redresse() -> void:
	await _spawn_on_flat_ground()
	var charger: Muet = await _add_muet(Charger, Vector3(0.0, 0.0, -2.0))
	assert_eq(charger.poise, charger.poise_max)
	charger.hurtbox.receive(_hit(charger, 1.0, &"martelo", charger.poise_max * 0.5))
	assert_false(charger.staggered, "à moitié : il tient")
	assert_eq(charger.state_machine.current.name, &"Hop")
	charger.hurtbox.receive(_hit(charger, 1.0, &"martelo", charger.poise_max * 0.6))
	assert_true(charger.staggered, "brisé : il chancelle")
	assert_eq(charger.state_machine.current.name, &"Stunned")
	assert_gte(charger.hurtbox.damage_taken_multiplier, tuning.stagger_damage_multiplier, "plus fragile")
	assert_true(charger.can_receive_grace())
	var back: bool = await _wait_until(func() -> bool: return not charger.staggered)
	assert_true(back, "il se redresse")
	assert_eq(charger.poise, charger.poise_max, "l'équilibre retrouvé")


func test_sans_coup_l_equilibre_revient() -> void:
	await _spawn_on_flat_ground()
	var charger: Muet = await _add_muet(Charger, Vector3(0.0, 0.0, -4.0))
	charger.hurtbox.receive(_hit(charger, 1.0, &"martelo", charger.poise_max * 0.5))
	var dented: float = charger.poise
	await _step(roundi(tuning.poise_recover_delay * 0.5 * Engine.physics_ticks_per_second))
	assert_eq(charger.poise, dented, "pas tout de suite")
	await _step(roundi((tuning.poise_recover_delay + 1.0) * Engine.physics_ticks_per_second))
	assert_gt(charger.poise, dented, "puis il revient")


func test_le_coup_de_grace_libere_le_muet_qui_chancelle() -> void:
	await _spawn_on_flat_ground()
	var hopper: Muet = await _add_muet(Charger, Vector3(0.0, 0.0, -1.8))
	hopper.hurtbox.receive(_hit(hopper, 1.0, &"martelo", hopper.poise_max))
	assert_true(hopper.staggered)
	assert_eq(hero.grace_target(), hopper, "à portée")
	var groove: float = hero.groove.value
	hero.press(&"attack")
	await _wait_for_state(&"Attack")
	assert_eq((hero.state_machine.current as Node).get(&"attack").id, &"grace")
	var freed: bool = await _wait_until(func() -> bool: return hopper.is_freed())
	assert_true(freed, "le coup de grâce le libère")
	assert_gt(hero.groove.value, groove, "le groove monte")


func test_le_grand_muet_encaisse_un_grand_coup_de_grace() -> void:
	await _spawn_on_flat_ground()
	var boss: Muet = await _add_muet(GrandMuet, Vector3(0.0, 0.0, -2.0))
	boss.hurtbox.receive(_hit(boss, 1.0, &"martelo", boss.poise_max))
	assert_true(boss.staggered, "même le Grand Muet chancelle")
	var before: float = boss.health.current
	hero.press(&"attack")
	await _wait_until(func() -> bool: return boss.health.current < before)
	assert_false(boss.is_freed(), "il n'est pas libéré d'un coup")
	assert_gte(before - boss.health.current, hero.stats.attack * tuning.grace_boss_damage, "mais le coup est grand")


func test_projete_contre_un_obstacle_il_se_blesse() -> void:
	await _spawn_on_flat_ground()
	_add_block(Vector3(4.0, 2.0, 0.4), Vector3(0.0, 1.0, -3.2))
	var hopper: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -1.6))
	hopper.hurtbox.receive(_hit(hopper, 1.0, &"armada", 0.0, 1.5))
	var after_hit: float = hopper.health.current
	var hit_wall: bool = await _wait_until(func() -> bool: return hopper.health.current < after_hit)
	assert_true(hit_wall, "le choc contre l'obstacle blesse")
	assert_almost_eq(after_hit - hopper.health.current, hero.stats.attack * tuning.impact_damage, 0.01)
	assert_eq(hopper.state_machine.current.name, &"Stunned", "sonné")


func test_un_muet_projete_en_bouscule_un_autre() -> void:
	await _spawn_on_flat_ground()
	var first: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -1.4))
	var second: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -2.8))
	second.set_physics_process(false)
	first.hurtbox.receive(_hit(first, 1.0, &"armada", 0.0, 1.5))
	var struck: bool = await _wait_until(func() -> bool: return second.health.current < second.health.maximum)
	assert_true(struck, "l'autre Muet est heurté")
	assert_lt(first.health.current, first.health.maximum - 1.0, "et le premier aussi")


func test_frappe_maintenue_charge_puis_frappe_fort() -> void:
	await _spawn_on_flat_ground()
	var charger: Muet = await _add_muet(Charger, Vector3(0.0, 0.0, -1.6))
	charger.set_physics_process(false)
	var landed: Array[HitData] = []
	hero.hit_landed.connect(func(hit: HitData) -> void: landed.append(hit))
	hero.input_attack_held = true
	hero.press(&"attack")
	await _wait_for_state(&"Charge")
	await _step(roundi(tuning.charge_full_time * Engine.physics_ticks_per_second) + 2)
	assert_eq(hero.charge_level, 1.0, "pleine charge")
	hero.input_attack_held = false
	await _wait_for_state(&"Attack")
	assert_eq((hero.state_machine.current as Node).get(&"attack").id, &"charged")
	await _wait_until(func() -> bool: return landed.size() >= 2)
	var charged: HitData = landed[landed.size() - 1]
	assert_eq(charged.move, &"charged")
	assert_gt(charged.damage, landed[0].damage * 2.0, "bien plus fort qu'un coup simple")
	assert_gt(charged.poise, tuning.charged_attack.poise, "et il ébranle davantage")


func test_le_coup_charge_brise_la_garde_et_le_bouclier_cede_a_force() -> void:
	await _spawn_on_flat_ground()
	var shielder: Muet = await _add_muet(Shielder, Vector3(0.0, 0.0, -1.2))
	shielder.set_physics_process(false)
	shielder.body.target_yaw = EnemyMath.yaw_of(Vector3.BACK)
	shielder.body.rotation.y = shielder.body.target_yaw
	assert_true(shielder.hurtbox.receive(_hit(shielder, 5.0, &"charged", 1.0)), "le coup chargé passe le bouclier")
	assert_eq(shielder.state_machine.current.name, &"Stunned")
	var other: Muet = await _add_muet(Shielder, Vector3(2.0, 0.0, -1.2))
	other.set_physics_process(false)
	other.body.rotation.y = EnemyMath.yaw_of((hero.global_position - other.global_position) * Vector3(1.0, 0.0, 1.0))
	for i: int in 20:
		if other.staggered:
			break
		assert_false(other.hurtbox.receive(_hit(other, 5.0, &"martelo", tuning.combo_attacks[0].poise)), "bloqué")
	assert_true(other.staggered, "à force, la garde cède")


func test_apres_une_esquive_parfaite_frappe_riposte() -> void:
	await _spawn_on_flat_ground()
	var hopper: Muet = await _add_muet(Hopper, Vector3(0.0, 0.0, -2.0))
	hero.press(&"dodge")
	await _wait_for_state(&"Roll")
	await _step(3)
	hopper.global_position = hero.global_position + Vector3(0.0, 0.0, -0.5)
	await _step(2)
	assert_true(hero.riposte_ready(), "le Muet esquivé s'offre à la riposte")
	await _wait_for_state(&"Ground")
	hopper.set_physics_process(false)
	hopper.global_position = hero.global_position + Vector3(2.5, 0.0, 0.0)
	var landed: Array[HitData] = []
	hero.hit_landed.connect(func(hit: HitData) -> void: landed.append(hit))
	hero.press(&"attack")
	await _wait_for_state(&"Attack")
	assert_eq((hero.state_machine.current as Node).get(&"attack").id, &"riposte")
	await _wait_until(func() -> bool: return not landed.is_empty())
	assert_eq(landed[0].move, &"riposte")
	assert_true(landed[0].critical, "critique")
	assert_false(hero.riposte_ready(), "une seule riposte")
