class_name Effects
extends Node3D
## Effets du prototype, partagés par tout le niveau : petits cubes qui jaillissent et rebondissent
## (et poussière), anneaux qui s'élargissent au sol, étincelles d'impact, un mot qui monte près de
## sa source (un seul à la fois, comme le veut la charte). Un seul nœud par niveau (groupe
## « effects ») ; chacun le trouve avec Effects.of().
## Les tailles et vitesses sont en mètres ; les teintes de 0 à 1 (-1 : au hasard).

## Couleurs des effets de la nuit.
@export var white: Color
@export var gold: Color
@export var pink: Color
@export var cyan: Color
@export var red: Color
@export var violet: Color
@export var green: Color
@export var block_color: Color
@export var stun_color: Color
## Matériaux : cubes voxel (voxel_actor.tres) et anneaux (ring.tres).
@export var cube_material: Material
@export var ring_material: ShaderMaterial

## Couleur codée d'un cube de poussière (voir salto_voxel.gdshaderinc).
const DUST_COLOR := Vector3(2.1, 0.25, 0.82)
## Cubes d'éclat : arc-en-ciel (mode 3), saturation et luminosité.
const BURST_MODE := 3.0
const BURST_SATURATION := 1.0
const BURST_LIGHTNESS := 0.6
## Couleur codée des éclats d'une bulle de silence.
const ORB_HUE := 0.78
const HUE_RANGE := 0.99

var _multimesh: MultiMesh
var _count: int = 0
var _next: int = 0
var _alive: int = 0
## État des cubes : vie, vie de départ, position, vitesse, taille, rotation, gravité, sol.
var _life := PackedFloat32Array()
var _max := PackedFloat32Array()
var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _size := PackedFloat32Array()
var _rot := PackedFloat32Array()
var _gravity := PackedFloat32Array()
var _floor := PackedFloat32Array()
var _rings: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _word: Label3D
var _word_time: float = -1.0
var _word_origin := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


## Nœud d'effets du niveau de `node`, ou null (tests sans niveau).
static func of(node: Node) -> Effects:
	if node == null or not node.is_inside_tree():
		return null
	return node.get_tree().get_first_node_in_group(&"effects") as Effects


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	add_to_group(&"effects")
	_rng.randomize()
	_count = tuning.fx_cube_count
	_life.resize(_count)
	_max.resize(_count)
	_size.resize(_count)
	_rot.resize(_count)
	_gravity.resize(_count)
	_floor.resize(_count)
	_pos.resize(_count)
	_vel.resize(_count)
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_custom_data = true
	_multimesh.mesh = VoxelMesh.cube()
	_multimesh.instance_count = _count
	for i: int in _count:
		_multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
	_multimesh.visible_instance_count = 0
	var cubes := MultiMeshInstance3D.new()
	cubes.name = "Cubes"
	cubes.multimesh = _multimesh
	cubes.material_override = cube_material
	cubes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Les cubes bougent à chaque image (et non au pas de physique) : pas d'interpolation.
	cubes.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cubes.custom_aabb = AABB(Vector3.ONE * -tuning.fx_cull_margin, Vector3.ONE * tuning.fx_cull_margin * 2.0)
	add_child(cubes)
	_word = Label3D.new()
	_word.name = "Word"
	_word.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_word.no_depth_test = true
	_word.render_priority = tuning.fx_word_priority
	_word.outline_render_priority = tuning.fx_word_priority - 1
	_word.font_size = tuning.fx_word_font_size
	_word.outline_size = tuning.fx_word_outline
	_word.pixel_size = tuning.fx_word_pixel_size
	_word.outline_modulate = tuning.fx_word_outline_color
	_word.visible = false
	add_child(_word)


## Cubes qui jaillissent de `at` : `count` cubes lancés jusqu'à `speed` m/s, de teinte `hue`
## (un peu variée ; -1 : couleurs au hasard) ; ou poussière (`dust`) : plus petite et lente.
func burst(at: Vector3, count: int, speed: float, hue: float = -1.0, dust: bool = false) -> void:
	var tuning: TuningData = Tuning.data
	for k: int in count:
		var i: int = _next
		_next = (_next + 1) % _count
		var angle: float = _rng.randf() * TAU
		var v: float = speed * _rng.randf_range(tuning.fx_speed_min, 1.0)
		var life: float = _rng.randf_range(tuning.fx_dust_life_min, tuning.fx_dust_life_max) if dust else _rng.randf_range(tuning.fx_cube_life_min, tuning.fx_cube_life_max)
		var spread: float = tuning.fx_dust_spread if dust else 0.0
		_life[i] = life
		_max[i] = life
		_pos[i] = at + Vector3(_rng.randf_range(-spread, spread), 0.0, _rng.randf_range(-spread, spread))
		var up: float = _rng.randf_range(tuning.fx_dust_rise_min, tuning.fx_dust_rise_max) if dust else _rng.randf_range(tuning.fx_cube_rise_min, tuning.fx_cube_rise_max)
		_vel[i] = Vector3(cos(angle) * v, up, sin(angle) * v)
		_size[i] = _rng.randf_range(tuning.fx_dust_size_min, tuning.fx_dust_size_max) if dust else _rng.randf_range(tuning.fx_cube_size_min, tuning.fx_cube_size_max)
		_rot[i] = _rng.randf() * TAU
		_gravity[i] = tuning.fx_dust_gravity if dust else tuning.fx_cube_gravity
		_floor[i] = maxf(tuning.fx_floor_min, at.y - (tuning.fx_dust_floor_drop if dust else tuning.fx_cube_floor_drop))
		var color: Vector3 = DUST_COLOR
		if not dust:
			var h: float = _rng.randf() if hue < 0.0 else fposmod(hue + _rng.randf_range(-tuning.fx_hue_jitter, tuning.fx_hue_jitter), 1.0)
			color = Vector3(BURST_MODE + h * HUE_RANGE, BURST_SATURATION, BURST_LIGHTNESS)
		_multimesh.set_instance_custom_data(i, Color(color.x, color.y, color.z, 0.0))
	_alive = _count
	_multimesh.visible_instance_count = _count


## Poussière au sol autour de `at`.
func dust(at: Vector3, count: int, speed: float) -> void:
	burst(at + Vector3.UP * Tuning.data.fx_dust_lift, count, speed, -1.0, true)


## Anneau au sol qui s'élargit jusqu'à `radius` m en `duration` s ; `rainbow` : il change de couleur.
func ring(at: Vector3, radius: float, color: Color, duration: float, rainbow: bool = false) -> void:
	var slot: Dictionary = {}
	for r: Dictionary in _rings:
		if not r[&"on"]:
			slot = r
			break
	if slot.is_empty():
		var mesh := MeshInstance3D.new()
		mesh.mesh = _ring_mesh()
		var material: ShaderMaterial = ring_material.duplicate() as ShaderMaterial
		mesh.material_override = material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mesh)
		slot = {&"mesh": mesh, &"material": material}
		_rings.append(slot)
	var node: MeshInstance3D = slot[&"mesh"]
	node.global_position = at + Vector3.UP * Tuning.data.fx_ring_lift
	node.visible = true
	slot[&"on"] = true
	slot[&"t"] = 0.0
	slot[&"duration"] = duration
	slot[&"radius"] = radius
	slot[&"rainbow"] = rainbow
	(slot[&"material"] as ShaderMaterial).set_shader_parameter(&"color", color)
	_update_ring(slot)


## Étincelle d'impact en `at`, de `size` m.
func spark(at: Vector3, size: float, color: Color) -> void:
	var slot: Dictionary = {}
	for s: Dictionary in _sparks:
		if not s[&"on"]:
			slot = s
			break
	if slot.is_empty():
		var sprite := Sprite3D.new()
		sprite.texture = _spark_texture()
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.no_depth_test = true
		sprite.shaded = false
		sprite.render_priority = Tuning.data.fx_word_priority
		sprite.pixel_size = 1.0 / sprite.texture.get_width()
		add_child(sprite)
		slot = {&"sprite": sprite}
		_sparks.append(slot)
	var node: Sprite3D = slot[&"sprite"]
	node.global_position = at
	node.modulate = color
	node.rotation.z = _rng.randf() * TAU
	node.visible = true
	slot[&"on"] = true
	slot[&"t"] = 0.0
	slot[&"size"] = size
	_update_spark(slot)


## Mot qui monte au-dessus de `at` (au plus un à la fois : le nouveau remplace l'ancien).
func word(text: String, at: Vector3, color: Color, big: bool = false) -> void:
	var tuning: TuningData = Tuning.data
	_word.text = text
	_word.modulate = color
	_word.font_size = tuning.fx_word_font_size_big if big else tuning.fx_word_font_size
	_word_origin = at
	_word_time = 0.0
	_word.visible = true
	_update_word()


## Muet libéré : une gerbe de cubes de toutes les couleurs, quelques cubes dorés, un anneau blanc.
func muet_freed(at: Vector3, height: float, boss: bool) -> void:
	var tuning: TuningData = Tuning.data
	burst(at + Vector3.UP * height * tuning.fx_freed_burst_height, tuning.fx_freed_boss_cubes if boss else tuning.fx_freed_cubes, tuning.fx_freed_boss_speed if boss else tuning.fx_freed_speed)
	burst(at + Vector3.UP * height, tuning.fx_freed_gold_cubes, tuning.fx_freed_gold_speed, tuning.fx_gold_hue)
	ring(at, tuning.fx_freed_boss_ring if boss else tuning.fx_freed_ring, white, tuning.fx_freed_ring_time)


## Frappe au sol du Grand Muet : anneau rouge, cubes rouges.
func slam(at: Vector3, radius: float) -> void:
	var tuning: TuningData = Tuning.data
	ring(at, radius + tuning.fx_slam_ring_extra, red, tuning.fx_slam_ring_time)
	burst(at + Vector3.UP * tuning.fx_slam_burst_height, tuning.fx_slam_cubes, tuning.fx_slam_speed, tuning.fx_red_hue)


## Coup arrêté par un bouclier.
func blocked(at: Vector3) -> void:
	var tuning: TuningData = Tuning.data
	burst(at, tuning.fx_block_cubes, tuning.fx_block_speed, tuning.fx_gold_hue)
	word(GameTexts.WORD_BLOCKED, at, block_color)


## Cornu assommé contre un obstacle.
func stunned_against_wall(at: Vector3) -> void:
	var tuning: TuningData = Tuning.data
	burst(at, tuning.fx_stun_cubes, tuning.fx_stun_speed, tuning.fx_stun_hue)
	word(GameTexts.WORD_STUNNED, at, stun_color, true)


## Bulle de silence qui éclate.
func orb_popped(at: Vector3) -> void:
	var tuning: TuningData = Tuning.data
	burst(at, tuning.fx_orb_cubes, tuning.fx_orb_speed, ORB_HUE)


func _process(delta: float) -> void:
	_update_cubes(delta)
	for slot: Dictionary in _rings:
		if slot[&"on"]:
			slot[&"t"] = float(slot[&"t"]) + delta / float(slot[&"duration"])
			_update_ring(slot)
	for slot: Dictionary in _sparks:
		if slot[&"on"]:
			slot[&"t"] = float(slot[&"t"]) + delta / Tuning.data.fx_spark_time
			_update_spark(slot)
	if _word_time >= 0.0:
		_word_time += delta / Tuning.data.fx_word_time
		_update_word()


func _update_cubes(delta: float) -> void:
	if _alive == 0:
		return
	var tuning: TuningData = Tuning.data
	var any: bool = false
	for i: int in _count:
		if _life[i] <= 0.0:
			continue
		_life[i] -= delta
		if _life[i] <= 0.0:
			_multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
			continue
		any = true
		var v: Vector3 = _vel[i]
		v.y -= _gravity[i] * delta
		var p: Vector3 = _pos[i] + v * delta
		if p.y < _floor[i]:
			p.y = _floor[i]
			v.y *= -tuning.fx_bounce
			v.x *= tuning.fx_bounce_friction
			v.z *= tuning.fx_bounce_friction
		_vel[i] = v
		_pos[i] = p
		_rot[i] += delta * tuning.fx_cube_spin
		var s: float = _size[i] * minf(1.0, _life[i] / _max[i] * tuning.fx_shrink)
		var basis := Basis.from_euler(Vector3(_rot[i], _rot[i] * tuning.fx_cube_spin_ratio, 0.0)).scaled(Vector3.ONE * s)
		_multimesh.set_instance_transform(i, Transform3D(basis, p - global_position))
	if not any:
		_alive = 0
		_multimesh.visible_instance_count = 0


func _update_ring(slot: Dictionary) -> void:
	var t: float = float(slot[&"t"])
	var node: MeshInstance3D = slot[&"mesh"]
	if t >= 1.0:
		slot[&"on"] = false
		node.visible = false
		return
	var tuning: TuningData = Tuning.data
	var eased: float = 1.0 - pow(1.0 - t, 3.0)
	var size: float = float(slot[&"radius"]) * (tuning.fx_ring_start + (1.0 - tuning.fx_ring_start) * eased)
	node.scale = Vector3(size, 1.0, size)
	var material: ShaderMaterial = slot[&"material"]
	material.set_shader_parameter(&"opacity", 1.0 - t)
	if slot[&"rainbow"]:
		material.set_shader_parameter(&"color", Color.from_hsv(fmod(t * tuning.fx_rainbow_turns, 1.0), 1.0, 1.0))


func _update_spark(slot: Dictionary) -> void:
	var t: float = float(slot[&"t"])
	var node: Sprite3D = slot[&"sprite"]
	if t >= 1.0:
		slot[&"on"] = false
		node.visible = false
		return
	node.scale = Vector3.ONE * float(slot[&"size"]) * (Tuning.data.fx_spark_start + t)
	node.modulate.a = 1.0 - t * t


func _update_word() -> void:
	var tuning: TuningData = Tuning.data
	if _word_time >= 1.0:
		_word_time = -1.0
		_word.visible = false
		return
	var t: float = _word_time
	_word.global_position = _word_origin + Vector3.UP * t * tuning.fx_word_rise
	var pop: float = EffectsMath.pop(t, tuning)
	_word.scale = Vector3.ONE * pop
	_word.modulate.a = 1.0 - maxf(0.0, (t - tuning.fx_word_fade_start) / (1.0 - tuning.fx_word_fade_start))


## Anneau plat de rayon 1 (bord intérieur à Tuning.fx_ring_inner).
func _ring_mesh() -> ArrayMesh:
	var tuning: TuningData = Tuning.data
	var vertices := PackedVector3Array()
	var segments: int = tuning.fx_ring_segments
	for i: int in segments:
		var a0: float = TAU * i / segments
		var a1: float = TAU * (i + 1) / segments
		var o0 := Vector3(cos(a0), 0.0, sin(a0))
		var o1 := Vector3(cos(a1), 0.0, sin(a1))
		var i0: Vector3 = o0 * tuning.fx_ring_inner
		var i1: Vector3 = o1 * tuning.fx_ring_inner
		vertices.append_array([i0, o1, o0, i0, i1, o1])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Étoile lumineuse du prototype : seize branches, dégradé du centre vers le bord.
static var _star: ImageTexture


static func _spark_texture() -> ImageTexture:
	if _star:
		return _star
	var tuning: TuningData = Tuning.data
	var size: int = tuning.fx_spark_texture_size
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center: float = size / 2.0
	for y: int in size:
		for x: int in size:
			var d := Vector2(x + 0.5 - center, y + 0.5 - center)
			var angle: float = fposmod(d.angle(), TAU)
			var reach: float = EffectsMath.star_reach(angle) * center
			var alpha: float = 0.0
			if d.length() <= reach:
				alpha = clampf(1.0 - d.length() / center, 0.0, 1.0)
				alpha = minf(1.0, alpha * tuning.fx_spark_glow)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_star = ImageTexture.create_from_image(image)
	return _star
