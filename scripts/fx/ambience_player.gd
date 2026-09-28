class_name AmbiencePlayer
extends AudioStreamPlayer
## Ambiance de la forêt (version 4.0) : de vraies prises de forêt tropicale, une par lieu —
## sous-bois amazonien, fleuve et grenouilles des Ruines, oiseaux de la Canopée, nuit au village.
## Changer de lieu fond l'ancienne ambiance dans la nouvelle.

## Boucle d'ambiance de chaque lieu (régions d'expédition et village).
const STREAMS: Dictionary[StringName, AudioStream] = {
	&"undergrowth": preload("res://assets/audio/ambience/undergrowth.ogg"),
	&"sunken": preload("res://assets/audio/ambience/sunken.ogg"),
	&"canopy": preload("res://assets/audio/ambience/canopy.ogg"),
	&"village": preload("res://assets/audio/ambience/village.ogg"),
}

## Lieu dont on entend l'ambiance.
var place: StringName = &""
var _fade: Tween


func _ready() -> void:
	volume_db = Tuning.data.ambience_volume_db
	if stream == null:
		play_place(&"village")


## Fait entendre l'ambiance de `where` (sans effet si c'est déjà elle).
func play_place(where: StringName) -> void:
	var next: AudioStream = STREAMS.get(where, STREAMS[&"undergrowth"])
	if where == place and playing:
		return
	place = where
	var tuning: TuningData = Tuning.data
	if _fade:
		_fade.kill()
	if not playing or stream == null or not is_inside_tree():
		stream = next
		volume_db = tuning.ambience_volume_db
		if is_inside_tree():
			play()
		return
	_fade = create_tween()
	_fade.tween_property(self, ^"volume_db", tuning.music_silent_db, tuning.ambience_fade_time * 0.5)
	_fade.tween_callback(_swap.bind(next))
	_fade.tween_property(self, ^"volume_db", tuning.ambience_volume_db, tuning.ambience_fade_time * 0.5)


func _swap(next: AudioStream) -> void:
	stream = next
	play()
