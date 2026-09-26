extends GutTest
## Logique pure de la progression, comme dans le prototype : une sortie (sanctuaires, tambours
## portés, rapportés et déjà au village) ; objets (rareté, effets, sac plein) ; niveaux et
## talents ; forces du héros ; mélodie des gongs et carnet.

var tuning: TuningData = Tuning.data


func _profile() -> Profile:
	return Profile.new()


func test_on_rapporte_les_tambours_portes() -> void:
	var night := NightProgress.new(3)
	assert_eq(night.return_drums(), [] as Array[int], "rien à poser sans tambour")
	assert_true(night.pick_drum(0))
	assert_false(night.pick_drum(0), "déjà pris")
	assert_true(night.pick_drum(2))
	assert_eq(night.carrying, [0, 2] as Array[int])
	assert_eq(night.return_drums(), [0, 2] as Array[int])
	assert_eq(night.drums_returned, 2)
	assert_false(night.carrying_drum)


func test_evanoui_les_tambours_portes_retournent_a_leur_autel() -> void:
	var night := NightProgress.new(3)
	night.pick_drum(0)
	night.return_drums()
	night.pick_drum(1)
	assert_true(night.drop_drums())
	assert_false(night.picked[1], "de nouveau sur son autel")
	assert_true(night.freed[1], "son gardien reste libéré")
	assert_eq(night.drums_returned, 1, "les tambours rapportés restent au village")
	assert_false(night.drop_drums(), "plus rien à perdre")


func test_les_tambours_d_une_sortie_precedente_sont_deja_au_village() -> void:
	var night := NightProgress.new(3, [true, false, false] as Array[bool])
	assert_eq(night.drums_returned, 1)
	assert_true(night.freed[0])
	assert_true(night.banked_at_start[0])
	night.free_sanctuary(1)
	night.pick_drum(1)
	night.return_drums()
	assert_eq(night.drums_returned, 2)
	assert_false(night.banked_at_start[1], "rapporté pendant cette sortie")


func test_la_nuit_est_accomplie_avec_tous_les_tambours() -> void:
	var night := NightProgress.new(2)
	for i: int in 2:
		assert_false(night.is_complete())
		night.pick_drum(i)
		night.return_drums()
	assert_true(night.is_complete())
	night.advance(5.0)
	assert_eq(night.elapsed, 0.0, "le temps s'arrête une fois la nuit accomplie")


func test_chaque_tambour_ajoute_une_couche_de_musique() -> void:
	var night := NightProgress.new(3)
	assert_eq(night.music_layers(4), 1, "la base seule au début")
	night.pick_drum(0)
	night.return_drums()
	assert_eq(night.music_layers(4), 2)
	night.pick_drum(1)
	night.pick_drum(2)
	night.return_drums()
	assert_eq(night.music_layers(3), 3, "pas plus de couches qu'il n'y en a")


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
	assert_eq(ItemMath.rarity_for(0.99, tuning.loot_muet_weights), ItemData.Rarity.EPIC, "un Muet ordinaire ne laisse pas de légendaire")


func test_valeur_d_un_effet_selon_les_reglages() -> void:
	# base × (1 + 0,35 × (niveau − 1)) × rareté × tirage, arrondi.
	var item := ItemData.new()
	item.rarity = ItemData.Rarity.EPIC
	item.level = 3
	item.rolls.assign({&"health": 1.1, &"damage": 1.0})
	var health: float = tuning.item_effect_bases[&"health"] * (1.0 + tuning.item_level_bonus * 2.0) * tuning.item_rarity_multipliers[2] * 1.1
	assert_eq(ItemMath.effect_value(item, &"health", tuning), roundf(health), "les PV sont entiers")
	var damage: float = tuning.item_effect_bases[&"damage"] * (1.0 + tuning.item_level_bonus * 2.0) * tuning.item_rarity_multipliers[2]
	assert_almost_eq(ItemMath.effect_value(item, &"damage", tuning), snappedf(damage, 0.01), 0.0001, "les pour cent sont entiers")


func test_un_objet_tire_a_autant_d_effets_que_sa_rarete_le_permet() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 104
	var weights := PackedFloat32Array([1.0, 1.0, 1.0, 1.0])
	for i: int in 60:
		var item: ItemData = ItemMath.roll_item(rng, 2, weights, tuning)
		assert_eq(item.level, 2)
		assert_eq(item.rolls.size(), mini(tuning.item_effects_per_rarity[item.rarity], (ItemMath.SLOT_EFFECTS[item.slot] as Array).size()))
		for effect: StringName in item.rolls:
			assert_true((ItemMath.SLOT_EFFECTS[item.slot] as Array).has(effect), "effet de son emplacement")
			assert_between(item.rolls[effect], tuning.item_roll_min, tuning.item_roll_max)
		if item.rarity == ItemData.Rarity.LEGENDARY:
			assert_ne(item.legendary, &"")
			assert_eq(item.slot, ItemMath.LEGENDARIES[item.legendary], "un légendaire a son emplacement")


func test_un_nouveau_profil_porte_les_objets_de_depart() -> void:
	var profile: Profile = Profile.create()
	assert_eq(profile.items.size(), ItemData.Slot.size())
	assert_eq(profile.equipped_items().size(), ItemData.Slot.size(), "un objet à chaque emplacement")
	for item: ItemData in profile.items:
		assert_false(item.is_new)
		assert_eq(item.rolls.keys(), [ItemMath.STARTER[item.slot]])


func test_equiper_un_objet() -> void:
	var profile: Profile = Profile.create()
	var item := ItemData.new()
	item.slot = ItemData.Slot.MASK
	item.rarity = ItemData.Rarity.EPIC
	item.rolls.assign({&"health": 1.0})
	profile.add_item(item)
	assert_gt(item.id, 0, "il reçoit un numéro")
	var old: ItemData = profile.equipped_item(ItemData.Slot.MASK)
	profile.equip(item)
	assert_true(profile.is_equipped(item))
	assert_false(profile.is_equipped(old))


func test_sac_plein_le_plus_faible_laisse_sa_place() -> void:
	var profile: Profile = Profile.create()
	var weakest := ItemData.new()
	weakest.level = 1
	profile.add_item(weakest)
	while profile.items.size() < tuning.item_inventory_max:
		var filler := ItemData.new()
		filler.rarity = ItemData.Rarity.RARE
		profile.add_item(filler)
	var starters: Array[ItemData] = profile.equipped_items()
	var extra := ItemData.new()
	extra.rarity = ItemData.Rarity.EPIC
	profile.add_item(extra)
	assert_eq(profile.items.size(), tuning.item_inventory_max)
	assert_true(profile.items.has(extra), "le nouvel objet est rangé")
	assert_false(profile.items.has(weakest), "le plus faible des objets non portés s'en va")
	for item: ItemData in starters:
		assert_true(profile.items.has(item), "un objet porté ne s'en va jamais")


func test_experience_demandee_par_niveau() -> void:
	assert_eq(ProgressionMath.xp_needed(1, tuning), tuning.xp_base)
	assert_eq(ProgressionMath.xp_needed(3, tuning), tuning.xp_base + 2.0 * tuning.xp_per_level + 4.0 * tuning.xp_per_level_squared)
	var result: Dictionary = ProgressionMath.add_xp(1, 0.0, tuning.xp_base + ProgressionMath.xp_needed(2, tuning) + 5.0, tuning)
	assert_eq(result[&"level"], 3)
	assert_eq(result[&"gained"], 2)
	assert_almost_eq(result[&"xp"], 5.0, 0.001)


func test_experience_d_un_muet() -> void:
	assert_eq(ProgressionMath.muet_xp(&"hopper", 0, false, tuning), tuning.xp_per_species[&"hopper"])
	assert_eq(ProgressionMath.muet_xp(&"charger", 2, false, tuning), tuning.xp_per_species[&"charger"] + 2.0 * tuning.xp_per_tier)
	assert_eq(ProgressionMath.muet_xp(&"boss", 1, false, tuning), tuning.xp_boss + tuning.xp_boss_per_tier)
	assert_gt(ProgressionMath.muet_xp(&"boss", 2, true, tuning), ProgressionMath.muet_xp(&"boss", 2, false, tuning), "le Roi en donne plus")


func test_chaque_niveau_donne_un_point_de_talent() -> void:
	var profile := Profile.new()
	assert_eq(profile.add_xp(ProgressionMath.xp_needed(1, tuning)), 1)
	assert_eq(profile.level, 2)
	assert_eq(profile.talent_points, 1)


func test_un_talent_s_ouvre_avec_assez_de_points_dans_sa_voie() -> void:
	var profile := Profile.new()
	profile.talent_points = 5
	assert_false(profile.buy_talent(&"triple"), "il faut d'abord 2 points en Acrobate")
	assert_true(profile.buy_talent(&"feet"))
	assert_true(profile.buy_talent(&"feet"))
	assert_true(profile.buy_talent(&"triple"))
	assert_false(profile.buy_talent(&"triple"), "un seul rang")
	assert_eq(profile.talent_points, 2)
	assert_eq(TalentTree.required_points(&"second"), 3 * TalentTree.POINTS_PER_TIER)
	profile.reset_talents()
	assert_eq(profile.talent_points, 5, "tous les points reviennent")
	assert_eq(profile.talent_rank(&"feet"), 0)


func test_forces_du_heros_selon_niveau_talents_et_objets() -> void:
	var profile := Profile.new()
	profile.level = 3
	profile.talents.assign({&"breath": 2, &"feet": 1, &"triple": 1, &"bark": 1})
	var stats: HeroStats = HeroStats.compute(profile, tuning)
	assert_eq(stats.max_health, tuning.hero_health_base + 2.0 * tuning.hero_health_per_level + 2.0 * tuning.talent_breath_health)
	assert_almost_eq(stats.attack, tuning.hero_attack_base + 2.0 * tuning.hero_attack_per_level, 0.001)
	assert_almost_eq(stats.speed, 1.0 + tuning.talent_feet_speed, 0.001)
	assert_eq(stats.extra_jumps, 1)
	assert_almost_eq(stats.damage_taken, 1.0 - tuning.talent_bark_resistance, 0.001)
	var legendary := ItemData.new()
	legendary.slot = ItemData.Slot.MASK
	legendary.rarity = ItemData.Rarity.LEGENDARY
	legendary.legendary = &"phoenix"
	profile.add_item(legendary)
	profile.equip(legendary)
	stats = HeroStats.compute(profile, tuning)
	assert_eq(stats.second_wind, tuning.legendary_phoenix_health, "le Masque du Phénix relève le héros")


func test_la_resistance_a_un_plancher() -> void:
	var profile := Profile.new()
	var item := ItemData.new()
	item.slot = ItemData.Slot.MASK
	item.rarity = ItemData.Rarity.LEGENDARY
	item.level = 40
	item.rolls.assign({&"resistance": 1.2})
	profile.add_item(item)
	profile.equip(item)
	assert_eq(HeroStats.compute(profile, tuning).damage_taken, tuning.hero_min_damage_taken)


func test_le_carnet_a_ses_douze_pages() -> void:
	var notebook: NotebookData = load("res://data/notebook.tres") as NotebookData
	assert_eq(notebook.pages.size(), 12)
	assert_string_starts_with(notebook.text(1), "Avant le Grand Silence")
