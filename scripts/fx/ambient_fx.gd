class_name AmbientFx
extends Node3D
## Vie de la clairière (version 2.5) : des lucioles qui flottent et palpitent (elles brillent : le
## halo de l'écran les fait rayonner), quelques feuilles qui tombent en tournoyant. Particules
## légères (CPU), valables aussi pour le web.

## Couleurs des lucioles (au-delà de 1 : elles rayonnent) et des feuilles.
const FIREFLY_COLOR := Color(2.4, 2.2, 0.9)
const LEAF_COLORS: Array[Color] = [Color(0.45, 0.7, 0.25), Color(0.75, 0.62, 0.2), Color(0.35, 0.55, 0.3)]

var _fireflies: CPUParticles3D
var _leaves: CPUParticles3D


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	_fireflies = _make(tuning.fireflies, tuning.firefly_life, tuning.firefly_size, true)
	_fireflies.name = "Fireflies"
	_fireflies.gravity = Vector3.ZERO
	_fireflies.initial_velocity_min = 0.05
	_fireflies.initial_velocity_max = 0.25
	_fireflies.spread = 180.0
	var pulse := Curve.new()
	pulse.add_point(Vector2(0.0, 0.0))
	pulse.add_point(Vector2(0.2, 1.0))
	pulse.add_point(Vector2(0.5, 0.4))
	pulse.add_point(Vector2(0.75, 1.0))
	pulse.add_point(Vector2(1.0, 0.0))
	_fireflies.scale_amount_curve = pulse
	_fireflies.color = FIREFLY_COLOR
	add_child(_fireflies)
	_leaves = _make(tuning.falling_leaves, tuning.leaf_life, tuning.leaf_size, false)
	_leaves.name = "Leaves"
	_leaves.gravity = Vector3.DOWN * tuning.leaf_fall_speed
	_leaves.initial_velocity_min = 0.1
	_leaves.initial_velocity_max = 0.3
	_leaves.angular_velocity_min = -180.0
	_leaves.angular_velocity_max = 180.0
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray(LEAF_COLORS)
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	_leaves.color_initial_ramp = ramp
	add_child(_leaves)


## Étend les particules sur une clairière de `radius` m de rayon.
func setup(radius: float) -> void:
	var tuning: TuningData = Tuning.data
	_fireflies.emission_box_extents = Vector3(radius, tuning.firefly_height / 2.0, radius)
	_fireflies.position = Vector3.UP * tuning.firefly_height / 2.0
	_leaves.emission_box_extents = Vector3(radius, tuning.firefly_height, radius)
	_leaves.position = Vector3.UP * tuning.firefly_height * 2.0
	_fireflies.restart()
	_leaves.restart()


func _make(amount: int, life: float, size: float, glowing: bool) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = life
	particles.preprocess = life
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.local_coords = false
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glowing:
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	quad.material = material
	particles.mesh = quad
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles
