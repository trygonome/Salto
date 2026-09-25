class_name FloatingJoystick
extends Control
## Joystick flottant : la base se pose là où le pouce touche la zone, puis ne le suit jamais.
## Au repos, un repère discret reste affiché à l'emplacement du nœud enfant RestPoint.

## Couleur de l'anneau pendant l'utilisation.
@export var ring_color: Color
## Couleur de la manette pendant l'utilisation.
@export var knob_color: Color
## Couleur du repère au repos.
@export var rest_color: Color
## Épaisseur de l'anneau (unités d'interface).
@export var ring_width: float
## Rayon de la manette, en fraction du rayon du joystick.
@export var knob_ratio: float

## Sortie : direction à l'écran (x à droite, y vers le bas), longueur de 0 à 1.
var vector: Vector2 = Vector2.ZERO

var _touch_index: int = -1
var _base: Vector2 = Vector2.ZERO
var _knob_offset: Vector2 = Vector2.ZERO

@onready var _rest_point: Control = $RestPoint


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()


## Vrai tant qu'un doigt tient le joystick.
func is_active() -> bool:
	return _touch_index >= 0


func _input(event: InputEvent) -> void:
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch:
		if touch.pressed and not is_active() and get_global_rect().has_point(touch.position):
			_touch_index = touch.index
			_base = touch.position - global_position
			_move_knob(Vector2.ZERO)
		elif not touch.pressed and touch.index == _touch_index:
			_release()
		return
	var drag: InputEventScreenDrag = event as InputEventScreenDrag
	if drag and drag.index == _touch_index:
		_move_knob(drag.position - global_position - _base)


func _notification(what: int) -> void:
	# Un doigt levé pendant que l'appli n'a plus la main ne serait jamais signalé.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release()


func _draw() -> void:
	var radius: float = Tuning.data.joystick_radius_px
	var center: Vector2 = _base if is_active() else _rest_point.position
	draw_circle(center, radius, ring_color if is_active() else rest_color, false, ring_width, true)
	draw_circle(center + _knob_offset, radius * knob_ratio, knob_color if is_active() else rest_color)


## Direction et force pour un doigt décalé de `offset` par rapport à la base :
## rien dans la zone morte, puis progression jusqu'à la pleine vitesse, atteinte à `full_speed`.
## `dead_zone` et `full_speed` sont des fractions du rayon.
static func shape(offset: Vector2, radius: float, dead_zone: float, full_speed: float) -> Vector2:
	var amount: float = offset.length() / radius
	if amount <= dead_zone:
		return Vector2.ZERO
	var strength: float = clampf((amount - dead_zone) / (full_speed - dead_zone), 0.0, 1.0)
	return offset.normalized() * strength


func _move_knob(offset: Vector2) -> void:
	var tuning: TuningData = Tuning.data
	_knob_offset = offset.limit_length(tuning.joystick_radius_px)
	vector = shape(offset, tuning.joystick_radius_px, tuning.joystick_dead_zone, tuning.joystick_full_speed)
	queue_redraw()


func _release() -> void:
	_touch_index = -1
	_move_knob(Vector2.ZERO)
