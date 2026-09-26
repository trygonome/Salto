class_name DebugOverlay
extends Label
## Infos de mise au point, pour les versions de test (éditeur, ou export marqué « test_build »,
## en débogage comme en version optimisée), quand le réglage « Infos techniques » est coché :
## images par seconde, moteur de rendu, taille de l'écran, orientation, temps de la musique, puis la ligne
## `debug_text()` du premier nœud du groupe « debug_info » (le héros).


func _ready() -> void:
	Game.settings_changed.connect(_refresh)
	_refresh()


## Vrai si les infos de mise au point peuvent être affichées (versions de test seulement).
static func available() -> bool:
	return OS.is_debug_build() or OS.has_feature("test_build")


func _refresh() -> void:
	visible = available() and Game.profile.debug_info
	set_process(visible)


func _process(_delta: float) -> void:
	var size: Vector2i = DisplayServer.window_get_size()
	var orientation: String = "portrait" if size.y > size.x else "paysage"
	text = "%d i/s · %s (%s)\n%d × %d · %s\n%s · Godot %s" % [
		roundi(Engine.get_frames_per_second()),
		RenderingServer.get_current_rendering_method(),
		RenderingServer.get_current_rendering_driver_name(),
		size.x,
		size.y,
		orientation,
		OS.get_model_name(),
		Engine.get_version_info()["string"],
	]
	if Rhythm.is_playing():
		text += "\nmusique %.1f s · couches %d/%d · troupe %.0f %%" % [Rhythm.song_time(), Rhythm.audible_layers(), Rhythm.NIGHT_LAYERS.size(), Rhythm.band_amount() * 100.0]
	else:
		text += "\nmusique arrêtée"
	var source: Node = get_tree().get_first_node_in_group(&"debug_info")
	if source:
		text += "\n" + String(source.call(&"debug_text"))
