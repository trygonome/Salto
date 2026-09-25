class_name PauseMenu
extends CanvasLayer
## Menu pause : Reprendre, Carnet (pages trouvées), Sac (objets trouvés), Réglages (chiffres de
## dégâts, infos techniques des versions de test), Recommencer la nuit. S'ouvre avec le bouton
## de pause, Échap / Start, le bouton retour d'Android, ou quand le jeu passe en arrière-plan.

## Couleur de chaque rareté (commun, rare, épique, légendaire).
@export var rarity_colors: Array[Color]
## Pictogramme de chaque emplacement d'objet (chevillières, masque, talisman).
@export var slot_icons: Array[Texture2D]
## Taille des pictogrammes du sac (px).
@export var icon_size: float
## Place laissée autour des listes qui défilent (px) et hauteur maximale d'une liste (px).
@export var list_margin: float
@export var list_max_height: float

const NOTEBOOK: NotebookData = preload("res://data/notebook.tres")

@onready var _views: Array[Control] = [%Main, %NotebookView, %BagView, %SettingsView]
@onready var _main: Control = %Main
@onready var _notebook_list: VBoxContainer = %NotebookList
@onready var _notebook_header: Label = %NotebookHeader
@onready var _bag_list: VBoxContainer = %BagList
@onready var _damage_numbers: CheckButton = %DamageNumbers
@onready var _debug_info: CheckButton = %DebugInfo


func _ready() -> void:
	add_to_group(&"pause_menu")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	%Title.text = GameTexts.PAUSE_TITLE
	%Resume.text = GameTexts.RESUME
	%Notebook.text = GameTexts.NOTEBOOK
	%Bag.text = GameTexts.BAG
	%Settings.text = GameTexts.SETTINGS
	%Restart.text = GameTexts.RESTART_NIGHT
	%BagHeader.text = GameTexts.BAG
	%SettingsHeader.text = GameTexts.SETTINGS
	_damage_numbers.text = GameTexts.SETTING_DAMAGE_NUMBERS
	_debug_info.text = GameTexts.SETTING_DEBUG_INFO
	%Resume.pressed.connect(close)
	%Notebook.pressed.connect(_show_notebook)
	%Bag.pressed.connect(_show_bag)
	%Settings.pressed.connect(_show_settings)
	%Restart.pressed.connect(_restart)
	for back: Button in [%NotebookBack, %BagBack, %SettingsBack]:
		back.text = GameTexts.BACK
		back.pressed.connect(_show.bind(_main))
	_damage_numbers.toggled.connect(Game.set_damage_numbers)
	_debug_info.toggled.connect(Game.set_debug_info)
	_debug_info.visible = DebugOverlay.available()
	for button: Node in find_children("*", "BaseButton", true, false):
		(button as BaseButton).pressed.connect($ClickSound.play)


## Ouvre le menu et met le jeu en pause (sauf si le jeu est déjà arrêté : écran de fin).
func open() -> void:
	if visible or get_tree().paused:
		return
	get_tree().paused = true
	_show(_main)
	visible = true


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false


func is_open() -> bool:
	return visible


## Retour : d'une page du menu vers le menu, du menu vers le jeu, du jeu vers le menu.
func back() -> void:
	if not visible:
		open()
	elif not _main.visible:
		_show(_main)
	else:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		back()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			back()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			open()


func _show(view: Control) -> void:
	for each: Control in _views:
		each.visible = each == view
	var height: float = minf(list_max_height, get_viewport().get_visible_rect().size.y - list_margin)
	for scroll: ScrollContainer in [%NotebookScroll, %BagScroll]:
		scroll.custom_minimum_size.y = height


func _show_notebook() -> void:
	_clear(_notebook_list)
	var found: Array[int] = Game.profile.pages
	_notebook_header.text = "%s · %s" % [GameTexts.NOTEBOOK, GameTexts.NOTEBOOK_COUNT % [found.size(), NOTEBOOK.pages.size()]]
	for page: int in range(1, NOTEBOOK.pages.size() + 1):
		if found.has(page):
			_add_label(_notebook_list, GameTexts.PAGE_TITLE % page, &"HintLabel")
			_add_label(_notebook_list, NOTEBOOK.text(page), &"")
		else:
			_add_label(_notebook_list, GameTexts.PAGE_MISSING % page, &"SmallLabel")
	_show(%NotebookView)


func _show_bag() -> void:
	_clear(_bag_list)
	if Game.profile.items.is_empty():
		_add_label(_bag_list, GameTexts.BAG_EMPTY, &"SmallLabel")
	for item: ItemData in Game.profile.items:
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 10)
		var icon := TextureRect.new()
		icon.texture = slot_icons[item.slot]
		icon.modulate = rarity_colors[item.rarity]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2.ONE * icon_size
		icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(icon)
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override(&"separation", 0)
		var name_label: Label = _add_label(column, GameTexts.item_name(item), &"")
		name_label.modulate = rarity_colors[item.rarity].lerp(Color.WHITE, 0.4)
		for effect: StringName in item.effects:
			_add_label(column, GameTexts.effect_line(effect, item.effects[effect]), &"SmallLabel")
		row.add_child(column)
		_bag_list.add_child(row)
	_show(%BagView)


func _show_settings() -> void:
	_damage_numbers.set_pressed_no_signal(Game.profile.damage_numbers)
	_debug_info.set_pressed_no_signal(Game.profile.debug_info)
	_show(%SettingsView)


func _restart() -> void:
	visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()


func _add_label(parent: Control, text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.theme_type_variation = variation
	parent.add_child(label)
	return label


func _clear(list: Control) -> void:
	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()
