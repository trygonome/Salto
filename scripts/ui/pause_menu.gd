class_name PauseMenu
extends ScreenLayer
## Menu (version 3.4, d'après le croquis du joueur) : en haut, un bandeau (où l'on est, MENU au
## centre, la clairière et les plumes) ; à gauche, les icônes rapides (réglages, son, vibrations)
## et six grands boutons (Sac, Talents, Carnet, Gestes, Rentrer, Reprendre) ; à droite, un panneau
## de cartes à icônes voxel qui défile dans son cadre : l'instrument, les objets portés et les dons
## de l'expédition (toucher une carte la lit en dessous). Sac et Talents : au village seulement (c'est
## là que le héros grandit). Rentrer se touche deux fois. S'ouvre avec le bouton de pause, Échap /
## Start, le bouton retour d'Android, ou quand le jeu passe en arrière-plan.

## Pages du carnet (leur nombre).
@export var notebook: NotebookData
## Taille des icônes des cartes et des icônes rapides (px).
@export var card_icon_size: float = 40.0
@export var quick_icon_size: float = 30.0

## Emplacements des objets et leur icône.
const SLOT_ICONS: Array[StringName] = [&"anklets", &"mask", &"talisman"]
## Transparence d'un emplacement vide.
const EMPTY_ALPHA := 0.55

var _quit_armed: bool = false
var _showing_help: bool = false

@onready var _where: Label = %Where
@onready var _info: Label = %Info
@onready var _resume: Button = %Resume
@onready var _bag: Button = %Bag
@onready var _talents: Button = %Talents
@onready var _notebook: Button = %Notebook
@onready var _help: Button = %Help
@onready var _settings: Button = %Settings
@onready var _sound: Button = %Sound
@onready var _vibration: Button = %Vibration
@onready var _quit: Button = %Quit
@onready var _cards: GridContainer = %Cards
@onready var _scroll: ScrollContainer = %Scroll
@onready var _card_info: Label = %CardInfo


func _ready() -> void:
	super()
	add_to_group(&"pause_menu")
	(%MenuTitle as Label).text = GameTexts.MENU_TITLE
	_resume.text = GameTexts.RESUME
	_resume.pressed.connect(close)
	_bag.pressed.connect(func() -> void: _open_sub(&"bag_screen"))
	_talents.pressed.connect(func() -> void: _open_sub(&"talents_screen"))
	_notebook.pressed.connect(func() -> void: _open_sub(&"notebook_screen"))
	_settings.pressed.connect(func() -> void: _open_sub(&"settings_screen"))
	_settings.add_child(_centered(_quick_icon(&"gear")))
	_sound.pressed.connect(func() -> void:
		Game.set_muted(not Game.profile.muted)
		_refresh_quick())
	_vibration.pressed.connect(func() -> void:
		Game.set_vibration(not Game.profile.vibration)
		_refresh_quick())
	_help.pressed.connect(func() -> void:
		_showing_help = not _showing_help
		_refresh_deck())
	_quit.pressed.connect(_on_quit)


func _band_anchor() -> Control:
	return %Header as Control


func _heading() -> Control:
	return %TitlePlate as Control


## Ce qui surgit à l'ouverture : les icônes rapides, les boutons, puis le panneau des cartes.
func _entries() -> Array[Control]:
	var list: Array[Control] = []
	for child: Node in (%Quick as Node).get_children() + (%Grid as Node).get_children():
		list.append(child as Control)
	list.append(%Deck as Control)
	return list


## Met le jeu en pause et ouvre le menu (pendant une sortie seulement).
func open() -> void:
	if visible or get_tree().paused or not _in_sortie():
		return
	get_tree().paused = true
	_quit_armed = false
	_showing_help = false
	_refresh()
	show_screen()


## Revient au menu (depuis le sac ou les talents), le jeu reste en pause.
func reopen() -> void:
	_refresh()
	show_screen()


## Reprend la partie.
func close() -> void:
	if not visible:
		return
	hide_screen()
	get_tree().paused = false


## Retour : du menu vers le jeu, du jeu vers le menu.
func back() -> void:
	if visible:
		close()
	else:
		open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if visible:
			close()
			get_viewport().set_input_as_handled()
		elif not get_tree().paused and _in_sortie():
			open()
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if visible:
				close()
			elif not get_tree().paused:
				open()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			open()


func _refresh() -> void:
	var profile: Profile = Game.profile
	var level: Level = get_tree().get_first_node_in_group(&"night_level") as Level
	var in_village: bool = level != null and bool(level.get(&"in_village"))
	_where.text = GameTexts.NIGHT_CHAPTER % [Game.night, GameTexts.night_name(Game.night)]
	_info.text = GameTexts.MENU_INFO_HOME % [profile.level, GameTexts.feathers(profile.feathers)]
	if level and level.is_expedition():
		# En expédition : la région, la clairière et les plumes rapportées (au village : le village).
		var region: StringName = Game.run.region if Game.run else profile.region
		_where.text = GameTexts.VILLAGE_TITLE if in_village else GameTexts.PAUSE_EXPEDITION % GameTexts.REGION_NAMES.get(region, "")
		if Game.run and not in_village:
			_info.text = GameTexts.MENU_INFO_RUN % [Game.run.room + 1, Game.run.room_count, GameTexts.feathers(Game.run.feathers)]
	var home: bool = Game.at_village or not Game.playing
	_bag.disabled = not home
	_talents.disabled = not home
	if home:
		_bag.text = GameTexts.BAG_BUTTON
		_talents.text = GameTexts.TALENTS_BUTTON_POINTS % GameTexts.plural(profile.talent_points, GameTexts.POINT) if profile.talent_points > 0 else GameTexts.TALENTS_BUTTON
	else:
		_bag.text = GameTexts.BAG_AT_VILLAGE
		_talents.text = GameTexts.TALENTS_AT_VILLAGE
	_notebook.text = GameTexts.NOTEBOOK_SHORT % [profile.pages.size(), notebook.pages.size()]
	_quit.text = GameTexts.QUIT_CONFIRM if _quit_armed else (GameTexts.QUIT_TO_TITLE if in_village else GameTexts.QUIT)
	_refresh_quick()
	_refresh_deck()


## Icônes rapides : le son (coupé ou non), les vibrations.
func _refresh_quick() -> void:
	var profile: Profile = Game.profile
	for child: Node in _sound.get_children():
		child.queue_free()
	_sound.add_child(_centered(_quick_icon(&"sound_off" if profile.muted else &"sound")))
	_vibration.text = GameTexts.VIBRATION_ON if profile.vibration else GameTexts.VIBRATION_OFF


func _quick_icon(id: StringName) -> VoxelIconView:
	return VoxelIconView.create(VoxelIcons.cells(id), quick_icon_size, false)


## `control` centré sur toute la surface d'un bouton (qui n'est pas un conteneur).
func _centered(control: Control) -> CenterContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(control)
	return center


## Le panneau de droite : les cartes (instrument, objets portés, dons) ou les gestes.
func _refresh_deck() -> void:
	_help.text = GameTexts.MENU_DECK if _showing_help else GameTexts.MENU_HELP
	(%DeckTitle as Label).text = GameTexts.MENU_HELP_TITLE if _showing_help else GameTexts.MENU_DECK_TITLE
	(%HelpText as Label).text = GameTexts.PAUSE_HELP
	(%HelpText as Control).visible = _showing_help
	_scroll.visible = not _showing_help
	_card_info.visible = not _showing_help
	_card_info.text = GameTexts.MENU_DECK_HINT
	for child: Node in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	if _showing_help:
		return
	var profile: Profile = Game.profile
	var weapon_id: StringName = Game.run.weapon if Game.run else profile.weapon
	for weapon: WeaponData in Tuning.data.weapons:
		if weapon.id == weapon_id:
			_add_card(HeroVisual.instrument_cells(weapon), GameTexts.WEAPON_NAMES.get(weapon.id, ""), GameTexts.MENU_INSTRUMENT, GameTexts.WEAPON_TEXTS.get(weapon.id, ""), Color.WHITE)
	for slot: int in SLOT_ICONS.size():
		var item: ItemData = profile.equipped_item(slot as ItemData.Slot)
		var card: TileButton
		if item:
			card = _add_card(VoxelIcons.cells(SLOT_ICONS[slot]), GameTexts.item_name(item), GameTexts.ITEM_LEVEL % item.level, " · ".join(GameTexts.item_lines(item)), Color.WHITE)
		else:
			card = _add_card(VoxelIcons.cells(SLOT_ICONS[slot]), GameTexts.SLOT_NAMES[slot], GameTexts.MENU_EMPTY, GameTexts.MENU_EMPTY_INFO, Color.WHITE)
			card.modulate.a = EMPTY_ALPHA
	if Game.run:
		for id: StringName in Game.run.boons:
			var rank: int = Game.run.boons[id]
			if rank <= 0:
				continue
			var color: Color = VoxelIcons.family_color(Boons.family(id), true)
			_add_card(VoxelIcons.boon(id), GameTexts.boon_name(id), GameTexts.MENU_RANK % rank, GameTexts.boon_text(id, rank, Tuning.data), color)
	_scroll.scroll_vertical = 0


## Une carte : icône voxel, nom (à la couleur de sa famille pour un don), détail ; la toucher la lit
## sous le panneau. Elle laisse passer le glissé du doigt (le panneau défile).
func _add_card(cells: PackedFloat32Array, title: String, detail: String, info: String, color: Color) -> TileButton:
	var card := TileButton.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var icon: VoxelIconView = VoxelIconView.create(cells, card_icon_size, false)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add(icon)
	var name_label: Label = _label(title, &"TileTitle")
	if color != Color.WHITE:
		name_label.add_theme_color_override(&"font_color", color)
	card.add(name_label)
	card.add(_label(detail, &"TileSmall"))
	card.pressed.connect(func() -> void:
		_card_info.text = "%s : %s" % [title, info]
		for other: Node in _cards.get_children():
			(other as Button).theme_type_variation = &"TileSelected" if other == card else &"TileButton")
	_clicks(card)
	_cards.add_child(card)
	return card


func _label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _on_quit() -> void:
	if not _quit_armed:
		_quit_armed = true
		_refresh()
		return
	hide_screen()
	get_tree().call_group(&"night_level", &"end_sortie", &"quit")


func _open_sub(group: StringName) -> void:
	hide_screen()
	var screen: Node = get_tree().get_first_node_in_group(group)
	if screen:
		screen.call(&"open", reopen)


func _in_sortie() -> bool:
	var night: Node = get_tree().get_first_node_in_group(&"night_level")
	return night == null or bool(night.get(&"in_sortie")) or bool(night.get(&"in_village"))
