extends Control
## Garde l'interface hors des encoches et des bords arrondis de l'écran (téléphones) : les
## marges suivent la zone sûre donnée par le système.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_apply)
	_apply()


func _apply() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var insets: Vector4 = SafeInsets.of(get_viewport())
	offset_left = insets.x
	offset_top = insets.y
	offset_right = -insets.z
	offset_bottom = -insets.w
