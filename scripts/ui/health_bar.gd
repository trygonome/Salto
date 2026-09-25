class_name HealthBar
extends Control
## Barre de points de vie du héros, discrète, en haut à gauche. L'affichage rattrape la vraie
## valeur en douceur ; sous le seuil de PV bas, elle bat.

@export var back_color: Color
@export var fill_color: Color
@export var low_color: Color
@export var corner_radius: int
## Bordure autour de la jauge (px).
@export var border: float

var _shown: float = 1.0
var _fraction: float = 1.0
var _time: float = 0.0
var _back := StyleBoxFlat.new()
var _fill := StyleBoxFlat.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for box: StyleBoxFlat in [_back, _fill]:
		box.set_corner_radius_all(corner_radius)
	_back.bg_color = back_color


## Fraction de PV à afficher (0 à 1).
func set_fraction(fraction: float) -> void:
	_fraction = clampf(fraction, 0.0, 1.0)


func _process(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_time += delta
	_shown = lerpf(_shown, _fraction, Smoothing.weight(tuning.health_bar_follow_rate, delta))
	queue_redraw()


func _draw() -> void:
	var tuning: TuningData = Tuning.data
	draw_style_box(_back, Rect2(Vector2.ZERO, size))
	if _shown <= 0.0:
		return
	var low: bool = _fraction <= tuning.health_low_fraction
	var color: Color = fill_color
	if low:
		var beat: float = 0.5 + 0.5 * sin(TAU * _time / tuning.hint_pulse_period)
		color = fill_color.lerp(low_color, beat)
	_fill.bg_color = color
	var inner := Rect2(Vector2.ONE * border, size - Vector2.ONE * border * 2.0)
	inner.size.x = maxf(inner.size.x * _shown, inner.size.y)
	draw_style_box(_fill, inner)
