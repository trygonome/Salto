class_name NotebookScreen
extends ScreenLayer
## Carnet : les douze pages qui racontent le Grand Silence. Une page trouvée montre son texte ; une
## page encore cachée dit dans quelle nuit la chercher (gongs, ou sommet d'un perchoir).

## Pages du carnet (textes, nuit de chaque page).
@export var notebook: NotebookData

@onready var _sub: Label = %Sub
@onready var _pages: GridContainer = %Pages
@onready var _detail: PanelContainer = %Detail
@onready var _detail_title: Label = %DetailTitle
@onready var _detail_text: Label = %DetailText

## Taille d'une tuile de page (px) ; page montrée à droite.
@export var tile_size: float = 52.0
## Transparence d'une page encore cachée.
@export var missing_alpha: float = 0.55
var _page: int = 0


func _ready() -> void:
	super()
	add_to_group(&"notebook_screen")
	%Title.text = GameTexts.NOTEBOOK_TITLE
	%Back.text = GameTexts.BACK
	%Back.pressed.connect(go_back)


## Ouvre le carnet ; « Retour » appelle `back`.
func open(back: Callable = Callable()) -> void:
	back_action = back
	_render()
	show_screen()


func _render() -> void:
	var profile: Profile = Game.profile
	var total: int = notebook.pages.size()
	_sub.text = GameTexts.NOTEBOOK_SUB % [profile.pages.size(), total]
	for child: Node in _pages.get_children():
		_pages.remove_child(child)
		child.queue_free()
	if _page <= 0 or _page > total:
		_page = profile.pages[profile.pages.size() - 1] if not profile.pages.is_empty() else 1
	for page: int in range(1, total + 1):
		var found: bool = profile.has_page(page)
		var tile := Button.new()
		tile.text = str(page) if found else "?"
		tile.custom_minimum_size = Vector2.ONE * tile_size
		tile.focus_mode = Control.FOCUS_NONE
		tile.theme_type_variation = &"TileSelected" if page == _page else &"TileButton"
		tile.modulate.a = 1.0 if found else missing_alpha
		tile.pressed.connect(func() -> void:
			_page = page
			_render())
		_clicks(tile)
		_pages.add_child(tile)
	var shown: bool = profile.has_page(_page)
	_detail_title.text = GameTexts.PAGE_TITLE % _page
	_detail_text.text = notebook.text(_page) if shown else _where(_page)
	_detail.theme_type_variation = &"PagePanel" if shown else &"SlotPanel"


## Où chercher une page encore cachée.
func _where(page: int) -> String:
	var night: int = notebook.night_of_page(page)
	if night == 0:
		return GameTexts.PAGE_EMPTY
	return (GameTexts.PAGE_GONGS if notebook.pages_of_night(night)[0] == page else GameTexts.PAGE_PERCH) % night


func _label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
