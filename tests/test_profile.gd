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
	item.rolls.assign({&"damage": 0.9, &"health": 1.1})
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
	profile.night_seed = 4242
	profile.nights_done = 1
	assert_true(Save.save_profile(profile))
	var loaded: Profile = Save.load_profile()
	assert_eq(loaded.pages, [5, 1] as Array[int])
	assert_eq(loaded.items.size(), 1)
	var item: ItemData = loaded.items[0]
	assert_eq(item.id, 1)
	assert_eq(item.slot, ItemData.Slot.MASK)
	assert_eq(item.rarity, ItemData.Rarity.EPIC)
	assert_eq(item.level, 2)
	assert_eq(item.forge, 1)
	assert_almost_eq(item.rolls[&"damage"], 0.9, 0.0001)
	assert_almost_eq(item.rolls[&"health"], 1.1, 0.0001)
	assert_true(loaded.is_hint_done(&"move"))
	assert_eq(loaded.best_time(1), 251.5)
	assert_false(loaded.damage_numbers)
	assert_true(loaded.debug_info)
	assert_eq(loaded.night_seed, 4242)
	assert_eq(loaded.nights_done, 1)


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


func test_une_nuit_accomplie_garde_son_record_et_ouvre_la_suivante() -> void:
	Game.start_sortie()
	Game.progress.advance(42.0)
	for i: int in tuning.night_drums_required:
		Game.pick_drum(i)
		Game.return_drum()
	assert_true(Game.new_record)
	assert_almost_eq(Save.load_profile().best_time(1), 42.0, 0.001)
	Game.progress.advance(10.0)
	assert_almost_eq(Game.progress.elapsed, 42.0, 0.001, "le temps s'arrête une fois la nuit accomplie")
	var summary: Dictionary = Game.end_sortie(&"night")
	assert_eq(summary[&"kind"], &"night")
	assert_eq(Game.profile.nights_done, 1)
	assert_eq(Game.profile.night, 2)
	assert_eq(Game.profile.night_seed, 0, "la nuit suivante aura un nouveau monde")
	assert_eq(Game.profile.banked_count(), 0, "ses tambours sont à reprendre")


func test_les_tambours_rapportes_restent_d_une_sortie_a_l_autre() -> void:
	Game.start_sortie()
	Game.pick_drum(1)
	Game.return_drum()
	Game.pick_drum(0)
	var summary: Dictionary = Game.end_sortie(&"faint")
	assert_eq(summary[&"banked"], 1)
	assert_eq(Game.profile.night, 1, "la nuit continue")
	Game.start_sortie()
	assert_eq(Game.profile.sortie, 2)
	assert_true(Game.progress.returned[1], "toujours au village")
	assert_false(Game.progress.picked[0], "le tambour perdu est retourné sur son autel")
	assert_true(Save.load_profile().banked[1])


func test_la_cinquieme_nuit_acheve_la_saga() -> void:
	Game.profile.night = tuning.saga_nights
	Game.start_sortie()
	for i: int in tuning.night_drums_required:
		Game.pick_drum(i)
		Game.return_drum()
	var summary: Dictionary = Game.end_sortie(&"night")
	assert_true(summary[&"finale"])
	assert_true(Game.profile.finished)
	assert_eq(Game.profile.night, tuning.saga_nights + 1, "les nuits sans fin commencent")
	assert_eq(GameTexts.night_name(Game.profile.night), GameTexts.ENDLESS[&"title"])


func test_la_fin_de_sortie_rapporte_des_plumes_et_le_defi() -> void:
	Game.start_sortie()
	var id: StringName = Game.progress.challenge
	assert_true(Game.CHALLENGES.has(id))
	var target: int = Game.progress.challenge_target
	var before: int = Game.profile.plumes
	for i: int in target:
		match id:
			&"perfect":
				Game.on_perfect()
			&"dodge":
				Game.on_perfect_dodge()
			&"dive":
				Game.on_dive_kill()
			&"combo":
				Game.on_combo(target)
			&"multi":
				Game.on_multi_hit(target)
	assert_true(Game.progress.challenge_done)
	assert_eq(Game.profile.plumes, before + tuning.challenge_reward)
	Game.progress.muets_freed = 5
	var summary: Dictionary = Game.end_sortie(&"quit")
	assert_true(summary[&"challenge_done"])
	assert_eq(summary[&"plumes"], roundi(5 * tuning.plumes_per_muet))
	assert_eq(Game.profile.plumes, before + tuning.challenge_reward + summary[&"plumes"])


func test_l_experience_fait_gagner_des_niveaux() -> void:
	Game.start_sortie()
	watch_signals(Game)
	Game.add_xp(ProgressionMath.xp_needed(1, tuning))
	assert_eq(Game.profile.level, 2)
	assert_eq(Game.profile.talent_points, 1)
	assert_signal_emitted_with_parameters(Game, "level_up", [2])
	assert_eq(Game.stats.max_health, tuning.hero_health_base + tuning.hero_health_per_level, "le héros est plus fort")


func test_les_mots_qui_montent_restent_courts() -> void:
	for word: String in GameTexts.WORDS:
		assert_lte(GameTexts.word_count(word), 3, word)
	assert_eq(GameTexts.word_count("Tambour perdu !"), 2, "la ponctuation isolée ne compte pas")


func test_chaque_objet_effet_talent_et_defi_a_son_texte() -> void:
	for slot: int in ItemData.Slot.size():
		for rarity: int in ItemData.Rarity.size():
			var item := ItemData.new()
			item.slot = slot as ItemData.Slot
			item.rarity = rarity as ItemData.Rarity
			assert_gt(GameTexts.item_name(item).split(" ").size(), 1, GameTexts.item_name(item))
	for effect: StringName in tuning.item_effect_bases:
		assert_true(GameTexts.EFFECT_LINES.has(effect), "texte de l'effet %s" % effect)
	for id: StringName in ItemMath.LEGENDARIES:
		assert_true(GameTexts.LEGENDARY_NAMES.has(id) and GameTexts.LEGENDARY_EFFECTS.has(id), String(id))
	for t: Dictionary in TalentTree.TALENTS:
		assert_true(GameTexts.TALENT_NAMES.has(t[&"id"]), String(t[&"id"]))
		assert_false(GameTexts.talent_effect(t[&"id"], 1, tuning).contains("%d"), "valeur remplie")
	for id: StringName in Game.CHALLENGES:
		assert_true(GameTexts.challenge_text(id, 3).contains("3"), String(id))
	for n: int in range(1, tuning.saga_nights + 2):
		assert_ne(GameTexts.night_name(n), "")


func test_lignes_d_effet_nombres_et_durees() -> void:
	assert_eq(GameTexts.effect_line(&"damage", 0.06), "+6 % de dégâts")
	assert_eq(GameTexts.effect_line(&"health", 12.4), "+12 PV max")
	assert_eq(GameTexts.talent_effect(&"breath", 2, tuning), "+%d PV max" % roundi(2.0 * tuning.talent_breath_health))
	assert_eq(GameTexts.plural(1, GameTexts.PLUME), "1 plume")
	assert_eq(GameTexts.plural(3, GameTexts.PLUME), "3 plumes")
	assert_eq(GameTexts.number(12450), "12 450")
	assert_eq(GameTexts.duration(247.9), "4:07")
	assert_eq(GameTexts.duration(59.0), "0:59")


func test_comparer_un_objet_a_celui_qui_est_porte() -> void:
	var worn := ItemData.new()
	worn.rolls.assign({&"health": 1.0})
	var item := ItemData.new()
	item.rarity = ItemData.Rarity.RARE
	item.rolls.assign({&"health": 1.0, &"xp": 1.0})
	var lines: Array[Array] = GameTexts.compare_lines(item, worn)
	assert_eq(lines.size(), 2)
	for line: Array in lines:
		assert_true(line[1], "mieux partout : " + String(line[0]))


func test_une_sauvegarde_de_la_premiere_version_se_relit() -> void:
	var profile: Profile = Profile.from_dict({"version": 1, "nights_done": 2, "items": [{"slot": 1.0, "rarity": 2.0, "level": 3.0, "effects": {"health": 18.0}}]})
	assert_eq(profile.night, 3, "la nuit suivant la dernière accomplie")
	assert_true(profile.started)
	assert_eq(profile.items.size(), 1, "ses objets sont repris")
	assert_eq(profile.items[0].rolls[&"health"], 1.0)
	assert_gt(profile.items[0].id, 0)


func test_la_sauvegarde_garde_la_progression() -> void:
	var profile: Profile = Profile.create()
	profile.level = 5
	profile.xp = 12.5
	profile.talent_points = 2
	profile.talents[&"drum"] = 2
	profile.plumes = 77
	profile.banked[2] = true
	profile.perch_taken.append(3)
	profile.best_score = 900
	var mask: ItemData = profile.equipped_item(ItemData.Slot.MASK)
	mask.forge = 3
	var loaded: Profile = Profile.from_dict(JSON.parse_string(JSON.stringify(profile.to_dict())))
	assert_eq(loaded.level, 5)
	assert_almost_eq(loaded.xp, 12.5, 0.001)
	assert_eq(loaded.talent_points, 2)
	assert_eq(loaded.talent_rank(&"drum"), 2)
	assert_eq(loaded.plumes, 77)
	assert_true(loaded.banked[2])
	assert_eq(loaded.perch_taken, [3] as Array[int])
	assert_eq(loaded.best_score, 900)
	assert_eq(loaded.equipped_item(ItemData.Slot.MASK).forge, 3, "l'objet porté est retrouvé")


func test_le_monde_de_la_nuit_garde_sa_graine() -> void:
	var first: int = Game.world_seed()
	assert_ne(first, 0)
	assert_eq(Game.world_seed(), first)
	assert_eq(Save.load_profile().night_seed, first, "gardée même si on quitte le jeu")
