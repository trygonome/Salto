class_name BoonScreen
extends ScreenLayer
## Don des esprits : trois cartes (nom, rang, effet) ; on en prend une, le jeu reprend. Le bouton
## retour ne ferme pas l'écran : il faut choisir.

## Le don `id` vient d'être choisi.
signal chosen(id: StringName)

@onready var _cards: VBoxContainer = %Cards
@onready var _pick_sound: AudioStreamPlayer = $PickSound


func _ready() -> void:
	super()
	add_to_group(&"boon_screen")
	%Title.text = GameTexts.BOON_TITLE
	%Sub.text = GameTexts.BOON_SUB


## Propose les dons `offer` (le jeu est mis en pause jusqu'au choix).
func open(offer: Array[StringName]) -> void:
	var tuning: TuningData = Tuning.data
	var owned: Dictionary[StringName, int] = {}
	if Game.run:
		owned = Game.run.boons
	for child: Node in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	for id: StringName in offer:
		var level: int = Boons.rank(owned, id) + 1
		var card := TileButton.new()
		card.theme_type_variation = &"TileButton"
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add(_label(GameTexts.BOON_NAMES[id], &"ItemTitle"))
		card.add(_label(GameTexts.BOON_RANK % level if level > 1 else GameTexts.BOON_NEW, &"NewTag"))
		card.add(_label(GameTexts.boon_text(id, level, tuning), &"ItemLine"))
		card.pressed.connect(_choose.bind(id))
		_clicks(card)
		_cards.add_child(card)
	get_tree().paused = true
	show_screen()


func _choose(id: StringName) -> void:
	_pick_sound.play()
	hide_screen()
	get_tree().paused = false
	chosen.emit(id)


## Il faut choisir : le bouton retour ne ferme pas l'écran.
func _on_back_requested() -> void:
	pass


func _label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
