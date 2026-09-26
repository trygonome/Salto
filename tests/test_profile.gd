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
	item.rolls.assign({&"damage": 0.9, &"health": 1.1})
	return item


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
	assert_almost_eq(item.rolls[&"damage"], 0.9, 0.0001)
	assert_almost_eq(item.rolls[&"health"], 1.1, 0.0001)
	assert_true(loaded.is_hint_done(&"move"))
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


func test_une_nuit_accomplie_ouvre_la_suivante() -> void:
	Game.start_sortie()
	Game.progress.advance(42.0)
	for i: int in tuning.night_drums_required:
		Game.pick_drum(i)
		Game.return_drum()
	Game.progress.advance(10.0)
	assert_almost_eq(Game.progress.elapsed, 42.0, 0.001, "le temps s'arrête une fois la nuit accomplie")
	var summary: Dictionary = Game.end_sortie(&"night")
	assert_eq(summary[&"kind"], &"night")
	assert_almost_eq(summary[&"time"], 42.0, 0.001)
	assert_false(summary.has(&"score"), "ni score ni record : la nuit se raconte en tambours et en Muets")
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


func test_le_heros_grandit_au_village() -> void:
	Game.start_sortie()
	Game.leave_village()
	# Un Muet sautillant tout juste libéré.
	var script := GDScript.new()
	script.source_code = "extends Node3D\nvar species: StringName = &\"hopper\"\nvar tier: int = 0\nvar king: bool = false\n"
	script.reload()
	var muet: Node3D = script.new() as Node3D
	Game.on_muet_freed(muet)
	muet.free()
	assert_eq(Game.progress.xp_carried, tuning.xp_per_species[&"hopper"] * Game.stats.xp, "l'expérience des Muets libérés est mise de côté")
	assert_eq(Game.profile.level, 1, "pas de niveau loin du village")
	assert_eq(Game.profile.xp, 0.0)
	watch_signals(Game)
	Game.enter_village()
	assert_eq(Game.progress.xp_carried, 0.0)
	assert_signal_emitted(Game, "xp_changed")
	assert_eq(Game.profile.xp, tuning.xp_per_species[&"hopper"] * Game.stats.xp, "au village, elle s'ajoute")


func test_l_experience_mise_de_cote_s_ajoute_a_la_fin_de_la_sortie() -> void:
	Game.start_sortie()
	Game.leave_village()
	Game.progress.xp_carried = ProgressionMath.xp_needed(1, tuning)
	var summary: Dictionary = Game.end_sortie(&"faint")
	assert_eq(summary[&"level"], 2, "même évanoui, le héros se réveille au village")
	assert_eq(Save.load_profile().level, 2)


func test_le_cadeau_du_grand_muet_arrive_au_village_avec_son_tambour() -> void:
	Game.start_sortie()
	var bag: int = Game.profile.items.size()
	Game.give_gift(0, false)
	var gift: ItemData = Game.progress.gifts[0]
	assert_not_null(gift)
	assert_eq(gift.level, Game.night + 1, "un niveau de plus que la nuit")
	assert_ne(gift.rarity, ItemData.Rarity.COMMON, "jamais commun")
	Game.free_sanctuary(0)
	Game.pick_drum(0)
	assert_eq(Game.profile.items.size(), bag, "pas encore : il voyage avec le tambour")
	var found: Array[ItemData] = []
	Game.item_found.connect(func(item: ItemData) -> void: found.append(item))
	Game.return_drum()
	assert_eq(found, [gift] as Array[ItemData], "au village : dans le sac")
	assert_true(Save.load_profile().items.size() == bag + 1)


func test_les_muets_liberes_rejoignent_le_village_pour_la_nuit() -> void:
	Game.start_sortie()
	watch_signals(Game)
	Game.welcome(&"hopper")
	Game.welcome(&"boss")
	assert_signal_emit_count(Game, "band_joined", 2)
	for i: int in tuning.village_band_max:
		Game.welcome(&"flyer")
	assert_eq(Game.profile.band.size(), tuning.village_band_max, "une troupe plafonnée")
	Game.end_sortie(&"quit")
	var loaded: Profile = Save.load_profile()
	assert_eq(loaded.band.slice(0, 2), [&"hopper", &"boss"] as Array[StringName], "gardés d'une sortie à l'autre")
	loaded.complete_current_night()
	assert_eq(loaded.band.size(), 0, "une nouvelle nuit, une nouvelle troupe")


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


func test_chaque_objet_effet_et_talent_a_son_texte() -> void:
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
	for n: int in range(1, tuning.saga_nights + 2):
		assert_ne(GameTexts.night_name(n), "")


func test_lignes_d_effet_nombres_et_durees() -> void:
	assert_eq(GameTexts.effect_line(&"damage", 0.06), "+6 % de dégâts")
	assert_eq(GameTexts.effect_line(&"health", 12.4), "+12 PV max")
	assert_eq(GameTexts.talent_effect(&"breath", 2, tuning), "+%d PV max" % roundi(2.0 * tuning.talent_breath_health))
	assert_eq(GameTexts.plural(1, GameTexts.DRUM), "1 tambour")
	assert_eq(GameTexts.plural(3, GameTexts.DRUM), "3 tambours")
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
	profile.banked[2] = true
	var mask: ItemData = profile.equipped_item(ItemData.Slot.MASK)
	var loaded: Profile = Profile.from_dict(JSON.parse_string(JSON.stringify(profile.to_dict())))
	assert_eq(loaded.level, 5)
	assert_almost_eq(loaded.xp, 12.5, 0.001)
	assert_eq(loaded.talent_points, 2)
	assert_eq(loaded.talent_rank(&"drum"), 2)
	assert_true(loaded.banked[2])
	assert_eq(loaded.equipped_item(ItemData.Slot.MASK).id, mask.id, "l'objet porté est retrouvé")


func test_une_sauvegarde_d_avant_la_symbiose_se_relit() -> void:
	var profile: Profile = Profile.from_dict({"version": 2, "plumes": 300, "best_score": 900, "perch_taken": [1.0],
		"items": [{"id": 1.0, "slot": 0.0, "rarity": 1.0, "level": 2.0, "forge": 3.0, "rolls": {"damage": 1.0}}]})
	assert_eq(profile.items.size(), 1, "les objets forgés sont repris")
	assert_eq(profile.to_dict()["version"], Profile.VERSION)
	assert_false(profile.to_dict().has("plumes"), "les plumes n'existent plus")


func test_le_monde_de_la_nuit_garde_sa_graine() -> void:
	var first: int = Game.world_seed()
	assert_ne(first, 0)
	assert_eq(Game.world_seed(), first)
	assert_eq(Save.load_profile().night_seed, first, "gardée même si on quitte le jeu")
