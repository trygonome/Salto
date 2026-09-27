class_name ScreenLayer
extends CanvasLayer
## Écran plein du prototype (titre, pause, résumé, sac, talents) : une colonne centrée qui défile
## si elle dépasse, au plus `max_width` px de large. Il tourne même quand le jeu est en pause ; le
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

## Ce que fait « Retour » (l'écran d'où l'on vient) ; vide : rien.
var back_action: Callable

var _band: WovenBand
var _tween: Tween

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


## Montre l'écran (sa colonne remonte en haut), en l'animant.
func show_screen() -> void:
	visible = true
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
	_margin.add_theme_constant_override(&"margin_left", roundi(side))
	_margin.add_theme_constant_override(&"margin_right", roundi(side))
	_margin.add_theme_constant_override(&"margin_top", roundi(top_margin))
	_margin.add_theme_constant_override(&"margin_bottom", roundi(bottom_margin))
	var title: Label = get_node_or_null(^"%Title") as Label
	if title:
		var compact: bool = get_viewport().get_visible_rect().size.y < compact_height
		title.theme_type_variation = &"ScreenTitleSmall" if compact else &"ScreenTitle"
