class_name BoonScreen
extends ScreenLayer
## Don des esprits : trois cartes (nom, rang, effet) ; on en prend une, le jeu reprend. Sert aussi
## aux rencontres : ce que dit le personnage, et ses choix. Le bouton retour ne ferme pas l'écran :
## il faut choisir.

## Le don `id` vient d'être choisi.
signal chosen(id: StringName)
## Le choix numéro `index` d'une rencontre vient d'être fait.
signal choice_made(index: int)

## Styles des lignes d'une carte : don (nom, rang, effet), choix de rencontre (action, effet).
const BOON_STYLES: Array[StringName] = [&"CardTitle", &"CardTag", &"CardLine"]
const CHOICE_STYLES: Array[StringName] = [&"CardTitle", &"CardLine"]
const CHOICE_SPLIT := " : "

@onready var _cards: VBoxContainer = %Cards
@onready var _pick_sound: AudioStreamPlayer = $PickSound
@onready var _card_sound: AudioStreamPlayer = $CardSound


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
	%Title.text = GameTexts.BOON_TITLE
	%Sub.text = GameTexts.BOON_SUB
	for id: StringName in offer:
		var level: int = Boons.rank(owned, id) + 1
		var card: TileButton = _card([GameTexts.BOON_NAMES[id], GameTexts.BOON_RANK % level if level > 1 else GameTexts.BOON_NEW, GameTexts.boon_text(id, level, tuning)])
		card.pressed.connect(_choose.bind(id))
	get_tree().paused = true
	show_screen()


## Rencontre : `title` (le personnage), `text` (ce qu'il dit), et un choix par entrée de `choices`
## (texte) ; ceux de `enabled` à faux sont grisés.
func open_choices(title: String, text: String, choices: PackedStringArray, enabled: Array[bool]) -> void:
	for child: Node in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	%Title.text = title
	%Sub.text = text
	for i: int in choices.size():
		# « Action : effet » : l'action en titre, l'effet dessous.
		var parts: PackedStringArray = choices[i].split(CHOICE_SPLIT, true, 1)
		var card: TileButton = _card(Array(parts), CHOICE_STYLES)
		card.disabled = not enabled[i]
		if card.disabled:
			card.modulate.a = Tuning.data.ui_disabled_alpha
		card.pressed.connect(_make_choice.bind(i))
	get_tree().paused = true
	show_screen()


func _card(lines: Array, styles: Array[StringName] = BOON_STYLES) -> TileButton:
	var card := TileButton.new()
	card.theme_type_variation = &"DrumCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i: int in lines.size():
		card.add(_label(lines[i], styles[i] if lines.size() > 1 else styles[styles.size() - 1]))
	_clicks(card)
	_cards.add_child(card)
	return card


## Chaque carte qui surgit sonne un petit tambour, un ton plus haut que la précédente.
func _entry_shown(item: Control) -> void:
	if item.get_parent() != _cards or item.is_queued_for_deletion():
		return
	_card_sound.pitch_scale = pow(Tuning.data.ui_card_pitch_step, item.get_index())
	_card_sound.play()


func _make_choice(index: int) -> void:
	_pick_sound.play()
	hide_screen()
	get_tree().paused = false
	choice_made.emit(index)


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
