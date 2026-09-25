extends "res://tests/hero_test_base.gd"
## Le rythme au combat : un appui jugé Parfait ou Bien frappe plus fort, remplit la jauge
## (une fois par coup) ; jauge pleine, Frappe en l'air lance le Salto arc-en-ciel.

var landed: Array[HitData] = []
var judgements: Array[RhythmMath.Judgement] = []


func before_each() -> void:
	super.before_each()
	landed = []
	judgements = []


func _spawn_judged(judgement: RhythmMath.Judgement) -> void:
	await _spawn_on_flat_ground()
	hero.judge = func() -> RhythmMath.Judgement: return judgement
	hero.hit_landed.connect(func(hit: HitData) -> void: landed.append(hit))
	hero.judged.connect(func(j: RhythmMath.Judgement) -> void: judgements.append(j))


func _wait_until_idle() -> void:
	await _step(1)
	for i: int in MAX_FRAMES:
		if _state() == &"Ground":
			return
		await _step(1)
	fail_test("le héros n'est jamais revenu au sol")


func _without_critical(hit: HitData) -> float:
	return hit.damage / (tuning.crit_multiplier if hit.critical else 1.0)


func test_un_coup_parfait_frappe_plus_fort_et_remplit_la_jauge() -> void:
	await _spawn_judged(RhythmMath.Judgement.PERFECT)
	_add_dummy(Vector3(0.0, 0.0, -1.0))
	hero.press(&"attack")
	await _wait_until_idle()
	assert_eq(judgements, [RhythmMath.Judgement.PERFECT] as Array[RhythmMath.Judgement], "jugé au moment de l'appui")
	var base: float = CombatMath.hero_attack(tuning.hero_start_level, tuning) * tuning.combo_attacks[0].damage_multiplier
	assert_almost_eq(_without_critical(landed[0]), base * tuning.perfect_multiplier, 0.001)
	assert_eq(landed[0].judgement, RhythmMath.Judgement.PERFECT)
	assert_eq(hero.groove.value, tuning.groove_perfect)


func test_un_coup_bien_frappe_un_peu_plus_fort() -> void:
	await _spawn_judged(RhythmMath.Judgement.GOOD)
	_add_dummy(Vector3(0.0, 0.0, -1.0))
	hero.press(&"attack")
	await _wait_until_idle()
	var base: float = CombatMath.hero_attack(tuning.hero_start_level, tuning) * tuning.combo_attacks[0].damage_multiplier
	assert_almost_eq(_without_critical(landed[0]), base * tuning.good_multiplier, 0.001)
	assert_eq(hero.groove.value, tuning.groove_good)


func test_a_contretemps_le_coup_marche_quand_meme() -> void:
	await _spawn_judged(RhythmMath.Judgement.MISS)
	_add_dummy(Vector3(0.0, 0.0, -1.0))
	hero.press(&"attack")
	await _wait_until_idle()
	assert_eq(landed.size(), 1)
	assert_eq(hero.groove.value, 0.0)


func test_un_coup_qui_touche_plusieurs_cibles_ne_compte_qu_une_fois() -> void:
	await _spawn_judged(RhythmMath.Judgement.PERFECT)
	for angle: float in [0.0, 120.0, 240.0]:
		_add_dummy(Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(angle)) * 0.9)
	for i: int in tuning.combo_attacks.size():
		hero.press(&"attack")
		await _step(12)
	await _wait_until_idle()
	assert_gt(landed.size(), tuning.combo_attacks.size(), "l'armada touche plusieurs mannequins")
	assert_eq(hero.groove.value, tuning.groove_perfect * tuning.combo_attacks.size(), "une fois par coup")


func test_un_coup_dans_le_vide_ne_remplit_pas_la_jauge() -> void:
	await _spawn_judged(RhythmMath.Judgement.PERFECT)
	hero.press(&"attack")
	await _wait_until_idle()
	assert_eq(hero.groove.value, 0.0)


func test_jauge_pleine_frappe_en_l_air_lance_le_salto_arc_en_ciel() -> void:
	await _spawn_judged(RhythmMath.Judgement.MISS)
	var radius: float = tuning.rainbow_radius + tuning.dummy_radius
	var near: TrainingDummy = _add_dummy(Vector3.LEFT * radius * 0.9)
	hero.groove.add(tuning.groove_max)
	hero.input_jump_held = true
	hero.press(&"jump")
	await _step(10)
	hero.press(&"attack")
	await _wait_for_state(&"Dive")
	assert_true(hero.invulnerable, "invulnérable pendant le Salto arc-en-ciel")
	assert_eq(hero.groove.value, 0.0, "la jauge est consommée")
	var start: float = hero.global_position.y
	await _step(5)
	assert_gt(hero.global_position.y, start, "le bond monte d'abord")
	await _wait_until_idle()
	assert_eq(near.hits_taken, 1)
	assert_eq(landed[0].move, &"rainbow")
	assert_eq(landed[0].stun_time, tuning.rainbow_stun)
	assert_false(hero.invulnerable)


func test_jauge_incomplete_frappe_en_l_air_reste_un_plongeon() -> void:
	await _spawn_judged(RhythmMath.Judgement.MISS)
	hero.groove.add(tuning.groove_max / 2.0)
	hero.input_jump_held = true
	hero.press(&"jump")
	await _step(10)
	hero.press(&"attack")
	await _wait_for_state(&"Dive")
	assert_false(hero.invulnerable)
	assert_lt(hero.velocity.y, 0.0, "le plongeon tombe tout de suite")
