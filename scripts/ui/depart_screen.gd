class_name DepartScreen
extends ScreenLayer
## Préparer l'expédition (version 3.3) : sur une page, en cartes à icônes voxel, la région (celles
## qui restent fermées disent comment les ouvrir), l'instrument-arme et les pactes de difficulté
## (le bonus de plumes d'or s'affiche) ; « Partir » lance l'expédition. S'ouvre depuis l'écran titre,
## le passage du nord du village, le râtelier et la pierre des pactes.

## Taille des icônes (px) et largeur des cartes (px) ; transparence d'une région fermée.
@export var icon_size: float = 34.0
@export var card_width: float = 150.0
@export var locked_alpha: float = 0.45

@onready var _regions: HBoxContainer = %Regions
@onready var _weapons: HBoxContainer = %Weapons
@onready var _pacts: HBoxContainer = %PactCards
@onready var _go: Button = %Go


func _ready() -> void:
	super()
	add_to_group(&"depart_screen")
	%Title.text = GameTexts.DEPART_TITLE
	%RegionLabel.text = GameTexts.DEPART_REGION
	%WeaponLabel.text = GameTexts.DEPART_WEAPON
	%PactsLabel.text = GameTexts.DEPART_PACTS
	%Back.text = GameTexts.BACK
	%Back.pressed.connect(go_back)
	_go.pressed.connect(_on_go)


## Ouvre la page ; « Retour » appelle `back`.
func open(back: Callable = Callable()) -> void:
	back_action = back
	_render()
	show_screen()


func _render() -> void:
	var profile: Profile = Game.profile
	var tuning: TuningData = Tuning.data
	_clear(_regions)
	var open_regions: Array[StringName] = Regions.unlocked(profile.regions_won)
	for region: StringName in Regions.IDS:
		var locked: bool = not open_regions.has(region)
		var card: TileButton = _card(VoxelIcons.cells(region), GameTexts.REGION_NAMES.get(region, ""), GameTexts.REGION_LOCKED if locked else "", region == profile.region)
		card.disabled = locked
		card.modulate.a = locked_alpha if locked else 1.0
		card.pressed.connect(func() -> void:
			profile.region = region
			Game.save()
			get_tree().call_group(&"night_level", &"preview_region", region)
			_render())
		_regions.add_child(card)
	_clear(_weapons)
	for weapon: WeaponData in tuning.weapons:
		var card: TileButton = _card(HeroVisual.instrument_cells(weapon), GameTexts.WEAPON_NAMES.get(weapon.id, ""), "", weapon.id == profile.weapon)
		card.pressed.connect(func() -> void:
			profile.weapon = weapon.id
			Game.save()
			get_tree().call_group(&"hero", &"equip", weapon.id)
			get_tree().call_group(&"night_level", &"on_weapon_chosen", weapon.id)
			_render())
		_weapons.add_child(card)
	_clear(_pacts)
	for pact: StringName in Pacts.IDS:
		var bonus: int = roundi(tuning.pact_bonus.get(pact, 0.0) * 100.0)
		var card: TileButton = _card(VoxelIcons.cells(pact), GameTexts.PACT_NAMES.get(pact, ""), GameTexts.PACT_BONUS % bonus, profile.pacts.has(pact))
		card.pressed.connect(func() -> void:
			profile.pacts = Pacts.toggle(profile.pacts, pact)
			Game.save()
			_render())
		_pacts.add_child(card)
	var total: int = roundi((Pacts.feather_multiplier(profile.pacts, tuning) - 1.0) * 100.0)
	_go.text = GameTexts.DEPART_GO if total <= 0 else GameTexts.DEPART_GO_BONUS % total
	_go.disabled = not open_regions.has(profile.region)


## Carte à icône voxel, l'icône à gauche du nom (choisie : cadre doré, icône animée) ; en rangées
## basses, les trois choix tiennent sur un écran paysage.
func _card(cells: PackedFloat32Array, name_text: String, detail: String, chosen: bool) -> TileButton:
	var card := TileButton.new()
	card.theme_type_variation = &"TileSelected" if chosen else &"TileButton"
	card.custom_minimum_size.x = card_width
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	row.add_child(VoxelIconView.create(cells, icon_size, chosen))
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.add_theme_constant_override(&"separation", 0)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(_label(name_text, &"TileTitle"))
	if detail != "":
		text.add_child(_label(detail, &"TileSmall"))
	row.add_child(text)
	card.add(row)
	_clicks(card)
	return card


func _on_go() -> void:
	hide_screen()
	back_action = Callable()
	get_tree().call_group(&"night_level", &"depart_from_screen")


func _label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _clear(container: Control) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
