class_name ScreenLayer
extends CanvasLayer
## Écran plein du prototype (titre, pause, résumé, sac, talents) : une colonne centrée qui défile
## si elle dépasse, au plus `max_width` px de large. Il tourne même quand le jeu est en pause ; le
## bouton retour d'Android (ou Échap) fait comme son bouton « Retour ».

## Largeur au plus de la colonne, marge sur les côtés, en haut et en bas (px).
@export var max_width: float
@export var side_margin: float
@export var top_margin: float
@export var bottom_margin: float
## Sous cette hauteur d'écran (px, paysage), le titre rapetisse.
@export var compact_height: float

## Ce que fait « Retour » (l'écran d'où l'on vient) ; vide : rien.
var back_action: Callable

@onready var _margin: MarginContainer = %Margin
@onready var _click: AudioStreamPlayer = $ClickSound


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	get_viewport().size_changed.connect(_layout)
	_layout()
	for button: Node in find_children("*", "BaseButton", true, false):
		(button as BaseButton).pressed.connect(_click.play)


## Montre l'écran (sa colonne remonte en haut).
func show_screen() -> void:
	visible = true
	_layout()
	var scroll: ScrollContainer = _margin.get_parent() as ScrollContainer
	if scroll:
		scroll.scroll_vertical = 0


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


## Ajoute un bouton de rappel du clic à un bouton créé après coup.
func _clicks(button: BaseButton) -> void:
	button.pressed.connect(_click.play)


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
