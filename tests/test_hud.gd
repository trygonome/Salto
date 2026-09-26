extends "res://tests/hero_test_base.gd"
## Interface du prototype : bannières (une à la fois), message court, bulle, conseil près du bon
## bouton, HUD (niveau, PV, tambours, défi), chiffres de dégâts, pause, sac et forge, talents.

const HudScene: PackedScene = preload("res://scenes/ui/hud.tscn")
const ControlsScene: PackedScene = preload("res://scenes/ui/touch_controls.tscn")
const PauseScene: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
const BagScene: PackedScene = preload("res://scenes/ui/bag_screen.tscn")
const TalentsScene: PackedScene = preload("res://scenes/ui/talents_screen.tscn")
const SummaryScene: PackedScene = preload("res://scenes/ui/summary_screen.tscn")
const HintZoneScript: GDScript = preload("res://scripts/levels/props/hint_zone.gd")

var hud: Hud


func before_each() -> void:
	super.before_each()
	Save.path = "user://test_hud.json"
	Game.profile = Profile.create()
	Game.start_night()
	hud = HudScene.instantiate() as Hud
	world.add_child(hud)


func after_each() -> void:
	get_tree().paused = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.path))


func test_les_bannieres_passent_une_a_une() -> void:
	hud.show_banner("Un", "Premier", "")
	hud.show_banner("Deux", "Second", "")
	assert_eq(hud.current_banner(), "Premier", "la suivante attend")
	await get_tree().create_timer(tuning.banner_gap + 0.1).timeout
	assert_eq(hud.current_banner(), "Second")


func test_un_message_court_puis_il_s_efface() -> void:
	hud.show_toast("Premier")
	hud.show_toast("Second")
	assert_eq(hud.current_toast(), "Second", "le nouveau remplace l'ancien")
	await get_tree().create_timer(tuning.toast_time + 0.2).timeout
	assert_eq(hud.current_toast(), "")


func test_trois_grands_titres_seulement_le_reste_parle_ailleurs() -> void:
	Game.free_sanctuary(0)
	assert_eq(hud.current_banner(), GameTexts.BANNER_SANCTUARY_TITLE, "sanctuaire libéré : grand titre")
	await get_tree().create_timer(tuning.banner_gap + 0.1).timeout
	Game.profile.add_xp(ProgressionMath.xp_needed(1, tuning))
	Game.level_up.emit(2)
	var item := ItemData.new()
	item.slot = ItemData.Slot.MASK
	item.rarity = ItemData.Rarity.RARE
	Game.add_item(item)
	assert_eq(hud.current_banner(), "", "ni le niveau ni l'objet ne prennent le centre de l'écran")
	var card: Control = hud.get_node("%LootCard") as Control
	assert_true(card.visible, "l'objet trouvé : une petite carte en bas")
	assert_eq((hud.get_node("%CardName") as Label).text, "Masque de corail")


func test_le_haut_de_l_ecran_montre_niveau_pv_et_tambours() -> void:
	await _spawn_on_flat_ground()
	Game.profile.level = 3
	Game.pick_drum(0)
	Game.return_drum()
	await _step(2)
	assert_eq((hud.get_node("%LevelLabel") as Label).text, GameTexts.LEVEL_CHIP % 3)
	assert_eq((hud.get_node("%HpText") as Label).text, GameTexts.HEALTH % [roundi(hero.health.current), roundi(hero.health.maximum)])
	assert_eq((hud.get_node("%Drum1") as Control).theme_type_variation, &"DrumOn", "le tambour rapporté s'allume")
	assert_eq((hud.get_node("%Drum2") as Control).theme_type_variation, &"DrumOff")


func test_une_bulle_au_dessus_de_qui_parle() -> void:
	var source := Node3D.new()
	world.add_child(source)
	hud.show_bubble("Bonjour !", source, 1.0)
	assert_eq(hud.current_bubble(), "Bonjour !")
	await get_tree().create_timer(tuning.bubble_time + 0.2).timeout
	assert_eq(hud.current_bubble(), "")


func test_une_aide_brille_puis_disparait_une_fois_suivie() -> void:
	world.add_child(ControlsScene.instantiate())
	await _spawn_on_flat_ground()
	var zone := Area3D.new()
	zone.set_script(HintZoneScript)
	zone.set(&"hint", &"test_jump")
	zone.set(&"action", &"jump")
	zone.set(&"text", "Saute !")
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 3.0, 4.0)
	shape.shape = box
	zone.add_child(shape)
	world.add_child(zone)
	await _step(3)
	assert_eq(hud.current_hint(), &"test_jump")
	assert_eq(hud.current_coach(), "Saute !")
	hero.press(&"dodge")
	assert_eq(hud.current_hint(), &"test_jump", "une autre action ne compte pas")
	hero.press(&"jump")
	assert_eq(hud.current_hint(), &"")
	assert_eq(hud.current_coach(), "")
	assert_true(Game.profile.is_hint_done(&"test_jump"))
	# Suivie une fois, elle ne revient plus.
	zone.body_entered.emit(hero)
	assert_eq(hud.current_hint(), &"")


func test_les_chiffres_de_degats_se_desactivent() -> void:
	await _spawn_on_flat_ground()
	_add_dummy(Vector3(0.0, 0.0, -1.0))
	await _step(2)
	hero.press(&"attack")
	await _step(30)
	assert_eq(world.find_children("*", "DamageNumber", true, false).size(), 1)
	await _step(60)
	Game.set_damage_numbers(false)
	hero.press(&"attack")
	await _step(30)
	assert_eq(world.find_children("*", "DamageNumber", true, false).size(), 0)


func test_la_pause_arrete_le_jeu_et_ouvre_le_sac() -> void:
	var menu: PauseMenu = PauseScene.instantiate() as PauseMenu
	var bag: BagScreen = BagScene.instantiate() as BagScreen
	world.add_child(menu)
	world.add_child(bag)
	menu.open()
	assert_true(get_tree().paused)
	menu.call(&"_open_sub", &"bag_screen")
	assert_false(menu.is_open())
	assert_true(bag.is_open())
	bag.go_back()
	assert_true(menu.is_open(), "retour : du sac à la pause")
	assert_true(get_tree().paused)
	menu.back()
	assert_false(menu.is_open(), "retour : de la pause au jeu")
	assert_false(get_tree().paused)


func test_rentrer_au_village_se_confirme() -> void:
	var menu: PauseMenu = PauseScene.instantiate() as PauseMenu
	world.add_child(menu)
	menu.open()
	var quit: Button = menu.get_node("%Quit") as Button
	quit.pressed.emit()
	assert_eq(quit.text, GameTexts.QUIT_CONFIRM, "il faut toucher deux fois")
	assert_true(menu.is_open())


func test_le_sac_equipe_un_objet() -> void:
	var bag: BagScreen = BagScene.instantiate() as BagScreen
	world.add_child(bag)
	var item := ItemData.new()
	item.slot = ItemData.Slot.TALISMAN
	item.rarity = ItemData.Rarity.EPIC
	item.rolls.assign({&"xp": 1.0})
	Game.profile.add_item(item)
	bag.open()
	assert_eq((bag.get_node("%Equipped") as Control).get_child_count(), ItemData.Slot.size())
	assert_eq((bag.get_node("%Inventory") as Control).get_child_count(), 1, "l'objet non porté est dans le sac")
	bag.call(&"_select", item)
	assert_false(item.is_new, "regardé")
	var actions: Array[Node] = bag.get_node("%Actions").get_children()
	assert_eq(actions.size(), 1, "équiper, rien d'autre")
	(actions[0] as Button).pressed.emit()
	assert_true(Game.profile.is_equipped(item))
	assert_eq(bag.get_node("%Actions").get_child_count(), 0, "porté : plus rien à faire")
	assert_true(Game.stats.xp > 1.0, "le héros profite de l'objet porté")


func test_les_talents_se_prennent_dans_l_ordre() -> void:
	var screen: TalentsScreen = TalentsScene.instantiate() as TalentsScreen
	world.add_child(screen)
	Game.profile.talent_points = 3
	screen.open()
	var tree: Control = screen.get_node("%Tree") as Control
	assert_eq(tree.get_child_count(), 3, "trois voies")
	var first: TileButton = tree.get_child(0).get_child(1) as TileButton
	first.pressed.emit()
	assert_eq(Game.profile.talent_rank(&"feet"), 1)
	assert_eq(Game.profile.talent_points, 2)
	var locked: TileButton = tree.get_child(0).get_child(2) as TileButton
	locked.pressed.emit()
	assert_eq(Game.profile.talent_rank(&"triple"), 0, "il faut d'abord deux points dans la voie")


func test_le_resume_montre_la_sortie() -> void:
	var screen: SummaryScreen = SummaryScene.instantiate() as SummaryScreen
	world.add_child(screen)
	Game.start_sortie()
	Game.progress.advance(125.0)
	Game.progress.muets_freed = 7
	screen.open(Game.end_sortie(&"faint"))
	assert_eq((screen.get_node("%Title") as Label).text, GameTexts.SUMMARY_FAINT)
	var texts: Array[String] = []
	for label: Node in screen.get_node("%Stats").get_children():
		texts.append((label as Label).text)
	assert_has(texts, "2:05")
	assert_has(texts, "7")
	assert_eq((screen.get_node("%Again") as Button).text, GameTexts.AGAIN)
