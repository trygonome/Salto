class_name ScreenLayer
extends CanvasLayer
## Écran plein (titre, pause, résumé, sac, talents…) : une page centrée, au plus `max_width` px de
## large, qui tient sur l'écran en paysage (version 3.3 : plus de défilement ; les pages du menu ont
## un rail d'onglets à gauche). Il tourne même quand le jeu est en pause ; le
## bouton retour d'Android (ou Échap) fait comme son bouton « Retour ».
## À l'ouverture, le fond apparaît, le titre tombe, le bandeau tissé se tisse dessous et chaque
## élément surgit l'un après l'autre ; un bouton appuyé s'écrase un instant (Tuning.ui_*).

## Largeur au plus de la colonne, marge sur les côtés, en haut et en bas (px).
@export var max_width: float
@export var side_margin: float
@export var top_margin: float
@export var bottom_margin: float
## Sous cette hauteur d'écran (px, paysage), le titre rapetisse.
@export var compact_height: float
## Onglet de ce menu (version 3.3 : sac, talents, carnet, réglages) : un rail d'onglets à gauche
## passe d'une page à l'autre, avec « Retour » en bas ; vide : pas de rail.
@export var rail_tab: StringName

## Onglets du menu : groupe de l'écran, nom, icône voxel.
const RAIL_TABS: Array[Array] = [
	[&"bag_screen", GameTexts.BAG_BUTTON, &"anklets"], [&"talents_screen", GameTexts.TALENTS_BUTTON, &"altar"],
	[&"notebook_screen", GameTexts.NOTEBOOK_TAB, &"secret"], [&"settings_screen", GameTexts.SETTINGS_BUTTON, &"tempo"],
]
## Largeur du rail (px) et écart avec la page.
const RAIL_WIDTH := 104.0
const RAIL_GAP := 14.0

## Ce que fait « Retour » (l'écran d'où l'on vient) ; vide : rien.
var back_action: Callable

var _band: WovenBand
var _tween: Tween
var _rail: VBoxContainer

@onready var _margin: MarginContainer = %Margin
@onready var _click: AudioStreamPlayer = $ClickSound
@onready var _backdrop: CanvasItem = get_node_or_null(^"Background") as CanvasItem


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	get_viewport().size_changed.connect(_layout)
	_layout()
	for button: Node in find_children("*", "BaseButton", true, false):
		_clicks(button as BaseButton)
	var anchor: Control = _band_anchor()
	if anchor:
		_band = WovenBand.new()
		_band.name = "Band"
		anchor.add_sibling(_band)
	if rail_tab != &"":
		_build_rail()


## Rail d'onglets du menu (sac, talents, carnet, réglages) ; le sac et les talents ne s'ouvrent
## qu'au village (ou avant de partir).
func _build_rail() -> void:
	var back: Node = get_node_or_null(^"%Back")
	if back:
		(back as Control).visible = false
	_rail = VBoxContainer.new()
	_rail.name = "Rail"
	_rail.add_theme_constant_override(&"separation", 6)
	_rail.alignment = BoxContainer.ALIGNMENT_CENTER
	var area: Control = _margin.get_parent() as Control
	area.add_child(_rail)
	_rail.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_rail.offset_left = side_margin
	_rail.offset_right = side_margin + RAIL_WIDTH
	for tab: Array in RAIL_TABS:
		var button := TileButton.new()
		button.name = String(tab[0])
		button.theme_type_variation = &"TileSelected" if tab[0] == rail_tab else &"TileButton"
		button.add(VoxelIconView.create(VoxelIcons.cells(tab[2]), 30.0, tab[0] == rail_tab))
		var label := Label.new()
		label.text = tab[1]
		label.theme_type_variation = &"TileTitle"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add(label)
		button.pressed.connect(_switch_tab.bind(tab[0]))
		_clicks(button)
		_rail.add_child(button)
	var leave := Button.new()
	leave.text = GameTexts.BACK
	leave.theme_type_variation = &"CtaButton"
	leave.focus_mode = Control.FOCUS_NONE
	leave.pressed.connect(go_back)
	_clicks(leave)
	_rail.add_child(leave)


## Les onglets du sac et des talents sont grisés pendant une expédition.
func _refresh_rail() -> void:
	if _rail == null:
		return
	var home: bool = Game.at_village or not Game.playing
	for child: Node in _rail.get_children():
		var button: TileButton = child as TileButton
		if button and (button.name == "bag_screen" or button.name == "talents_screen"):
			button.disabled = not home
			button.modulate.a = 1.0 if home else Tuning.data.ui_disabled_alpha


## Passe à l'onglet `group` : même « Retour ».
func _switch_tab(group: StringName) -> void:
	if group == rail_tab:
		return
	var screen: Node = get_tree().get_first_node_in_group(group)
	if screen == null:
		return
	var back: Callable = back_action
	back_action = Callable()
	hide_screen()
	screen.call(&"open", back)


## Montre l'écran (sa colonne remonte en haut), en l'animant.
func show_screen() -> void:
	visible = true
	_refresh_rail()
	_layout()
	var scroll: ScrollContainer = _margin.get_parent() as ScrollContainer
	if scroll:
		scroll.scroll_vertical = 0
	_animate_in()


func hide_screen() -> void:
	visible = false


func is_open() -> bool:
	return visible


## Retour : ferme l'écran et revient d'où l'on vient.
func go_back() -> void:
	if not visible:
		return
	hide_screen()
	if back_action.is_valid():
		var action: Callable = back_action
		back_action = Callable()
		action.call()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		_on_back_requested()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and visible:
		_on_back_requested()


## Bouton retour d'Android, ou Échap (chaque écran peut faire autrement).
func _on_back_requested() -> void:
	go_back()


## Donne son clic et son écrasement à un bouton (y compris créé après coup).
func _clicks(button: BaseButton) -> void:
	button.pressed.connect(_click.play)
	button.button_down.connect(_press.bind(button, true))
	button.button_up.connect(_press.bind(button, false))
	button.mouse_exited.connect(_press.bind(button, false))


func _press(button: BaseButton, down: bool) -> void:
	var tuning: TuningData = Tuning.data
	var target: float = tuning.ui_press_scale if down and not button.disabled else 1.0
	var tween: Tween = button.create_tween()
	tween.tween_method(_scale_centered.bind(button), button.scale.x, target, tuning.ui_press_time)


## Contrôle sous lequel se tisse le bandeau (le titre de l'écran).
func _band_anchor() -> Control:
	return get_node_or_null(^"%Title") as Control


## Titre qui tombe à l'ouverture.
func _heading() -> Control:
	return get_node_or_null(^"%Title") as Control


## Ce qui surgit à l'ouverture, dans l'ordre : chaque élément de la colonne (les boutons et les
## cartes un par un).
func _entries() -> Array[Control]:
	var list: Array[Control] = []
	var column: Node = get_node_or_null(^"%Column")
	if column == null:
		return list
	for child: Node in column.get_children():
		var control: Control = child as Control
		if control == null or not control.visible or control == _heading() or control == _band:
			continue
		if control is VBoxContainer:
			for inner: Node in control.get_children():
				if inner is Control and (inner as Control).visible:
					list.append(inner as Control)
		else:
			list.append(control)
	return list


func _animate_in() -> void:
	var tuning: TuningData = Tuning.data
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	if _backdrop:
		_backdrop.modulate.a = 0.0
		_tween.tween_property(_backdrop, "modulate:a", 1.0, tuning.ui_fade_time)
	var title: Control = _heading()
	if title:
		_pop(title, tuning.ui_title_scale, 0.0)
	if _band:
		_band.reveal = 0.0
		_tween.tween_property(_band, "reveal", 1.0, tuning.ui_band_time).set_delay(tuning.ui_stagger).set_ease(Tween.EASE_OUT)
	var entries: Array[Control] = _entries()
	for i: int in entries.size():
		_pop(entries[i], tuning.ui_item_scale, tuning.ui_stagger * (2 + mini(i, tuning.ui_stagger_max)))


## Fait surgir `item` de la taille `from` après `delay` s (il revient à sa transparence de repos).
func _pop(item: Control, from: float, delay: float) -> void:
	var tuning: TuningData = Tuning.data
	var rest: float = item.get_meta(&"rest_alpha", item.modulate.a)
	item.set_meta(&"rest_alpha", rest)
	item.modulate.a = 0.0
	_scale_centered(from, item)
	_tween.tween_property(item, "modulate:a", rest, tuning.ui_pop_time / 2.0).set_delay(delay)
	_tween.tween_method(_scale_centered.bind(item), from, 1.0, tuning.ui_pop_time).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_entry_shown.bind(item)).set_delay(delay)


## `item` surgit (chaque écran peut y ajouter un son).
func _entry_shown(_item: Control) -> void:
	pass


func _scale_centered(value: float, item: Control) -> void:
	item.pivot_offset = item.size / 2.0
	item.scale = Vector2.ONE * value


func _layout() -> void:
	var width: float = get_viewport().get_visible_rect().size.x
	var side: float = maxf(side_margin, (width - max_width) / 2.0)
	var left: float = side
	if _rail:
		# Le rail prend la largeur de son plus large bouton (au moins RAIL_WIDTH).
		var rail_width: float = maxf(RAIL_WIDTH, _rail.get_combined_minimum_size().x)
		_rail.offset_right = _rail.offset_left + rail_width
		left = maxf(side, side_margin + rail_width + RAIL_GAP)
	_margin.add_theme_constant_override(&"margin_left", roundi(left))
	_margin.add_theme_constant_override(&"margin_right", roundi(side))
	_margin.add_theme_constant_override(&"margin_top", roundi(top_margin))
	_margin.add_theme_constant_override(&"margin_bottom", roundi(bottom_margin))
	var title: Label = get_node_or_null(^"%Title") as Label
	if title:
		var compact: bool = get_viewport().get_visible_rect().size.y < compact_height
		title.theme_type_variation = &"ScreenTitleSmall" if compact or not _title_fits(title, width - 2.0 * side) else &"ScreenTitle"


## Vrai si chaque mot du titre tient sur la largeur `available` en grand (sinon il se couperait
## au milieu d'un mot : on le prend plus petit).
func _title_fits(title: Label, available: float) -> bool:
	var font: Font = title.get_theme_font(&"font", &"ScreenTitle")
	var size: int = title.get_theme_font_size(&"font_size", &"ScreenTitle")
	for word: String in title.text.split(" ", false):
		if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > available:
			return false
	return true
