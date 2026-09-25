extends GutTest
## Profil gardé d'une partie à l'autre, sauvegarde, textes du jeu.

var tuning: TuningData = Tuning.data


func before_each() -> void:
	Save.erase()
	Game.profile = Profile.new()


func after_all() -> void:
	Save.erase()
	Game.profile = Profile.new()


func _item() -> ItemData:
	var item := ItemData.new()
	item.slot = ItemData.Slot.MASK
	item.rarity = ItemData.Rarity.EPIC
	item.level = 2
	item.forge = 1
	item.effects = {&"damage": 0.075, &"health": 14.0}
	return item


func test_un_record_ne_compte_que_s_il_est_meilleur() -> void:
	var profile := Profile.new()
	assert_eq(profile.best_time(1), -1.0, "jamais accomplie")
	assert_true(profile.complete_night(1, 300.0), "première fois")
	assert_false(profile.complete_night(1, 320.0))
	assert_true(profile.complete_night(1, 280.0))
	assert_eq(profile.best_time(1), 280.0)


func test_une_aide_suivie_ne_revient_pas() -> void:
	var profile := Profile.new()
	assert_false(profile.is_hint_done(&"jump"))
	assert_true(profile.mark_hint_done(&"jump"))
	assert_false(profile.mark_hint_done(&"jump"))
	assert_true(profile.is_hint_done(&"jump"))


func test_le_profil_survit_a_la_sauvegarde() -> void:
	var profile := Profile.new()
	profile.add_page(5)
	profile.add_page(1)
	profile.add_item(_item())
	profile.mark_hint_done(&"move")
	profile.complete_night(1, 251.5)
	profile.damage_numbers = false
	profile.debug_info = true
	assert_true(Save.save_profile(profile))
	var loaded: Profile = Save.load_profile()
	assert_eq(loaded.pages, [5, 1] as Array[int])
	assert_eq(loaded.items.size(), 1)
	var item: ItemData = loaded.items[0]
	assert_eq(item.slot, ItemData.Slot.MASK)
	assert_eq(item.rarity, ItemData.Rarity.EPIC)
	assert_eq(item.level, 2)
	assert_eq(item.forge, 1)
	assert_almost_eq(item.effects[&"damage"], 0.075, 0.0001)
	assert_almost_eq(item.effects[&"health"], 14.0, 0.0001)
	assert_true(loaded.is_hint_done(&"move"))
	assert_eq(loaded.best_time(1), 251.5)
	assert_false(loaded.damage_numbers)
	assert_true(loaded.debug_info)


func test_la_sauvegarde_porte_sa_version() -> void:
	assert_eq(Profile.new().to_dict()["version"], Profile.VERSION)


func test_sans_sauvegarde_ou_sauvegarde_abimee_on_part_d_un_profil_neuf() -> void:
	assert_eq(Save.load_profile().pages.size(), 0)
	var file := FileAccess.open(Save.path, FileAccess.WRITE)
	file.store_string("{ pas du json")
	file.close()
	var profile: Profile = Save.load_profile()
	assert_eq(profile.pages.size(), 0)
	assert_true(profile.damage_numbers, "réglages par défaut")


func test_une_sauvegarde_incomplete_garde_les_valeurs_par_defaut() -> void:
	var profile: Profile = Profile.from_dict({"version": 1, "pages": [3.0]})
	assert_eq(profile.pages, [3] as Array[int])
	assert_true(profile.damage_numbers)
	assert_false(profile.debug_info)


func test_une_page_trouvee_est_sauvegardee_une_seule_fois() -> void:
	var pages: Array[int] = []
	Game.page_found.connect(func(page: int) -> void: pages.append(page))
	Game.add_page(4)
	Game.add_page(4)
	assert_eq(pages, [4] as Array[int])
	assert_true(Save.load_profile().has_page(4))


func test_une_nuit_accomplie_garde_son_record() -> void:
	Game.start_night(1)
	Game.progress.advance(42.0)
	for i: int in tuning.night_drums_required:
		Game.pick_drum()
		Game.return_drum()
	assert_true(Game.new_record)
	assert_almost_eq(Save.load_profile().best_time(1), 42.0, 0.001)
	Game.progress.advance(10.0)
	assert_almost_eq(Game.progress.elapsed, 42.0, 0.001, "le temps s'arrête une fois la nuit accomplie")


func test_les_messages_font_au_plus_cinq_mots() -> void:
	for message: String in GameTexts.MESSAGES:
		assert_lte(GameTexts.word_count(message), 5, message)
	assert_eq(GameTexts.word_count("Tambour perdu !"), 2, "la ponctuation isolée ne compte pas")


func test_chaque_objet_et_chaque_effet_a_un_nom() -> void:
	for slot: int in ItemData.Slot.size():
		for rarity: int in ItemData.Rarity.size():
			var item := ItemData.new()
			item.slot = slot as ItemData.Slot
			item.rarity = rarity as ItemData.Rarity
			assert_ne(GameTexts.item_name(item), "")
	for effect: StringName in tuning.item_effect_bases:
		assert_true(GameTexts.EFFECT_LABELS.has(effect), "nom de l'effet %s" % effect)


func test_lignes_d_effet_et_durees() -> void:
	assert_eq(GameTexts.effect_line(&"damage", 0.064), "Dégâts +6 %")
	assert_eq(GameTexts.effect_line(&"health", 12.4), "PV max +12")
	assert_eq(GameTexts.duration(247.9), "4:07")
	assert_eq(GameTexts.duration(59.0), "0:59")
