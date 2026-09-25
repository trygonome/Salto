class_name VoxelRig
extends Node3D
## Assemblage de cubes articulé, en un seul maillage (un seul appel de dessin) : chaque partie
## (tête, bras, aile, bouclier…) est un os d'un squelette, qu'on tourne, déplace ou étire comme
## un nœud. Les cellules sont celles de VoxelMesh (x, y, z, couleur codée, taille), en cases ;
## on met l'assemblage à l'échelle avec `scale`. Les maillages identiques sont partagés (clé).

## Maillages déjà construits, par clé : {mesh, skin}.
static var _cache: Dictionary = {}
## Gabarit d'un cube (sommets, normales, indices) pris sur un BoxMesh.
static var _cube_vertices: PackedVector3Array
static var _cube_normals: PackedVector3Array
static var _cube_indices: PackedInt32Array

var skeleton: Skeleton3D
var mesh_instance: MeshInstance3D

var _names: Array[StringName] = []
var _parents: PackedInt32Array = []
var _rests: Array[Vector3] = []
var _cells: Array[PackedFloat32Array] = []


## Ajoute la partie `part_name`, accrochée à `parent` (vide : à la racine) au point `at` (en cases,
## dans le repère du parent), faite des cellules `cells` (dans son propre repère).
func add_part(part_name: StringName, parent: StringName, at: Vector3, cells: PackedFloat32Array) -> void:
	_names.append(part_name)
	_parents.append(_names.find(parent) if parent != &"" else -1)
	_rests.append(at)
	_cells.append(cells)


## Construit le squelette et le maillage. Deux assemblages de même `key` (non vide) partagent
## leur maillage : ils doivent avoir les mêmes parties et les mêmes cellules.
func build(material: Material, key: String = "") -> void:
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton"
	for i: int in _names.size():
		skeleton.add_bone(_names[i])
		if _parents[i] >= 0:
			skeleton.set_bone_parent(i, _parents[i])
		skeleton.set_bone_rest(i, Transform3D(Basis.IDENTITY, _rests[i]))
	skeleton.reset_bone_poses()
	add_child(skeleton)
	var built: Dictionary = _cache.get(key, {}) if key != "" else {}
	if built.is_empty():
		built = _build_mesh()
		if key != "":
			_cache[key] = built
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	mesh_instance.mesh = built[&"mesh"]
	mesh_instance.skin = built[&"skin"]
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.extra_cull_margin = Tuning.data.voxel_rig_cull_margin
	skeleton.add_child(mesh_instance)


func bone(part_name: StringName) -> int:
	return _names.find(part_name)


## Rotation d'une partie (radians, dans l'ordre X puis Y puis Z comme les Euler du prototype).
func set_part_rotation(part: int, euler: Vector3) -> void:
	skeleton.set_bone_pose_rotation(part, Basis.from_euler(euler, EULER_ORDER_XYZ).get_rotation_quaternion())


## Position d'une partie (en cases, dans le repère de son parent).
func set_part_position(part: int, at: Vector3) -> void:
	skeleton.set_bone_pose_position(part, at)


func set_part_scale(part: int, size: Vector3) -> void:
	skeleton.set_bone_pose_scale(part, size)


## Nombre de cubes d'un assemblage de cellules.
static func cell_count(cells: PackedFloat32Array) -> int:
	return cells.size() / WorldGen.STRIDE


func _build_mesh() -> Dictionary:
	_prepare_cube()
	var total: int = 0
	for cells: PackedFloat32Array in _cells:
		total += cell_count(cells)
	var per_cube: int = _cube_vertices.size()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedFloat32Array()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var indices := PackedInt32Array()
	vertices.resize(total * per_cube)
	normals.resize(total * per_cube)
	colors.resize(total * per_cube * 3)
	bones.resize(total * per_cube * 4)
	weights.resize(total * per_cube * 4)
	indices.resize(total * _cube_indices.size())
	var globals: Array[Vector3] = []
	var skin := Skin.new()
	var cube_size: float = Tuning.data.voxel_cube_fraction
	var v: int = 0
	var n: int = 0
	for part: int in _names.size():
		var origin: Vector3 = _rests[part] + (globals[_parents[part]] if _parents[part] >= 0 else Vector3.ZERO)
		globals.append(origin)
		skin.add_named_bind(_names[part], Transform3D(Basis.IDENTITY, -origin))
		var cells: PackedFloat32Array = _cells[part]
		for c: int in cell_count(cells):
			var o: int = c * WorldGen.STRIDE
			var center := Vector3(cells[o], cells[o + 1], cells[o + 2]) + origin
			var size: float = cells[o + 6] * cube_size
			for i: int in _cube_indices.size():
				indices[n + i] = v + _cube_indices[i]
			n += _cube_indices.size()
			for k: int in per_cube:
				vertices[v] = center + _cube_vertices[k] * size
				normals[v] = _cube_normals[k]
				colors[v * 3] = cells[o + 3]
				colors[v * 3 + 1] = cells[o + 4]
				colors[v * 3 + 2] = cells[o + 5]
				bones[v * 4] = part
				weights[v * 4] = 1.0
				v += 1
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_CUSTOM0] = colors
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_CUSTOM_RGB_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	return {&"mesh": mesh, &"skin": skin}


static func _prepare_cube() -> void:
	if not _cube_vertices.is_empty():
		return
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var arrays: Array = box.get_mesh_arrays()
	_cube_vertices = arrays[Mesh.ARRAY_VERTEX]
	_cube_normals = arrays[Mesh.ARRAY_NORMAL]
	_cube_indices = arrays[Mesh.ARRAY_INDEX]
