class_name NotebookScreen
extends ScreenLayer
## Carnet : les douze pages qui racontent le Grand Silence. Une page trouvée montre son texte ; une
## page encore cachée dit dans quelle nuit la chercher (gongs, ou sommet d'un perchoir).

## Pages du carnet (textes, nuit de chaque page).
@export var notebook: NotebookData

@onready var _sub: Label = %Sub
@onready var _pages: VBoxContainer = %Pages


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
	for page: int in range(1, total + 1):
		var panel := PanelContainer.new()
		panel.theme_type_variation = &"ItemPanel" if profile.has_page(page) else &"ChipPanel"
		var box := VBoxContainer.new()
		panel.add_child(box)
		box.add_child(_label(GameTexts.PAGE_TITLE % page, &"ItemTitle"))
		box.add_child(_label(notebook.text(page) if profile.has_page(page) else _where(page), &"ItemLine" if profile.has_page(page) else &"SmallLabel"))
		_pages.add_child(panel)


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
