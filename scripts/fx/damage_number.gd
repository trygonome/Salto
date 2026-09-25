class_name DamageNumber
extends Label3D
## Chiffre de dégâts : petit, près du point d'impact, il jaillit, monte et s'efface. En rose,
## précédé d'un moins : les PV perdus par le héros.

@export var normal_color: Color
@export var critical_color: Color
@export var hurt_color: Color
## Taille relative d'un coup critique.
@export var critical_scale: float


func play(damage: float, critical: bool, hurt: bool = false) -> void:
	var tuning: TuningData = Tuning.data
	text = ("-%d" if hurt else "%d") % roundi(damage)
	modulate = hurt_color if hurt else (critical_color if critical else normal_color)
	var size: float = critical_scale if critical else 1.0
	scale = Vector3.ONE * size * tuning.fx_word_pop_start
	var pop: Tween = create_tween()
	pop.tween_property(self, "scale", Vector3.ONE * size * tuning.fx_word_pop_peak, tuning.damage_number_time * tuning.fx_word_pop_time)
	pop.tween_property(self, "scale", Vector3.ONE * size, tuning.damage_number_time * tuning.fx_word_pop_time)
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y + tuning.damage_number_rise, tuning.damage_number_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, tuning.damage_number_time).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(queue_free)
