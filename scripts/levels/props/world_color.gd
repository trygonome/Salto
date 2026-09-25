extends WorldEnvironment
## Couleurs du monde : la nuit commence terne, et chaque tambour rapporté rend des couleurs.


func _ready() -> void:
	environment.adjustment_enabled = true
	environment.adjustment_saturation = Game.world_saturation()
	Game.drum_returned.connect(_on_drum_returned)


func _on_drum_returned(_count: int) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(environment, "adjustment_saturation", Game.world_saturation(), Tuning.data.night_saturation_fade_time)
