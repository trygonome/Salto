extends Control
## Garde l'interface hors des encoches et des bords arrondis de l'écran (téléphones) : les
## marges suivent la zone sûre donnée par le système.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_apply)
	_apply()


func _apply() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if not OS.has_feature("mobile"):
		return
	var window: Vector2 = Vector2(DisplayServer.window_get_size())
	var safe: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	var scale: Vector2 = get_viewport_rect().size / window
	offset_left = safe.position.x * scale.x
	offset_top = safe.position.y * scale.y
	offset_right = -(window.x - safe.end.x) * scale.x
	offset_bottom = -(window.y - safe.end.y) * scale.y
