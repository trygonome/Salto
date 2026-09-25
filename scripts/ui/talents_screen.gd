class_name TalentsScreen
extends ScreenLayer
## Talents du prototype : trois voies (Acrobate, Percussion, Chamane) de quatre talents. Chaque
## niveau donne un point ; un talent s'ouvre quand sa voie a reçu assez de points. Les rangs pris
## se voient en ronds pleins ; les talents qu'on peut prendre ont un bord vert. Tout peut être
## réinitialisé (les points reviennent).

## Couleur du nom de chaque voie.
@export var branch_colors: Array[Color]
## Transparence d'un talent fermé, et d'un talent ouvert pas encore pris.
@export var locked_alpha: float
@export var idle_alpha: float

@onready var _sub: Label = %Sub
@onready var _tree: HBoxContainer = %Tree
@onready var _pips_model: Pips = %PipsModel
@onready var _reset: Button = %Reset
@onready var _buy_sound: AudioStreamPlayer = $BuySound


func _ready() -> void:
	super()
	add_to_group(&"talents_screen")
	%Title.text = GameTexts.TALENTS_TITLE
	%Back.text = GameTexts.BACK
	%Back.pressed.connect(go_back)
	_reset.text = GameTexts.TALENTS_RESET
	_reset.pressed.connect(func() -> void:
		Game.profile.reset_talents()
		Game.profile_changed()
		_render())


## Ouvre les talents ; « Retour » appelle `back`.
func open(back: Callable = Callable()) -> void:
	back_action = back
	_render()
	show_screen()


func _render() -> void:
	var profile: Profile = Game.profile
	var tuning: TuningData = Tuning.data
	_sub.text = GameTexts.TALENTS_SUB_POINTS % [profile.level, GameTexts.plural(profile.talent_points, GameTexts.POINT)] if profile.talent_points > 0 \
		else GameTexts.TALENTS_SUB % profile.level
	_reset.visible = TalentTree.spent(profile.talents) > 0
	for child: Node in _tree.get_children():
		_tree.remove_child(child)
		child.queue_free()
	for branch: int in TalentTree.Branch.values():
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override(&"separation", _tree.get_theme_constant(&"separation"))
		var title := Label.new()
		title.text = GameTexts.BRANCH_NAMES[branch]
		title.theme_type_variation = &"BranchTitle"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.modulate = branch_colors[branch]
		column.add_child(title)
		for t: Dictionary in TalentTree.branch_talents(branch as TalentTree.Branch):
			column.add_child(_tile(t, branch, tuning))
		_tree.add_child(column)


func _tile(t: Dictionary, branch: int, tuning: TuningData) -> TileButton:
	var profile: Profile = Game.profile
	var id: StringName = t[&"id"]
	var rank: int = profile.talent_rank(id)
	var required: int = TalentTree.required_points(id)
	var locked: bool = TalentTree.spent_in(branch as TalentTree.Branch, profile.talents) < required
	var can: bool = TalentTree.can_buy(id, profile.talents, profile.talent_points)
	var tile := TileButton.new()
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.theme_type_variation = &"TileCan" if can else &"TileSelected" if rank > 0 else &"TileButton"
	tile.modulate.a = locked_alpha if locked else 1.0 if rank > 0 or can else idle_alpha
	tile.add(_label(GameTexts.TALENT_NAMES[id], &"TileTitle"))
	var pips: Pips = _pips_model.duplicate() as Pips
	pips.visible = true
	pips.maximum = t[&"max"]
	pips.rank = rank
	pips.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tile.add(pips)
	var text: String = GameTexts.TALENT_LOCKED % [required, GameTexts.BRANCH_NAMES[branch]] if locked else GameTexts.talent_effect(id, rank, tuning)
	tile.add(_label(text, &"TileSmall"))
	tile.pressed.connect(func() -> void:
		if profile.buy_talent(id):
			_buy_sound.play()
			Game.profile_changed()
			_render())
	_clicks(tile)
	return tile


func _label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
