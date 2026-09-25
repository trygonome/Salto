class_name BeatRing
extends MeshInstance3D
## Anneau de battement au sol, autour du héros : il se resserre et s'allume à l'approche de
## chaque temps, et atteint son plus petit rayon pile sur le temps. Un appui sur Frappe le fait
## briller selon son jugement : or pour Parfait, clair pour Bien, terne à contretemps.

## Couleur de l'anneau entre deux appuis.
@export var beat_color: Color
@export var perfect_color: Color
@export var good_color: Color
@export var miss_color: Color

var _material: StandardMaterial3D
var _flash_left: float = 0.0
var _flash_color: Color


func _ready() -> void:
	_material = (material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
	material_override = _material


## Éclat après un appui jugé.
func flash(judgement: RhythmMath.Judgement) -> void:
	_flash_left = Tuning.data.judgement_flash_time
	match judgement:
		RhythmMath.Judgement.PERFECT:
			_flash_color = perfect_color
		RhythmMath.Judgement.GOOD:
			_flash_color = good_color
		_:
			_flash_color = miss_color


func _process(delta: float) -> void:
	visible = Rhythm.is_playing()
	if not visible:
		return
	var tuning: TuningData = Tuning.data
	var phase: float = Rhythm.beat_phase()
	var radius: float = lerpf(tuning.beat_ring_radius_max, tuning.beat_ring_radius_min, phase)
	var opacity: float = tuning.beat_ring_opacity * phase
	var color: Color = beat_color
	if _flash_left > 0.0:
		var strength: float = _flash_left / tuning.judgement_flash_time
		color = beat_color.lerp(_flash_color, strength)
		opacity = maxf(opacity, strength)
		_flash_left -= delta
	scale = Vector3(radius, 1.0, radius)
	transparency = 1.0 - opacity
	_material.albedo_color = color
