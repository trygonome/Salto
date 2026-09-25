extends Label
## Infos de mise au point, visibles seulement dans les versions de test :
## images par seconde, moteur de rendu, taille de l'écran, orientation, puis la ligne
## `debug_text()` du premier nœud du groupe « debug_info » (le héros).


func _ready() -> void:
	visible = OS.is_debug_build()
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
	var source: Node = get_tree().get_first_node_in_group(&"debug_info")
	if source:
		text += "\n" + String(source.call(&"debug_text"))
