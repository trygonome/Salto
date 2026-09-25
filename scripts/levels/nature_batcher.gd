class_name NatureBatcher
extends Node3D
## Regroupe la nature du niveau pour le téléphone : au chargement, les maillages de ses enfants
## (arbres, rochers, buissons, herbes) sont dessinés par des MultiMesh, un par maillage et par
## case de `cell_size` mètres (la caméra ne voit que quelques cases). Les collisions restent.
## Dans l'éditeur, chaque élément reste une scène à part, facile à déplacer.

## Côté d'une case de regroupement (m).
@export var cell_size: float
## Préfixes des noms d'éléments qui ne projettent pas d'ombre (petits, au ras du sol).
@export var no_shadow_prefixes: PackedStringArray


func _ready() -> void:
	batch()


## Remplace les maillages des enfants par des MultiMesh ; renvoie le nombre de MultiMesh créés.
func batch() -> int:
	var groups: Dictionary = {}
	for element: Node in get_children():
		var element_3d: Node3D = element as Node3D
		if element_3d == null or element is MultiMeshInstance3D:
			continue
		var casts_shadow: bool = not _has_prefix(element.name)
		var cell: Vector2i = Vector2i(floori(element_3d.global_position.x / cell_size), floori(element_3d.global_position.z / cell_size))
		for node: Node in element.find_children("*", "MeshInstance3D", true, false):
			var mesh_instance: MeshInstance3D = node as MeshInstance3D
			if mesh_instance.mesh == null:
				continue
			var key: Array = [mesh_instance.mesh, cell, casts_shadow]
			if not groups.has(key):
				groups[key] = []
			groups[key].append(global_transform.affine_inverse() * mesh_instance.global_transform)
			mesh_instance.queue_free()
	for key: Array in groups:
		var transforms: Array = groups[key]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = key[0]
		multimesh.instance_count = transforms.size()
		for i: int in transforms.size():
			multimesh.set_instance_transform(i, transforms[i])
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if key[2] else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
	return groups.size()


func _has_prefix(element_name: String) -> bool:
	for prefix: String in no_shadow_prefixes:
		if element_name.begins_with(prefix):
			return true
	return false
