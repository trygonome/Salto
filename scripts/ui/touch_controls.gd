class_name TouchControls
extends CanvasLayer
## Commandes tactiles : joystick flottant à gauche, trois boutons à droite (Frappe, Saut,
## Esquive). Pour une aide contextuelle, le bouton à utiliser (ou le repère du joystick) brille.

## Action de l'aide « courir » (le joystick).
const MOVE := &"move"

## Halo des aides : couleur, épaisseur, écart autour du bouton, battement (fraction du rayon).
@export var halo_color: Color
@export var halo_width: float
@export var halo_margin: float
@export var halo_pulse: float
## Où écrire l'aide : au-dessus des boutons, ou au-dessus du repère du joystick (décalage depuis
## le haut du halo).
@export var hint_gap: float

var _halos: Dictionary[StringName, ButtonHalo] = {}

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
	var move_halo: ButtonHalo = _make_halo(Tuning.data.joystick_radius_px + halo_margin)
	_rest_point.add_child(move_halo)
	_halos[MOVE] = move_halo


## Fait briller (ou éteint) le bouton de `action` (« move » : le joystick).
func highlight(action: StringName, on: bool) -> void:
	if _halos.has(action):
		_halos[action].set_active(on)


## Point (coordonnées du canevas) où centrer le bas du texte d'une aide pour `action` :
## au-dessus du groupe de boutons, ou au-dessus du joystick.
func hint_anchor(action: StringName) -> Vector2:
	if action == MOVE:
		var halo: ButtonHalo = _halos[MOVE]
		return halo.global_position + Vector2.UP * (halo.radius + hint_gap)
	var top: float = INF
	var left: float = INF
	var right: float = -INF
	for key: StringName in _halos:
		if key == MOVE:
			continue
		var halo: ButtonHalo = _halos[key]
		top = minf(top, halo.global_position.y - halo.radius)
		left = minf(left, halo.global_position.x - halo.radius)
		right = maxf(right, halo.global_position.x + halo.radius)
	return Vector2((left + right) / 2.0, top - hint_gap)


func _make_halo(radius: float) -> ButtonHalo:
	var halo := ButtonHalo.new()
	halo.radius = radius
	halo.color = halo_color
	halo.width = halo_width
	halo.pulse_amount = halo_pulse
	return halo
