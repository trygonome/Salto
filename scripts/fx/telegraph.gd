class_name Telegraph
extends MeshInstance3D
## Annonce d'une attaque de Muet : un cercle ou une ligne rouge au sol qui se remplit jusqu'à
## l'instant où l'attaque part, avec un son d'annonce. Disparaît ensuite d'elle-même.

## Hauteur au-dessus du sol, pour ne pas se mélanger au sol (m).
@export var ground_offset: float

var _duration: float = 0.0
var _elapsed: float = 0.0
var _material: ShaderMaterial


func _ready() -> void:
	add_to_group(&"telegraphs")
	_material = (material_override as ShaderMaterial).duplicate() as ShaderMaterial
	material_override = _material
	($Sound as AudioStreamPlayer3D).play()


## Cercle de `radius` mètres centré en `center`, rempli en `duration` secondes.
func show_circle(center: Vector3, radius: float, duration: float) -> void:
	_start(duration, false)
	global_position = center + Vector3.UP * ground_offset
	scale = Vector3(radius * 2.0, 1.0, radius * 2.0)


## Ligne de `from` à `to`, large de `width` mètres, remplie en `duration` secondes.
func show_line(from: Vector3, to: Vector3, width: float, duration: float) -> void:
	_start(duration, true)
	var flat_from := Vector3(from.x, from.y, from.z)
	var along: Vector3 = Vector3(to.x - from.x, 0.0, to.z - from.z)
	global_position = flat_from + along / 2.0 + Vector3.UP * ground_offset
	rotation.y = atan2(-along.z, along.x)
	scale = Vector3(along.length(), 1.0, width)


## Déplace une ligne déjà affichée (le cornu suit le héros pendant le premier temps).
func move_line(from: Vector3, to: Vector3, width: float) -> void:
	var along: Vector3 = Vector3(to.x - from.x, 0.0, to.z - from.z)
	global_position = from + along / 2.0 + Vector3.UP * ground_offset
	rotation.y = atan2(-along.z, along.x)
	scale = Vector3(along.length(), 1.0, width)


func _start(duration: float, is_line: bool) -> void:
	_duration = duration
	_elapsed = 0.0
	_material.set_shader_parameter(&"is_line", is_line)
	_material.set_shader_parameter(&"progress", 0.0)


func _process(delta: float) -> void:
	_elapsed += delta
	_material.set_shader_parameter(&"progress", minf(_elapsed / _duration, 1.0))
	if _elapsed >= _duration:
		queue_free()
