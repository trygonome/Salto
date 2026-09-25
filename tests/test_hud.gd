extends "res://tests/hero_test_base.gd"
## Interface : un seul message à la fois, aides contextuelles, carte d'objet, chiffres de dégâts.

const HudScene: PackedScene = preload("res://scenes/ui/hud.tscn")
const ControlsScene: PackedScene = preload("res://scenes/ui/touch_controls.tscn")
const HintZoneScript: GDScript = preload("res://scripts/levels/props/hint_zone.gd")

var hud: Hud


func before_each() -> void:
	super.before_each()
	Game.profile = Profile.new()
	Game.start_night()
	hud = HudScene.instantiate() as Hud
	world.add_child(hud)



func test_un_seul_message_a_la_fois() -> void:
	hud.show_message("Premier")
	hud.show_message("Second")
	assert_eq(hud.current_message(), "Second", "le nouveau remplace l'ancien")
	var source := Node3D.new()
	world.add_child(source)
	hud.show_reply("Merci !", source, 1.0, 1.0)
	assert_eq(hud.current_message(), "Second", "une réplique ne remplace pas une information")


func test_pendant_un_grand_titre_les_messages_attendent() -> void:
	hud.show_title("Nuit 1", "Titre")
	hud.show_message("Plus tard")
	assert_eq(hud.current_message(), "")
	await wait_for_signal(hud.title_finished, Hud.title_duration(tuning) + 1.0)
	assert_eq(hud.current_message(), "Plus tard")


func test_les_evenements_de_la_nuit_parlent_en_peu_de_mots() -> void:
	Game.pick_drum()
	assert_eq(hud.current_message(), GameTexts.MESSAGE_DRUM_PICKED)
	Game.drop_drum()
	assert_eq(hud.current_message(), GameTexts.MESSAGE_DRUM_LOST)
	Game.free_sanctuary()
	assert_true(hud.is_title_active(), "sanctuaire libéré : grand titre")


func test_un_objet_trouve_montre_sa_carte() -> void:
	var item := ItemData.new()
	item.slot = ItemData.Slot.MASK
	item.rarity = ItemData.Rarity.RARE
	Game.add_item(item)
	var card: Control = hud.get_node("%LootCard") as Control
	assert_true(card.visible)
	assert_eq((hud.get_node("%CardName") as Label).text, "Masque rare")


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
	hero.press(&"dodge")
	assert_eq(hud.current_hint(), &"test_jump", "une autre action ne compte pas")
	hero.press(&"jump")
	assert_eq(hud.current_hint(), &"")
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

