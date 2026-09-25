class_name FadingBurst
extends Node3D
## Effet bref (étincelle, onde) : grandit de `start_scale` à `end_scale` en s'effaçant, puis disparaît.
## `play` fixe la durée et un facteur de taille (le rayon de l'onde, par exemple).

## Taille relative au début de l'effet.
@export var start_scale: float
## Taille relative à la fin de l'effet.
@export var end_scale: float
## Élément dont l'opacité diminue (Sprite3D ou GeometryInstance3D avec transparence).
@export var fading: GeometryInstance3D


## Colore l'effet : lueur d'un maillage, ou teinte d'un sprite.
func tint(color: Color) -> void:
	var sprite: Sprite3D = fading as Sprite3D
	if sprite:
		sprite.modulate = color
		return
	var mesh_instance: MeshInstance3D = fading as MeshInstance3D
	var material: StandardMaterial3D = mesh_instance.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
	material.emission = color
	mesh_instance.material_override = material


func play(duration: float, size: float) -> void:
	scale = Vector3.ONE * start_scale * size
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector3.ONE * end_scale * size, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(fading, "transparency", 1.0, duration).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
