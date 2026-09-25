class_name VoxelMesh
## Petits assemblages de cubes colorés (parties des personnages, Muets, tambours) : un MultiMesh
## dont chaque cube porte sa couleur codée (mode + teinte, saturation, luminosité, voir
## scenes/world/voxel.gdshader). Les cellules sont rangées comme dans WorldGen : x, y, z, teinte,
## saturation, luminosité, taille — en cases (la scène met l'ensemble à l'échelle).

static var _cube: BoxMesh


## Cube partagé par tous les assemblages.
static func cube() -> BoxMesh:
	if _cube == null:
		_cube = BoxMesh.new()
		_cube.size = Vector3.ONE * Tuning.data.voxel_cube_fraction
	return _cube


static func create(cells: PackedFloat32Array, material: Material) -> MultiMeshInstance3D:
	var count: int = cells.size() / WorldGen.STRIDE
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = cube()
	multimesh.instance_count = count
	for i: int in count:
		var o: int = i * WorldGen.STRIDE
		multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * cells[o + 6]), Vector3(cells[o], cells[o + 1], cells[o + 2])))
		multimesh.set_instance_custom_data(i, Color(cells[o + 3], cells[o + 4], cells[o + 5], 0.0))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## Ajoute une cellule.
static func add(cells: PackedFloat32Array, x: float, y: float, z: float, color: Vector3, size: float = 1.0) -> void:
	cells.append_array(PackedFloat32Array([x, y, z, color.x, color.y, color.z, size]))


## Remplit la boîte [x0, x1] × [y0, y1] × [z0, z1] de cellules centrées sur les demi-cases (comme
## box() du prototype) ; `paint(x, y, z)` donne la couleur de chacune (Vector3) ou null pour la sauter.
static func box(cells: PackedFloat32Array, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, paint: Callable) -> void:
	var x: float = x0 + 0.5
	while x < x1:
		var y: float = y0 + 0.5
		while y < y1:
			var z: float = z0 + 0.5
			while z < z1:
				var color: Variant = paint.call(x, y, z)
				if color != null:
					add(cells, x, y, z, color)
				z += 1.0
			y += 1.0
		x += 1.0
