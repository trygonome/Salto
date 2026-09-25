class_name DamageNumber
extends Label3D
## Chiffre de dégâts : petit, près du point d'impact, il monte et s'efface.

@export var normal_color: Color
@export var critical_color: Color
## Taille relative d'un coup critique.
@export var critical_scale: float


func play(damage: float, critical: bool) -> void:
	var tuning: TuningData = Tuning.data
	text = str(roundi(damage))
	modulate = critical_color if critical else normal_color
	if critical:
		scale = Vector3.ONE * critical_scale
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y + tuning.damage_number_rise, tuning.damage_number_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, tuning.damage_number_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(queue_free)
