class_name DancePad
extends Control
## Bouton Danse (version 4.1), à côté des trois autres, dès qu'on a appris la voie de l'Onde.
## Appuyer puis glisser le pouce : on vise (une ligne au sol, ou un anneau pour la pluie de pas),
## relâcher : la danse part par là. Un toucher bref vise tout seul la Sourdine la plus proche.
## Tenir sans glisser (avec le fil d'écho) : le rayon part et suit ensuite le pouce.
## L'anneau doré autour se remplit avec le groove : plein, la prochaine figure est payée ; sinon le
## bouton pâlit, et un appui ne fait qu'un pas manqué (il tremble).

## Rayon du bouton (px, avant la mise à l'échelle des boutons), couleurs, anneau du groove.
@export var radius: float = 34.0
@export var fill_color: Color = Color(1.0, 0.72, 0.16, 0.93)
@export var stroke_color: Color = Color(1.0, 1.0, 1.0, 0.85)
@export var stroke_width: float = 2.5
@export var ring_gap: float = 5.0
@export var ring_width: float = 4.0
@export var ring_back: Color = Color(1.0, 1.0, 1.0, 0.14)
@export var ring_color: Color = Color(1.0, 0.824, 0.247, 1.0)
## Transparence du bouton quand la prochaine figure n'est pas payée.
@export var poor_alpha: float = 0.45
## Pas manqué : durée (s) et amplitude (px) du tremblement ; nouveau bouton : durée du halo (s).
@export var fizzle_time: float = 0.3
@export var fizzle_shake: float = 5.0
@export var intro_time: float = 3.0
@export var segments: int = 40

var hero: Hero

var _touch: int = -1
var _start_time: float = 0.0
var _stick: Vector2 = Vector2.ZERO
var _dragged: bool = false
var _fizzle_left: float = 0.0
var _intro_left: float = 0.0
var _clock: float = 0.0

@onready var _label: Label = $Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.text = GameTexts.DANCE_BUTTON
	visible = false


## Centre du bouton (coordonnées du canevas), pour les tests et les aides.
func center() -> Vector2:
	return get_global_transform_with_canvas() * (size / 2.0)


func _process(delta: float) -> void:
	_clock += delta
	if hero == null or not is_instance_valid(hero):
		hero = get_tree().get_first_node_in_group(&"hero") as Hero
		if hero:
			hero.dance_fizzled.connect(func() -> void: _fizzle_left = fizzle_time)
	var show: bool = hero != null and hero.can_dance() and hero.reads_player_input
	if show and not visible:
		_intro_left = intro_time
	if not show and _touch >= 0:
		_cancel()
	visible = show
	_fizzle_left = maxf(0.0, _fizzle_left - delta)
	_intro_left = maxf(0.0, _intro_left - delta)
	if visible and _touch >= 0:
		_hold()
	if visible:
		_label.modulate.a = 1.0 if hero.groove.value >= DanceMath.cost(hero.next_dance_figure(), Tuning.data) else poor_alpha
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or hero == null:
		return
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * touch.position
		if touch.pressed and _touch < 0 and local.distance_to(size / 2.0) <= radius + ring_gap + ring_width:
			_touch = touch.index
			_start_time = _clock
			_stick = Vector2.ZERO
			_dragged = false
			hero.dance_aiming = true
			hero.dance_stick = Vector2.ZERO
			hero.dance_manual = false
			get_viewport().set_input_as_handled()
		elif not touch.pressed and touch.index == _touch:
			_release()
			get_viewport().set_input_as_handled()
		return
	var drag: InputEventScreenDrag = event as InputEventScreenDrag
	if drag and drag.index == _touch:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * drag.position
		_stick = ((local - size / 2.0) / Tuning.data.dance_pad_reach_px).limit_length(1.0)
		if _stick.length() > Tuning.data.dance_tap_drag:
			_dragged = true
		hero.dance_stick = _stick
		hero.dance_manual = _dragged
		get_viewport().set_input_as_handled()


## Bouton tenu : sans glisser assez longtemps, le fil d'écho part (s'il est appris).
func _hold() -> void:
	var tuning: TuningData = Tuning.data
	if hero.thread_held or _dragged or not hero.stats.dance.has(DanceMath.THREAD):
		return
	if _clock - _start_time >= tuning.dance_hold_time:
		hero.thread_held = true


func _release() -> void:
	var was_thread: bool = hero.thread_held
	hero.dance_aiming = false
	hero.thread_held = false
	_touch = -1
	if was_thread:
		return
	# Sans avoir glissé (un toucher bref) : visée automatique.
	hero.request_dance(_stick, _dragged)


func _cancel() -> void:
	_touch = -1
	if hero:
		hero.dance_aiming = false
		hero.thread_held = false


func _draw() -> void:
	if hero == null:
		return
	var tuning: TuningData = Tuning.data
	var shake: Vector2 = Vector2(sin(_clock * 60.0) * fizzle_shake * _fizzle_left / fizzle_time, 0.0) if _fizzle_left > 0.0 else Vector2.ZERO
	var c: Vector2 = size / 2.0 + shake
	var cost: float = DanceMath.cost(hero.next_dance_figure(), tuning)
	var ready: bool = hero.groove.value >= cost
	var fill: Color = fill_color
	fill.a *= 1.0 if ready else poor_alpha
	var pressed: bool = _touch >= 0
	draw_circle(c, radius * (0.94 if pressed else 1.0), fill)
	draw_arc(c, radius, 0.0, TAU, segments, stroke_color, stroke_width, true)
	# Anneau du groove : plein quand la prochaine figure est payée.
	var ring_r: float = radius + ring_gap + ring_width / 2.0
	draw_arc(c, ring_r, 0.0, TAU, segments, ring_back, ring_width, true)
	var part: float = clampf(hero.groove.value / maxf(cost, 0.01), 0.0, 1.0)
	if part > 0.0:
		draw_arc(c, ring_r, -PI / 2.0, -PI / 2.0 + TAU * part, segments, ring_color, ring_width, true)
	# Nouveau bouton : un halo qui bat quelques secondes.
	if _intro_left > 0.0:
		var pulse: float = 0.5 + 0.5 * sin(_clock * 8.0)
		draw_arc(c, ring_r + ring_width + 3.0 + pulse * 3.0, 0.0, TAU, segments, Color(1.0, 1.0, 1.0, 0.6 * _intro_left / intro_time), 3.0, true)
