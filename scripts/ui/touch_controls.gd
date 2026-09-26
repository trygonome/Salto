class_name TouchControls
extends CanvasLayer
## Commandes tactiles du prototype : joystick flottant à gauche, trois boutons ronds colorés à
## droite (Frappe, Saut, Esquive) avec leur nom, la jauge de groove et l'anneau du battement autour
## de Frappe. Pour un conseil, le bouton à utiliser (ou le repère du joystick) brille. En paysage,
## les boutons rétrécissent un peu.

## Action du conseil « courir » (le joystick).
const MOVE := &"move"

## Halo d'un conseil : couleur, épaisseur, écart autour du bouton, battement (fraction du rayon).
@export var halo_color: Color
@export var halo_width: float
@export var halo_margin: float
@export var halo_pulse: float
## Taille des boutons en paysage.
@export var landscape_scale: float

var _halos: Dictionary[StringName, ButtonHalo] = {}
var _buttons_rects: Dictionary[StringName, Rect2] = {}

@onready var _buttons: Control = $Buttons
@onready var _rest_point: Control = $Joystick/RestPoint


func _ready() -> void:
	add_to_group(&"touch_controls")
	for node: Node in _buttons.get_children():
		var button: TouchScreenButton = node as TouchScreenButton
		if button == null:
			continue
		var size: Vector2 = button.texture_normal.get_size() * button.scale
		var halo: ButtonHalo = _make_halo(size.x / 2.0 + halo_margin)
		halo.position = button.position + size / 2.0
		_buttons.add_child(halo)
		_halos[StringName(button.action)] = halo
		_buttons_rects[StringName(button.action)] = Rect2(button.position, size)
	var move_halo: ButtonHalo = _make_halo(Tuning.data.joystick_radius_px + halo_margin)
	_rest_point.add_child(move_halo)
	_halos[MOVE] = move_halo
	get_viewport().size_changed.connect(_layout)
	_layout()


## Fait briller (ou éteint) le bouton de `action` (« move » : le repère du joystick).
func highlight(action: StringName, on: bool) -> void:
	if _halos.has(action):
		_halos[action].set_active(on)


## Rectangle du bouton de `action` à l'écran (coordonnées du canevas) ; vide pour le joystick.
func button_rect(action: StringName) -> Rect2:
	if not _buttons_rects.has(action):
		return Rect2()
	var rect: Rect2 = _buttons_rects[action]
	var transform: Transform2D = _buttons.get_global_transform()
	return Rect2(transform * rect.position, rect.size * _buttons.scale)


## Rectangle qui englobe les trois boutons (coordonnées du canevas).
func pad_rect() -> Rect2:
	var all := Rect2()
	for action: StringName in _buttons_rects:
		var rect: Rect2 = button_rect(action)
		all = rect if not all.has_area() else all.merge(rect)
	return all


## Point du repère du joystick (coordonnées du canevas).
func stick_point() -> Vector2:
	return _rest_point.global_position


func _layout() -> void:
	var portrait: bool = CameraRig.is_portrait(get_viewport().get_visible_rect().size)
	_buttons.scale = Vector2.ONE * (1.0 if portrait else landscape_scale)


func _make_halo(radius: float) -> ButtonHalo:
	var halo := ButtonHalo.new()
	halo.radius = radius
	halo.color = halo_color
	halo.width = halo_width
	halo.pulse_amount = halo_pulse
	return halo
