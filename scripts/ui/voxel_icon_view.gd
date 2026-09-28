class_name VoxelIconView
extends SubViewportContainer
## Une icône voxel vivante dans l'interface (version 3.2) : la figure (VoxelIcons) tourne doucement
## sur elle-même, dans sa petite scène à part (caméra orthographique, fond transparent). Immobile
## (`animated` faux), elle n'est dessinée qu'une fois.

## Matériau des petits assemblages (voxel_actor.tres) : partagé par toutes les icônes.
static var icon_material: Material

## Balancement (radians), vitesse (tours par seconde), inclinaison vers la caméra (radians).
const SWAY := 0.6
const SPEED := 0.18
const TILT := 0.35
## Part du cadre occupée par la figure (7 cubes de haut).
const FILL := 8.4

var animated: bool = true

var _viewport: SubViewport
var _pivot: Node3D
var _mesh: MultiMeshInstance3D
var _time: float = 0.0


## Nouvelle icône de `size` px montrant les cubes `cells` (VoxelIcons.cells / boon).
static func create(cells: PackedFloat32Array, size: float, animate: bool = true) -> VoxelIconView:
	var view := VoxelIconView.new()
	view.animated = animate
	view.custom_minimum_size = Vector2.ONE * size
	view.stretch = true
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view._build(cells)
	return view


func _build(cells: PackedFloat32Array) -> void:
	if icon_material == null:
		icon_material = load("res://scenes/world/voxel_actor.tres") as Material
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE if animated else SubViewport.UPDATE_ONCE
	add_child(_viewport)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = FILL
	camera.position = Vector3(0.0, 0.0, 20.0)
	camera.far = 40.0
	_viewport.add_child(camera)
	_pivot = Node3D.new()
	_pivot.rotation.x = TILT * 0.3
	_viewport.add_child(_pivot)
	set_cells(cells)


## Change la figure montrée.
func set_cells(cells: PackedFloat32Array) -> void:
	if _mesh:
		_mesh.queue_free()
	_mesh = VoxelMesh.create(cells, icon_material)
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pivot.add_child(_mesh)
	if not animated:
		_pivot.rotation.y = SWAY * 0.5
		_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _process(delta: float) -> void:
	if not animated or not is_visible_in_tree():
		return
	_time += delta
	_pivot.rotation.y = sin(_time * TAU * SPEED) * SWAY
	_pivot.position.y = sin(_time * TAU * SPEED * 2.0) * 0.12
