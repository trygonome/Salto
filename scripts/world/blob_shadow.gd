class_name BlobShadow
extends MeshInstance3D
## Ombre ronde sous un personnage, comme dans le prototype : un disque sombre posé sur le sol sous
## son parent, qui rapetisse quand le parent s'élève (saut, salto). Le sol est cherché sous le
## parent (rocher, souche) ; sans sol trouvé, l'ombre reste au niveau du sol du monde.

## Rayon de l'ombre (m).
@export var radius: float
@export var material: Material

## Disque partagé par toutes les ombres.
static var _disc: ArrayMesh

var _ground_y: float = 0.0


func _ready() -> void:
	if _disc == null:
		_disc = disc(Tuning.data.shadow_segments)
	mesh = _disc
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_follow()


## Disque horizontal de rayon 1 (éventail de triangles), comme la CircleGeometry du prototype.
static func disc(segments: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	for i: int in segments:
		var a0: float = TAU * i / segments
		var a1: float = TAU * (i + 1) / segments
		vertices.append_array([Vector3.ZERO, Vector3(cos(a1), 0.0, sin(a1)), Vector3(cos(a0), 0.0, sin(a0))])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result


func _physics_process(_delta: float) -> void:
	var tuning: TuningData = Tuning.data
	var from: Vector3 = (get_parent() as Node3D).global_position + Vector3.UP * tuning.shadow_ray_start
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * tuning.shadow_ray_length, 1)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	_ground_y = (hit[&"position"] as Vector3).y if not hit.is_empty() else 0.0


func _process(_delta: float) -> void:
	_follow()


func _follow() -> void:
	var tuning: TuningData = Tuning.data
	var at: Vector3 = (get_parent() as Node3D).get_global_transform_interpolated().origin
	var lift: float = maxf(0.0, at.y - _ground_y)
	var size: float = radius * (1.0 - minf(tuning.shadow_shrink_max, lift / tuning.shadow_shrink_height))
	global_transform = Transform3D(Basis.from_scale(Vector3(size, 1.0, size)), Vector3(at.x, _ground_y + tuning.shadow_height, at.z))
