extends "res://tests/hero_test_base.gd"
## Parties différentes 2.8 : instruments-armes (enchaînements, fléchettes de la sarbacane), 25 dons
## en quatre familles, raretés, dons doubles, nouvelles rencontres ; les dons de l'expédition
## changent bien les forces du héros.

const Hopper: PackedScene = preload("res://scenes/enemies/hopper.tscn")


func after_each() -> void:
	Game.run = null
	Game.profile.weapon = &"rainstick"


func _add_muet(at: Vector3) -> Muet:
	var muet: Muet = Hopper.instantiate() as Muet
	muet.position = at
	world.add_child(muet)
	await _step(2)
	muet.set_physics_process(false)
	return muet


func test_quatre_instruments_chacun_son_enchainement() -> void:
	assert_eq(tuning.weapons.size(), 4)
	for weapon: WeaponData in tuning.weapons:
		assert_false(weapon.combo.is_empty(), String(weapon.id))
		assert_true(GameTexts.WEAPON_NAMES.has(weapon.id) and GameTexts.WEAPON_TEXTS.has(weapon.id))
		assert_gt(HeroVisual.instrument_cells(weapon).size(), 0, "il se voit dans la main")
		for attack: AttackData in weapon.combo:
			var pose: StringName = attack.pose if attack.pose != &"" else attack.id
			assert_true(HeroAnimator.ATTACK_POSES.has(pose), "une pose pour %s" % attack.id)
	assert_eq(tuning.weapon(&"rainstick").combo, tuning.combo_attacks, "le bâton de pluie garde l'enchaînement de base")
	assert_lt(tuning.weapon(&"maracas").combo[0].duration, tuning.combo_attacks[0].duration, "les maracas frappent plus vite")
	assert_gt(tuning.weapon(&"hammer").combo[1].reach, tuning.combo_attacks[2].reach, "le tambour-marteau frappe plus large")
	assert_gt(tuning.weapon(&"blowpipe").combo[0].projectiles, 0, "la sarbacane tire")
	assert_eq(tuning.weapon(&"inconnu").id, &"rainstick")
	var profile := Profile.create()
	profile.weapon = &"hammer"
	var saved: Profile = Profile.from_dict(JSON.parse_string(JSON.stringify(profile.to_dict())))
	assert_eq(saved.weapon, &"hammer", "gardé dans la sauvegarde")


func test_les_maracas_enchainent_quatre_secousses() -> void:
	await _spawn_on_flat_ground()
	hero.equip(&"maracas")
	var ids: Array[StringName] = []
	for i: int in 5:
		ids.append(hero.next_attack(&"Attack").id)
	assert_eq(ids, [&"maracas_1", &"maracas_2", &"maracas_3", &"maracas_4", &"maracas_1"] as Array[StringName])


func test_la_sarbacane_touche_de_loin() -> void:
	await _spawn_on_flat_ground()
	hero.equip(&"blowpipe")
	var muet: Muet = await _add_muet(hero.global_position + Vector3(0.0, 0.0, -5.0))
	hero.face_now(Vector3.FORWARD)
	hero.press(&"attack")
	var hurt: bool = false
	for i: int in MAX_FRAMES:
		await _step(1)
		if muet.health.current < muet.health.maximum:
			hurt = true
			break
	assert_true(hurt, "la fléchette atteint le Muet à 5 m")
	assert_gt(tuning.dart_range, 5.0)


func test_vingt_cinq_dons_en_quatre_familles_et_des_dons_doubles() -> void:
	assert_eq(Boons.IDS.size(), 25)
	var per_family: Dictionary[StringName, int] = {}
	for id: StringName in Boons.IDS:
		var family: StringName = Boons.family(id)
		assert_true(Boons.FAMILIES.has(family), "%s a sa famille" % id)
		per_family[family] = per_family.get(family, 0) + 1
	for family: StringName in Boons.FAMILIES:
		assert_gte(per_family.get(family, 0), 5, "au moins 5 dons de %s" % family)
	for id: StringName in Boons.IDS + Boons.DUOS.keys():
		assert_true(GameTexts.BOON_NAMES.has(id) and GameTexts.BOON_TEXTS.has(id), String(id))
		assert_gt(tuning.boon_values.get(id, 0.0), 0.0, "une valeur pour %s" % id)
		assert_false(GameTexts.boon_text(id, 1, tuning).contains("%d"))
	var owned: Dictionary[StringName, int] = {&"ember": 1}
	assert_true(Boons.eligible_duos(owned).is_empty(), "une seule famille : pas de don double")
	owned[&"hawk"] = 1
	assert_eq(Boons.eligible_duos(owned), [&"wildfire"] as Array[StringName], "feu + vent : Feu de joie")
	assert_eq(Boons.max_rank(&"wildfire", tuning), 1)


func test_la_rarete_donne_plusieurs_rangs() -> void:
	var owned: Dictionary[StringName, int] = {}
	assert_eq(Boons.ranks_gained(owned, &"fury", Boons.COMMON, tuning), 1)
	assert_eq(Boons.ranks_gained(owned, &"fury", Boons.RARE, tuning), 2)
	assert_eq(Boons.ranks_gained(owned, &"fury", Boons.EPIC, tuning), 3)
	owned[&"fury"] = 2
	assert_eq(Boons.ranks_gained(owned, &"fury", Boons.EPIC, tuning), 1, "sans dépasser le rang maximal")
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var counts: Dictionary[StringName, int] = {}
	for i: int in 400:
		for card: Dictionary in Boons.deal(rng, {} as Dictionary[StringName, int], 3, tuning):
			counts[card[&"rarity"]] = counts.get(card[&"rarity"], 0) + 1
	assert_gt(counts.get(Boons.COMMON, 0), counts.get(Boons.RARE, 0), "les communs d'abord")
	assert_gt(counts.get(Boons.RARE, 0), counts.get(Boons.EPIC, 0), "les épiques sont rares")
	for card: Dictionary in Boons.deal(rng, {} as Dictionary[StringName, int], 3, tuning, Boons.RARE):
		assert_ne(card[&"rarity"], Boons.COMMON, "le don de l'élite : au moins rare")
	for card: Dictionary in Boons.deal(rng, {} as Dictionary[StringName, int], 3, tuning, Boons.RARE, Boons.SEVE):
		assert_eq(Boons.family(card[&"id"]), Boons.SEVE, "l'Arbre muet : la Sève")
	var mixed: Dictionary[StringName, int] = {&"heart": 1, &"bark": 1}
	var duos: Array[Dictionary] = Boons.deal(rng, mixed, 3, tuning, Boons.COMMON, &"", true)
	assert_eq(duos.size(), 1, "l'Écho : les dons doubles possibles")
	assert_eq(duos[0][&"id"], &"sacred_grove")
	var run := RunState.new(1, 7)
	run.take_boon(&"fury", 2)
	assert_eq(Boons.rank(run.boons, &"fury"), 2)


func test_les_nouveaux_dons_changent_les_forces() -> void:
	var profile := Profile.new()
	var base: HeroStats = HeroStats.compute(profile, tuning)
	var boons: Dictionary[StringName, int] = {&"bark": 1, &"tempo": 1, &"halo": 1, &"rainbow": 1, &"mist": 1, &"blaze": 1, &"regrowth": 2}
	var stats: HeroStats = HeroStats.compute(profile, tuning, boons)
	assert_almost_eq(stats.damage_taken, base.damage_taken * (1.0 - tuning.boon_values[&"bark"]), 0.001)
	assert_almost_eq(stats.attack_speed, base.attack_speed + tuning.boon_values[&"tempo"], 0.001)
	assert_almost_eq(stats.groove, base.groove * (1.0 + tuning.boon_values[&"halo"]), 0.001)
	assert_gt(stats.rainbow_damage, base.rainbow_damage)
	assert_gt(stats.roll_invuln, base.roll_invuln, "Brume : roulade invulnérable plus longtemps")
	assert_eq(stats.blaze, tuning.boon_values[&"blaze"])
	assert_eq(stats.regrowth, 2.0 * tuning.boon_values[&"regrowth"])


func test_les_dons_de_l_expedition_comptent_pour_le_heros() -> void:
	await _spawn_on_flat_ground()
	Game.run = RunState.new(1, 7)
	var before: float = hero.health.maximum
	Game.take_boon(&"heart")
	assert_eq(hero.health.maximum, before + tuning.boon_values[&"heart"], "Cœur de la jungle : des PV en plus pour de vrai")


func test_brasier_et_prisme_frappent_plus_fort() -> void:
	await _spawn_on_flat_ground()
	var muet: Muet = await _add_muet(hero.global_position + Vector3(0.0, 0.0, -1.2))
	var plain: HitData = hero._make_hit(muet.hurtbox, 1.0, &"martelo", RhythmMath.Judgement.MISS, 0.0, 1.0, 0.0)
	Game.run = RunState.new(1, 7)
	Game.take_boon(&"blaze")
	muet.burn(0.1, 5.0)
	var burning: HitData = hero._make_hit(muet.hurtbox, 1.0, &"martelo", RhythmMath.Judgement.MISS, 0.0, 1.0, 0.0)
	var ratio: float = burning.damage / plain.damage
	if burning.critical != plain.critical:
		ratio = (burning.damage / (tuning.crit_multiplier if burning.critical else 1.0)) / (plain.damage / (tuning.crit_multiplier if plain.critical else 1.0))
	assert_almost_eq(ratio, 1.0 + tuning.boon_values[&"blaze"], 0.01, "Brasier : un Muet en feu prend plus")


func test_les_nouvelles_rencontres() -> void:
	for id: StringName in [&"weaver_lady", &"echo_spirit", &"mute_tree"]:
		assert_true(Encounters.IDS.has(id))
	assert_false(Encounters.can_choose(&"weaver_lady", 0, tuning.encounter_weaver_price - 1, tuning), "la Tisseuse veut ses plumes")
	assert_true(Encounters.can_choose(&"weaver_lady", 0, tuning.encounter_weaver_price, tuning))
	assert_false(Encounters.can_choose(&"echo_spirit", 0, 0, tuning, true, false), "pas de don double possible")
	assert_true(Encounters.can_choose(&"echo_spirit", 1, 0, tuning, true, false))


func test_les_dons_d_eau_protegent_et_ralentissent() -> void:
	assert_false(HeroMotion.is_roll_invulnerable(tuning.roll_invuln_end + 0.05, tuning), "sans Brume")
	assert_true(HeroMotion.is_roll_invulnerable(tuning.roll_invuln_end + 0.05, tuning, tuning.boon_values[&"mist"]), "avec Brume : plus longtemps")
	await _spawn_on_flat_ground()
	var muet: Muet = await _add_muet(hero.global_position + Vector3(0.0, 0.0, -3.0))
	muet.chill(0.4, 1.0)
	assert_true(muet.is_chilled(), "Givre : ralenti")
	muet.chill(5.0, 1.0)
	assert_true(muet.is_chilled())
	muet.set_physics_process(true)
	await _step(roundi(1.2 * Engine.physics_ticks_per_second))
	assert_false(muet.is_chilled(), "puis ça passe")
	for family: StringName in Boons.FAMILIES:
		assert_true(GameTexts.BOON_FAMILY_NAMES.has(family))
