extends GutTest
## Coups du héros : cohérence des réglages, calage de l'animation sur l'impact, rotation visuelle.

const CLIP_LENGTH := 0.9

var tuning: TuningData = Tuning.data


func _all_attacks() -> Array[AttackData]:
	var attacks: Array[AttackData] = tuning.combo_attacks.duplicate()
	attacks.append(tuning.rolling_kick)
	return attacks


func test_l_enchainement_a_trois_coups() -> void:
	assert_eq(tuning.combo_attacks.size(), 3)
	assert_eq(tuning.combo_attacks.map(func(a: AttackData) -> StringName: return a.id), [&"martelo", &"meia_lua", &"armada"])


func test_chaque_coup_touche_puis_s_enchaine_avant_de_finir() -> void:
	for attack: AttackData in _all_attacks():
		assert_gt(attack.impact, 0.0, String(attack.id))
		assert_lt(attack.impact, attack.chain_from, String(attack.id))
		assert_lte(attack.chain_from, attack.duration, String(attack.id))
		assert_gt(attack.reach, 0.0, String(attack.id))
		assert_gt(attack.damage_multiplier, 0.0, String(attack.id))


func test_la_zone_de_detection_couvre_tous_les_coups() -> void:
	var dive_max: float = CombatMath.dive_radius(INF, tuning)
	for attack: AttackData in _all_attacks():
		assert_lte(attack.reach + tuning.dummy_radius, tuning.hitbox_radius, String(attack.id))
	assert_lte(dive_max + tuning.dummy_radius, tuning.hitbox_radius, "onde du plongeon")
	assert_lte(maxf(dive_max, tuning.rainbow_radius) + tuning.dummy_radius, tuning.hitbox_radius, "onde du Salto arc-en-ciel")


func test_l_animation_porte_exactement_a_l_impact() -> void:
	var attack: AttackData = tuning.combo_attacks[0]
	assert_eq(attack.animation_time(0.0, CLIP_LENGTH), 0.0)
	assert_almost_eq(attack.animation_time(attack.impact, CLIP_LENGTH), attack.animation_impact, 0.0001)
	assert_almost_eq(attack.animation_time(attack.duration, CLIP_LENGTH), CLIP_LENGTH, 0.0001)


func test_l_animation_avance_toujours() -> void:
	var attack: AttackData = tuning.combo_attacks[1]
	var previous: float = -1.0
	for i: int in 21:
		var t: float = attack.duration * i / 20.0
		var clip_time: float = attack.animation_time(t, CLIP_LENGTH)
		assert_gt(clip_time, previous)
		previous = clip_time


func test_les_cles_de_rotation_s_interpolent() -> void:
	var keys := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.2, 180.0), Vector2(0.4, 360.0)])
	assert_eq(AttackData.sample_keys(keys, -1.0), 0.0)
	assert_almost_eq(AttackData.sample_keys(keys, 0.1), 90.0, 0.0001)
	assert_almost_eq(AttackData.sample_keys(keys, 0.3), 270.0, 0.0001)
	assert_eq(AttackData.sample_keys(keys, 1.0), 360.0)
	assert_eq(AttackData.sample_keys(PackedVector2Array(), 0.5), 0.0)


func test_l_armada_fait_un_tour_complet() -> void:
	var armada: AttackData = tuning.combo_attacks[2]
	assert_almost_eq(armada.yaw_offset_deg(armada.duration), 360.0, 0.0001)
