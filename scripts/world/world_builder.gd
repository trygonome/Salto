class_name WorldBuilder
extends Node3D
## Pose dans la scène le monde voxel généré par WorldGen : cubes (un MultiMesh par case, pour que
## la caméra ne dessine que ce qu'elle voit), sol, ombres rondes, collisions des obstacles,
## champignons-trampolines et murs invisibles au bord du monde. Convertit les unités du prototype
## en mètres.

## Matériau des cubes du décor (voxel.gdshader, transparence caméra-héros activée).
@export var voxel_material: Material
## Matériau du sol (ground.gdshader).
@export var ground_material: ShaderMaterial
## Matériau des ombres rondes (couleur multipliée par l'opacité de chaque ombre).
@export var shadow_material: Material
## Matériau de l'eau des mares (water.gdshader) ; sans lui, pas de mares.
@export var water_material: Material
## Son d'un rebond sur un champignon-trampoline.
@export var bounce_sound: AudioStream

## Les murs du bord se chevauchent un peu pour ne laisser aucune fente.
const BORDER_OVERLAP := 1.2

var gen: WorldGen

var _unit: float = 0.0


## Construit le monde ; `world` a déjà été généré. Un monde déjà construit est d'abord retiré.
func build(world: WorldGen) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.free()
	gen = world
	_unit = Tuning.data.voxel_unit
	_build_voxels()
	_build_ground()
	_build_shadows()
	_build_ponds()
	_build_solids()
	_build_border()


## Mares : un disque d'eau à ras du sol pour chacune (on y marche : elles sont peu profondes).
func _build_ponds() -> void:
	var tuning: TuningData = Tuning.data
	if water_material == null:
		return
	for i: int in gen.ponds.size() / 3:
		var plane := PlaneMesh.new()
		var r: float = gen.ponds[i * 3 + 2] * _unit
		plane.size = Vector2.ONE * r * 2.0
		var pond := MeshInstance3D.new()
		pond.name = "Pond%d" % i
		pond.mesh = plane
		pond.material_override = water_material
		pond.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pond.position = Vector3(gen.ponds[i * 3] * _unit, tuning.pond_height, gen.ponds[i * 3 + 1] * _unit)
		add_child(pond)
	var square: Material = null
	for i: int in gen.waters.size():
		if square == null:
			square = water_material.duplicate()
			(square as ShaderMaterial).set_shader_parameter(&"round", false)
		var rect: Rect2 = gen.waters[i]
		var plane := PlaneMesh.new()
		plane.size = rect.size * _unit
		var river := MeshInstance3D.new()
		river.name = "River%d" % i
		river.mesh = plane
		river.material_override = square
		river.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var center: Vector2 = rect.get_center() * _unit
		river.position = Vector3(center.x, tuning.pond_height, center.y)
		add_child(river)


## Point du monde en mètres, pour un point du prototype (x, z en u) au niveau du sol.
func to_world(p: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(p.x * Tuning.data.voxel_unit, height * Tuning.data.voxel_unit, p.y * Tuning.data.voxel_unit)


func _build_voxels() -> void:
	var tuning: TuningData = Tuning.data
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * tuning.voxel_cube_fraction
	var chunks: Dictionary = {}
	var data: PackedFloat32Array = gen.voxels
	for i: int in gen.voxel_count():
		var o: int = i * WorldGen.STRIDE
		var cell := Vector2i(floori(data[o] * _unit / tuning.world_chunk_size), floori(data[o + 2] * _unit / tuning.world_chunk_size))
		if not chunks.has(cell):
			chunks[cell] = []
		(chunks[cell] as Array).append(o)
	for cell: Vector2i in chunks:
		var offsets: Array = chunks[cell]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_custom_data = true
		multimesh.mesh = cube
		multimesh.instance_count = offsets.size()
		for k: int in offsets.size():
			var o: int = offsets[k]
			var size: float = data[o + 6] * _unit
			multimesh.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3.ONE * size), Vector3(data[o], data[o + 1], data[o + 2]) * _unit))
			multimesh.set_instance_custom_data(k, Color(data[o + 3], data[o + 4], data[o + 5], 0.0))
		var instance := MultiMeshInstance3D.new()
		instance.name = "Voxels_%d_%d" % [cell.x, cell.y]
		instance.multimesh = multimesh
		instance.material_override = voxel_material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)


func _build_ground() -> void:
	var tuning: TuningData = Tuning.data
	# Terre battue des sentiers (version 3.4 ; aucune au village).
	if ground_material:
		ground_material.set_shader_parameter(&"trail_segments", gen.tracks)
		ground_material.set_shader_parameter(&"trail_styles", gen.track_styles)
		ground_material.set_shader_parameter(&"trail_count", gen.tracks.size())
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * tuning.world_ground_size
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	ground.material_override = ground_material
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)


func _build_shadows() -> void:
	var tuning: TuningData = Tuning.data
	var disc: ArrayMesh = BlobShadow.disc(tuning.shadow_segments)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = disc
	var count: int = gen.shadows.size() / 4
	multimesh.instance_count = count
	for i: int in count:
		var x: float = gen.shadows[i * 4] * _unit
		var z: float = gen.shadows[i * 4 + 1] * _unit
		var r: float = gen.shadows[i * 4 + 2] * _unit
		multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(r, 1.0, r)), Vector3(x, tuning.shadow_height, z)))
		multimesh.set_instance_color(i, Color(1.0, 1.0, 1.0, gen.shadows[i * 4 + 3]))
	var instance := MultiMeshInstance3D.new()
	instance.name = "Shadows"
	instance.multimesh = multimesh
	instance.material_override = shadow_material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


## Sol, obstacles (cylindres) et champignons-trampolines.
func _build_solids() -> void:
	var tuning: TuningData = Tuning.data
	var body := StaticBody3D.new()
	body.name = "Solids"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = WorldBoundaryShape3D.new()
	body.add_child(floor_shape)
	for s: WorldGen.Solid in gen.solids:
		var height: float = tuning.world_wall_height if s.h >= WorldGen.WALL else s.h * _unit
		var cylinder := CylinderShape3D.new()
		cylinder.radius = s.r * _unit
		cylinder.height = height
		var shape := CollisionShape3D.new()
		shape.shape = cylinder
		shape.position = Vector3(s.x * _unit, height / 2.0, s.z * _unit)
		body.add_child(shape)
		if s.kind == WorldGen.BOUNCE:
			_add_bounce_pad(s)
	# Estrades, plateformes et passerelles : des boîtes pleines depuis le sol.
	for i: int in gen.boxes.size():
		var rect: Rect2 = gen.boxes[i]
		var height: float = gen.box_heights[i] * _unit
		var box := BoxShape3D.new()
		box.size = Vector3(rect.size.x * _unit, height, rect.size.y * _unit)
		var shape := CollisionShape3D.new()
		shape.shape = box
		var center: Vector2 = rect.get_center() * _unit
		shape.position = Vector3(center.x, height / 2.0, center.y)
		body.add_child(shape)


func _add_bounce_pad(s: WorldGen.Solid) -> void:
	var pad := BouncePad.new()
	pad.position = Vector3(s.x * _unit, s.h * _unit, s.z * _unit)
	pad.radius = s.r * _unit
	pad.sound = bounce_sound
	add_child(pad)


## Murs invisibles au bord du monde : en cercle, ou (version 3.4) des poteaux serrés le long des
## sentiers et des recoins.
func _build_border() -> void:
	var tuning: TuningData = Tuning.data
	var body := StaticBody3D.new()
	body.name = "Border"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	if not gen.fence.is_empty():
		for p: Vector2 in gen.fence:
			var post := CylinderShape3D.new()
			post.radius = WorldGen.FENCE_R * _unit
			post.height = tuning.world_wall_height
			var shape := CollisionShape3D.new()
			shape.shape = post
			shape.position = Vector3(p.x * _unit, tuning.world_wall_height / 2.0, p.y * _unit)
			body.add_child(shape)
		return
	var radius: float = gen.border_radius * _unit + tuning.world_border_thickness / 2.0
	var count: int = tuning.world_border_segments
	var width: float = TAU * radius / count * BORDER_OVERLAP
	for i: int in count:
		var a: float = TAU * i / count
		var box := BoxShape3D.new()
		box.size = Vector3(width, tuning.world_wall_height, tuning.world_border_thickness)
		var shape := CollisionShape3D.new()
		shape.shape = box
		shape.position = Vector3(cos(a) * radius, tuning.world_wall_height / 2.0, sin(a) * radius)
		shape.rotation.y = -a + PI / 2.0
		body.add_child(shape)
