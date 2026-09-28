class_name BagScreen
extends ScreenLayer
## Sac (un onglet du menu ; version 3.3 en paysage) : à gauche, les trois objets portés
## (chevillières, masque, talisman) et, pour l'objet choisi, ses effets, la comparaison avec l'objet
## porté et Équiper ; à droite, le sac en icônes voxel (le plus rare d'abord, « nouveau » sur ceux pas
## encore regardés).

## Couleur de chaque rareté (commun, rare, épique, légendaire).
@export var rarity_colors: Array[Color]
## Couleur du nom d'un emplacement vide.
@export var empty_slot_color: Color
## Taille des pictogrammes (px) ; largeur visée d'une tuile du sac (px).
@export var icon_size: float
@export var tile_width: float

var _selected: ItemData

@onready var _sub: Label = %Sub
@onready var _equipped: HBoxContainer = %Equipped
## Icône voxel de chaque emplacement (version 3.3).
const SLOT_ICONS: Array[StringName] = [&"anklets", &"mask", &"talisman"]
@onready var _panel: PanelContainer = %ItemPanel
@onready var _item_name: Label = %ItemName
@onready var _item_info: Label = %ItemInfo
@onready var _item_lines: Label = %ItemLines
@onready var _compare: VBoxContainer = %Compare
@onready var _actions: HFlowContainer = %Actions
@onready var _inventory: GridContainer = %Inventory
@onready var _empty: Label = %Empty


func _ready() -> void:
	super()
	add_to_group(&"bag_screen")
	%Title.text = GameTexts.BAG_TITLE
	_empty.text = GameTexts.BAG_EMPTY
	%Back.text = GameTexts.BACK
	%Back.pressed.connect(go_back)


## Ouvre le sac ; « Retour » appelle `back`.
func open(back: Callable = Callable()) -> void:
	back_action = back
	_selected = null
	Game.mark_hint_done(&"bag")
	_render()
	show_screen()


func _render() -> void:
	var profile: Profile = Game.profile
	var tuning: TuningData = Tuning.data
	_sub.text = GameTexts.BAG_SUB % [profile.items.size(), tuning.item_inventory_max]
	_clear(_equipped)
	for slot: int in ItemData.Slot.values():
		var item: ItemData = profile.equipped_item(slot as ItemData.Slot)
		var tile: TileButton = _tile(slot as ItemData.Slot, item, true)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_equipped.add_child(tile)
	_clear(_inventory)
	var others: Array[ItemData] = []
	for item: ItemData in profile.items:
		if not profile.is_equipped(item):
			others.append(item)
	others.sort_custom(func(a: ItemData, b: ItemData) -> bool: return a.rarity > b.rarity or (a.rarity == b.rarity and a.level > b.level))
	for item: ItemData in others:
		var tile: TileButton = _tile(item.slot, item, false)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_inventory.add_child(tile)
	_empty.visible = others.is_empty()
	_render_panel()


## Tuile d'un objet (version 3.3 : son icône voxel d'abord ; porté : son nom ; dans le sac : son
## niveau, « nouveau »), ou d'un emplacement vide. Le nom de l'objet est dans la couleur de sa rareté.
func _tile(slot: ItemData.Slot, item: ItemData, worn: bool) -> TileButton:
	var tile := TileButton.new()
	tile.theme_type_variation = &"TileSelected" if item and item == _selected else &"TileButton"
	tile.add(VoxelIconView.create(VoxelIcons.cells(SLOT_ICONS[slot]), icon_size, item != null and item == _selected))
	var text: String = (GameTexts.item_name(item) if worn else GameTexts.ITEM_LEVEL % item.level) if item else GameTexts.SLOT_NAMES[slot]
	var title: Label = tile.add(_label(text, &"TileTitle" if worn else &"TileSmall")) as Label
	title.modulate = rarity_colors[item.rarity] if item else empty_slot_color
	if item and not worn and item.is_new:
		tile.add(_label(GameTexts.ITEM_NEW, &"NewTag"))
	if item:
		tile.pressed.connect(_select.bind(item))
	_clicks(tile)
	return tile


func _select(item: ItemData) -> void:
	_selected = item
	if item.is_new:
		item.is_new = false
		Game.save()
	_render()


## Détail de l'objet choisi : effets, comparaison avec l'objet porté, actions.
func _render_panel() -> void:
	var item: ItemData = _selected
	_panel.visible = item != null and Game.profile.items.has(item)
	if not _panel.visible:
		return
	var profile: Profile = Game.profile
	var worn: ItemData = profile.equipped_item(item.slot)
	var equipped: bool = profile.is_equipped(item)
	_item_name.text = GameTexts.item_name(item)
	_item_name.modulate = rarity_colors[item.rarity]
	_item_info.text = GameTexts.ITEM_INFO % [GameTexts.RARITY_NAMES[item.rarity], GameTexts.SLOT_NAMES[item.slot], item.level] + (GameTexts.ITEM_WORN if equipped else "")
	_item_lines.text = "\n".join(GameTexts.item_lines(item))
	_clear(_compare)
	if not equipped:
		var lines: Array[Array] = GameTexts.compare_lines(item, worn)
		if not lines.is_empty():
			_compare.add_child(_label(GameTexts.ITEM_COMPARE, &"SmallLabel", false))
			for line: Array in lines:
				_compare.add_child(_label(line[0], &"CompareUp" if line[1] else &"CompareDown", false))
	_compare.visible = _compare.get_child_count() > 0
	_clear(_actions)
	if not equipped:
		_action(GameTexts.EQUIP, &"BuyButton", func() -> void:
			profile.equip(item)
			Game.profile_changed()
			_render())


func _action(text: String, variation: StringName, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = variation
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	_clicks(button)
	_actions.add_child(button)
	return button


func _label(text: String, variation: StringName, centered: bool = true) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _clear(container: Control) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
