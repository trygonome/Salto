extends GutTest
## La nature est dessinée par des MultiMesh (un par maillage et par case), sans perdre ses
## collisions ; les herbes ne projettent pas d'ombre.

const TreeScene: PackedScene = preload("res://scenes/levels/props/nature/tree_1_a.tscn")
const GrassScene: PackedScene = preload("res://scenes/levels/props/nature/grass_1_a.tscn")

var batcher: NatureBatcher


func before_each() -> void:
	batcher = NatureBatcher.new()
	batcher.cell_size = 16.0
	batcher.no_shadow_prefixes = PackedStringArray(["Grass"])
	for i: int in 3:
		var tree: Node3D = TreeScene.instantiate() as Node3D
		tree.name = "Tree%d" % i
		tree.position = Vector3(i * 3.0, 0.0, 0.0)
		batcher.add_child(tree)
	var far_tree: Node3D = TreeScene.instantiate() as Node3D
	far_tree.name = "FarTree"
	far_tree.position = Vector3(40.0, 0.0, 0.0)
	batcher.add_child(far_tree)
	var grass: Node3D = GrassScene.instantiate() as Node3D
	grass.name = "Grass1"
	batcher.add_child(grass)
	add_child_autofree(batcher)
	await get_tree().process_frame


func _multimeshes() -> Array[MultiMeshInstance3D]:
	var found: Array[MultiMeshInstance3D] = []
	for child: Node in batcher.get_children():
		if child is MultiMeshInstance3D:
			found.append(child)
	return found


func test_un_multimesh_par_maillage_et_par_case() -> void:
	var counts: Array[int] = []
	for multimesh: MultiMeshInstance3D in _multimeshes():
		counts.append(multimesh.multimesh.instance_count)
	counts.sort()
	assert_eq(counts, [1, 1, 3] as Array[int], "herbe, arbre lointain, trois arbres proches")


func test_les_maillages_d_origine_disparaissent_mais_pas_les_collisions() -> void:
	for tree: Node in batcher.find_children("Tree*", "StaticBody3D", false, false):
		assert_eq(tree.find_children("*", "MeshInstance3D", true, false).size(), 0)
		assert_eq(tree.find_children("*", "CollisionShape3D", true, false).size(), 1)


func test_les_herbes_ne_projettent_pas_d_ombre() -> void:
	for multimesh: MultiMeshInstance3D in _multimeshes():
		var is_grass: bool = multimesh.multimesh.instance_count == 1 and multimesh.multimesh.mesh.resource_path.contains("Grass")
		if is_grass:
			assert_eq(multimesh.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		else:
			assert_eq(multimesh.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
