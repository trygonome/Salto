class_name DanceAim
extends Node3D
## Visée d'une danse au sol (version 4.1), pendant qu'on tient le bouton Danse : une ligne dorée
## là où partira l'onde (ou le rayon), un anneau là où tombera la pluie de pas. Sans glisser, elle
## montre la Sourdine que la visée automatique a choisie.

## Largeur de la ligne (m), épaisseur de l'anneau (m), hauteur au-dessus du sol (m), couleur.
const LINE_WIDTH := 0.14
const RING_WIDTH := 0.12
const LIFT := 0.06
const COLOR := Color(1.0, 0.85, 0.3, 0.55)

var _line: MeshInstance3D
var _ring: MeshInstance3D


func _ready() -> void:
	top_level = true
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = COLOR
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var plane := PlaneMesh.new()
	plane.size = Vector2(LINE_WIDTH, 1.0)
	_line = MeshInstance3D.new()
	_line.mesh = plane
	_line.material_override = material
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_line)
	var torus := TorusMesh.new()
	torus.inner_radius = 1.0 - RING_WIDTH
	torus.outer_radius = 1.0
	torus.rings = 32
	torus.ring_segments = 4
	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.material_override = material
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	visible = false


## Montre la visée de `figure` depuis `origin` : direction et point visé (voir Hero.dance_aim).
func show_aim(figure: StringName, origin: Vector3, direction: Vector3, point: Vector3) -> void:
	var tuning: TuningData = Tuning.data
	visible = true
	var rain: bool = figure == DanceMath.RAIN
	_ring.visible = rain
	_line.visible = true
	var length: float = tuning.dance_thread_length if figure == DanceMath.THREAD else tuning.dance_range
	if rain:
		length = Vector2(point.x - origin.x, point.z - origin.z).length()
		_ring.global_position = Vector3(point.x, origin.y + LIFT, point.z)
		_ring.scale = Vector3.ONE * tuning.dance_rain_radius
	var yaw: float = HeroMotion.yaw_of(direction)
	_line.global_transform = Transform3D(Basis(Vector3.UP, yaw), origin + direction * length / 2.0 + Vector3.UP * LIFT)
	_line.scale = Vector3(1.0, 1.0, length)
