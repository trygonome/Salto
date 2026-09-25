class_name TileButton
extends Button
## Bouton-tuile (sac, talents) : son contenu, un conteneur, décide de sa taille ; il suit le style
## du bouton (marges intérieures).

var content: VBoxContainer


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	content = VBoxContainer.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(content)
	content.minimum_size_changed.connect(_fit)
	resized.connect(_place)
	theme_changed.connect(_fit)


func _ready() -> void:
	_fit()


## Ajoute `control` au contenu (il laisse passer les touchers vers le bouton).
func add(control: Control) -> Control:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(control)
	return control


func _fit() -> void:
	var style: StyleBox = get_theme_stylebox(&"normal")
	custom_minimum_size.y = content.get_combined_minimum_size().y + style.get_minimum_size().y
	_place()


func _place() -> void:
	var style: StyleBox = get_theme_stylebox(&"normal")
	content.position = Vector2(style.get_margin(SIDE_LEFT), style.get_margin(SIDE_TOP))
	content.size = size - style.get_minimum_size()
