class_name BoonScreen
extends ScreenLayer
## Don des esprits : trois cartes côte à côte (icône voxel, nom, famille et rareté, effet ; version
## 3.2 : cadre et encre à la couleur de la famille) ; on en prend une, le jeu reprend. Sert aussi
## aux rencontres : ce que dit le personnage, et ses choix. Le bouton retour ne ferme pas l'écran :
## il faut choisir.

## Le don `id` vient d'être choisi ; il gagne `ranks` rangs (sa rareté).
signal chosen(id: StringName, ranks: int)
## Le choix numéro `index` d'une rencontre vient d'être fait.
signal choice_made(index: int)

## Styles des lignes d'une carte : don (nom, rang, effet), choix de rencontre (action, effet).
const BOON_STYLES: Array[StringName] = [&"CardTitle", &"CardTag", &"CardLine"]
const CHOICE_STYLES: Array[StringName] = [&"CardTitle", &"CardLine"]
const CHOICE_SPLIT := " : "

## Taille des icônes voxel des cartes (px), largeur d'une carte (px).
@export var icon_size: float = 84.0
@export var card_width: float = 190.0
## Encre de la ligne de rareté sur la peau de tambour (rare, épique, don double ; commun : celle du
## thème).
@export var rarity_colors: Dictionary[StringName, Color] = {
	&"rare": Color(0.08, 0.38, 0.72), &"epic": Color(0.5, 0.12, 0.7), &"duo": Color(0.68, 0.4, 0.0),
}

@onready var _cards: BoxContainer = %Cards
## Dons proposés (pour le journal de jeu).
var _offered: Array = []
@onready var _pick_sound: AudioStreamPlayer = $PickSound
@onready var _card_sound: AudioStreamPlayer = $CardSound


func _ready() -> void:
	super()
	add_to_group(&"boon_screen")
	%Title.text = GameTexts.BOON_TITLE
	%Sub.text = GameTexts.BOON_SUB


## Propose les dons `offer` (le jeu est mis en pause jusqu'au choix) : des cartes {id, rarity}
## (voir Boons.deal) ou de simples noms de dons (communs) ; `title` : le titre de l'écran s'il n'est
## pas « Don des esprits » (don de l'élite, rencontres).
func open(offer: Array, title: String = "") -> void:
	var tuning: TuningData = Tuning.data
	var owned: Dictionary[StringName, int] = {}
	if Game.run:
		owned = Game.run.boons
	for child: Node in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	%Title.text = title if title != "" else GameTexts.BOON_TITLE
	%Sub.text = GameTexts.BOON_SUB
	_offered = []
	for entry: Variant in offer:
		var id: StringName = (entry as Dictionary)[&"id"] if entry is Dictionary else StringName(entry)
		var rarity: StringName = (entry as Dictionary)[&"rarity"] if entry is Dictionary else Boons.COMMON
		_offered.append("%s/%s" % [id, rarity])
		var ranks: int = maxi(1, Boons.ranks_gained(owned, id, rarity, tuning))
		var level: int = Boons.rank(owned, id) + ranks
		var card: TileButton = _card([GameTexts.BOON_NAMES[id], boon_tag(id, rarity, level), GameTexts.boon_text(id, level, tuning)])
		# Version 3.2 : l'icône voxel du don, le cadre et l'encre de l'effet à la couleur de sa famille.
		var family: StringName = Boons.family(id)
		card.content.add_child(VoxelIconView.create(VoxelIcons.boon(id), icon_size))
		card.content.move_child(card.content.get_child(card.content.get_child_count() - 1), 0)
		tint_card(card, family)
		var effect: Label = card.content.get_child(card.content.get_child_count() - 1) as Label
		effect.add_theme_color_override(&"font_color", VoxelIcons.family_color(family, true))
		if rarity_colors.has(rarity):
			(card.content.get_child(2) as Label).add_theme_color_override(&"font_color", rarity_colors[rarity])
		card.pressed.connect(_choose.bind(id, ranks))
	get_tree().paused = true
	show_screen()


## Ligne du milieu d'une carte : famille (ou les deux familles d'un don double), rareté, rang.
static func boon_tag(id: StringName, rarity: StringName, level: int) -> String:
	var rank_text: String = GameTexts.BOON_RANK % level if level > 1 else GameTexts.BOON_NEW
	var family_text: String
	if Boons.DUOS.has(id):
		var needs: Array = Boons.DUOS[id]
		family_text = GameTexts.BOON_DUO_TAG % [GameTexts.BOON_FAMILY_NAMES.get(needs[0], ""), GameTexts.BOON_FAMILY_NAMES.get(needs[1], "")]
		return GameTexts.BOON_TAG % [GameTexts.BOON_RARITY_NAMES[Boons.DUO], family_text]
	family_text = GameTexts.BOON_FAMILY_NAMES.get(Boons.family(id), "")
	var rarity_text: String = GameTexts.BOON_RARITY_NAMES.get(rarity, "")
	var head: String = family_text if rarity_text == "" else GameTexts.BOON_TAG % [family_text, rarity_text]
	return GameTexts.BOON_TAG % [head, rank_text]


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


## Cadre d'une carte à la couleur de la famille (laçage et contour ; version 3.2).
static func tint_card(card: Button, family: StringName) -> void:
	for state: StringName in [&"normal", &"hover", &"pressed", &"focus"]:
		var box: VoxelBox = card.get_theme_stylebox(state, &"DrumCard") as VoxelBox
		if box == null:
			continue
		var tinted: VoxelBox = box.duplicate() as VoxelBox
		tinted.lacing = VoxelIcons.family_color(family)
		tinted.rim = VoxelIcons.family_color(family, true)
		card.add_theme_stylebox_override(state, tinted)


func _card(lines: Array, styles: Array[StringName] = BOON_STYLES) -> TileButton:
	var card := TileButton.new()
	card.theme_type_variation = &"DrumCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.x = card_width
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


func _choose(id: StringName, ranks: int) -> void:
	Journal.event(&"boon", {"offered": _offered, "chosen": String(id), "ranks": ranks})
	_pick_sound.play()
	hide_screen()
	get_tree().paused = false
	chosen.emit(id, ranks)


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
