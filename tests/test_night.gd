extends GutTest
## Progression de la nuit, mélodie des gongs, objets, carnet.

var tuning: TuningData = Tuning.data


func test_on_rapporte_un_tambour_porte() -> void:
	var night := NightProgress.new(3)
	assert_false(night.return_drum(), "rien à poser sans tambour")
	night.pick_drum()
	assert_true(night.return_drum())
	assert_eq(night.drums_returned, 1)
	assert_false(night.carrying_drum)


func test_tomber_fait_perdre_le_tambour_porte_mais_pas_les_rapportes() -> void:
	var night := NightProgress.new(3)
	night.pick_drum()
	night.return_drum()
	night.pick_drum()
	assert_true(night.drop_drum())
	assert_eq(night.drums_returned, 1)
	assert_false(night.drop_drum(), "déjà perdu")


func test_la_nuit_est_accomplie_avec_tous_les_tambours() -> void:
	var night := NightProgress.new(2)
	for i: int in 2:
		assert_false(night.is_complete())
		night.pick_drum()
		night.return_drum()
	assert_true(night.is_complete())


func test_chaque_tambour_ajoute_une_couche_de_musique() -> void:
	var night := NightProgress.new(3)
	assert_eq(night.music_layers(4), 1, "la base seule au début")
	night.pick_drum()
	night.return_drum()
	assert_eq(night.music_layers(4), 2)
	night.drums_returned = 10
	assert_eq(night.music_layers(4), 4, "pas plus de couches qu'il n'y en a")


func test_le_monde_reprend_ses_couleurs() -> void:
	var night := NightProgress.new(2)
	assert_eq(night.world_saturation(0.3, 1.0), 0.3)
	night.drums_returned = 1
	assert_almost_eq(night.world_saturation(0.3, 1.0), 0.65, 0.0001)
	night.drums_returned = 2
	assert_eq(night.world_saturation(0.3, 1.0), 1.0)


func test_une_page_ne_compte_qu_une_fois() -> void:
	var night := NightProgress.new(1)
	assert_true(night.add_page(5))
	assert_false(night.add_page(5))
	assert_eq(night.pages, [5] as Array[int])


func test_la_melodie_se_rejoue_dans_l_ordre() -> void:
	var melody := GongMelody.new(PackedInt32Array([2, 0, 3]))
	assert_eq(melody.strike(2), GongMelody.Result.CORRECT)
	assert_eq(melody.strike(0), GongMelody.Result.CORRECT)
	assert_eq(melody.strike(3), GongMelody.Result.COMPLETE)


func test_une_erreur_fait_tout_recommencer() -> void:
	var melody := GongMelody.new(PackedInt32Array([2, 0, 3]))
	melody.strike(2)
	assert_eq(melody.strike(3), GongMelody.Result.WRONG)
	assert_eq(melody.progress, 0)
	assert_eq(melody.strike(2), GongMelody.Result.CORRECT)


func test_rarete_selon_les_poids() -> void:
	var weights := PackedFloat32Array([1.0, 1.0, 1.0, 1.0])
	assert_eq(ItemMath.rarity_for(0.1, weights), ItemData.Rarity.COMMON)
	assert_eq(ItemMath.rarity_for(0.3, weights), ItemData.Rarity.RARE)
	assert_eq(ItemMath.rarity_for(0.6, weights), ItemData.Rarity.EPIC)
	assert_eq(ItemMath.rarity_for(0.99, weights), ItemData.Rarity.LEGENDARY)


func test_valeur_d_un_effet_selon_les_reglages() -> void:
	# base × (1 + 0,35 × (niveau − 1)) × rareté × tirage × (1 + 0,15 × forge)
	var value: float = ItemMath.effect_value(10.0, 3, ItemData.Rarity.EPIC, 1.1, 2, tuning)
	var expected: float = 10.0 * (1.0 + tuning.item_level_bonus * 2.0) * tuning.item_rarity_multipliers[2] * 1.1 * (1.0 + tuning.item_forge_bonus * 2.0)
	assert_almost_eq(value, expected, 0.0001)


func test_un_objet_tire_a_des_effets_differents_selon_sa_rarete() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 104
	for i: int in 50:
		var item: ItemData = ItemMath.roll_item(rng, 1, tuning.loot_guaranteed_weights, tuning)
		assert_eq(item.effects.size(), tuning.item_effects_per_rarity[item.rarity])
		for effect: StringName in item.effects:
			var base: float = tuning.item_effect_bases[effect]
			var factor: float = tuning.item_rarity_multipliers[item.rarity]
			assert_between(item.effects[effect], base * factor * tuning.item_roll_min - 0.0001, base * factor * tuning.item_roll_max + 0.0001)


func test_le_carnet_a_ses_douze_pages() -> void:
	var notebook: NotebookData = load("res://data/notebook.tres") as NotebookData
	assert_eq(notebook.pages.size(), 12)
	assert_string_starts_with(notebook.text(1), "Avant le Grand Silence")


func test_on_peut_porter_plusieurs_tambours() -> void:
	var night := NightProgress.new(3)
	night.pick_drum()
	night.pick_drum()
	assert_eq(night.drums_carried, 2)
	assert_true(night.return_drum())
	assert_eq(night.drums_returned, 2, "tous les tambours portés sont posés")
	night.pick_drum()
	assert_true(night.drop_drum())
	assert_eq(night.drums_carried, 0)
	assert_eq(night.drums_returned, 2)
