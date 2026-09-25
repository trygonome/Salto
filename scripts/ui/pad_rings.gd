class_name PadRings
extends Node2D
## Autour du bouton Frappe : la jauge de groove (anneau doré qui se remplit, arc-en-ciel qui tourne
## quand elle est pleine) et l'anneau du battement (s'élargit et s'efface entre deux temps).
## Autour du bouton Esquive : l'attente avant la prochaine roulade (part assombrie).

## Rayons (px) : jauge, anneau du battement ; épaisseurs (px).
@export var groove_radius: float
@export var groove_width: float
@export var beat_radius: float
@export var beat_width: float
## Élargissement de l'anneau du battement (fraction) et part de son effacement.
@export var beat_grow: float
@export var beat_fade: float
@export var groove_color: Color
@export var groove_back: Color
@export var beat_color: Color
## Arc-en-ciel de la jauge pleine : couleurs et tours par seconde.
@export var rainbow: Array[Color]
@export var rainbow_speed: float
## Esquive : centre relatif (px), rayon (px), couleur de l'attente.
@export var dodge_offset: Vector2
@export var dodge_radius: float
@export var dodge_color: Color
## Segments d'un cercle.
@export var segments: int

var _hero: Hero
var _spin: float = 0.0


func _process(delta: float) -> void:
	if _hero == null:
		_hero = get_tree().get_first_node_in_group(&"hero") as Hero
	_spin += delta * rainbow_speed * TAU
	queue_redraw()


func _draw() -> void:
	if _hero == null:
		return
	var tuning: TuningData = Tuning.data
	# Jauge de groove.
	draw_arc(Vector2.ZERO, groove_radius, 0.0, TAU, segments, groove_back, groove_width, true)
	if _hero.groove.is_full():
		var count: int = rainbow.size()
		for i: int in count:
			var from: float = _spin + TAU * i / count
			draw_arc(Vector2.ZERO, groove_radius, from, from + TAU / count, maxi(2, segments / count), rainbow[i], groove_width, true)
	else:
		var fill: float = _hero.groove.fraction()
		if fill > 0.0:
			draw_arc(Vector2.ZERO, groove_radius, -PI / 2.0, -PI / 2.0 + TAU * fill, maxi(2, int(segments * fill)), groove_color, groove_width, true)
	# Anneau du battement : il part du bouton sur le temps, grandit et s'efface.
	var phase: float = Rhythm.beat_phase()
	var grow: float = 1.0 - phase
	var ring: Color = beat_color
	ring.a *= 1.0 - grow * beat_fade
	draw_arc(Vector2.ZERO, beat_radius * (1.0 + beat_grow * grow), 0.0, TAU, segments, ring, beat_width, true)
	# Attente de l'esquive.
	var wait: float = _hero.roll_cooldown_left / tuning.roll_cooldown if tuning.roll_cooldown > 0.0 else 0.0
	if _hero.state_machine.current and _hero.state_machine.current.name == &"Roll":
		wait = 1.0
	if wait > 0.0:
		var points := PackedVector2Array([dodge_offset])
		var steps: int = maxi(2, int(segments * wait))
		for i: int in steps + 1:
			var angle: float = -PI / 2.0 + TAU * wait * i / steps
			points.append(dodge_offset + Vector2(cos(angle), sin(angle)) * dodge_radius)
		draw_colored_polygon(points, dodge_color)
