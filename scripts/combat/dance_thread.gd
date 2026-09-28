class_name DanceThread
extends Node3D
## Fil d'écho (version 4.1) : tant que le héros tient la danse, un rayon de vibration part du bout de
## ses doigts ; on le balaie en glissant le pouce. Il frappe à petits coups réguliers toutes les
## Sourdines qu'il traverse, et boit le groove.

## Fabrique le coup pour une Hurtbox touchée (voir Hero._make_hit) ; le héros qui danse.
var make_hit: Callable
var shooter: Hero

var _beam: MeshInstance3D
var _material: StandardMaterial3D
var _tick_left: float = 0.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _time: float = 0.0

## Épaisseur du rayon (m) et sa pulsation.
const THICKNESS := 0.22
const PULSE := 0.35
const PULSE_SPEED := 18.0


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color = Color(1.0, 0.86, 0.35, 0.8)
	_material.emission_enabled = true
	_material.emission = Color(1.0, 0.8, 0.3)
	var box := BoxMesh.new()
	box.size = Vector3(THICKNESS, THICKNESS, 1.0)
	_beam = MeshInstance3D.new()
	_beam.mesh = box
	_beam.material_override = _material
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)
	_tick_left = 0.0


## Place le rayon de `from` (le bout des doigts) à `to`.
func aim(from: Vector3, to: Vector3) -> void:
	_from = from
	_to = to
	var length: float = from.distance_to(to)
	if length < 0.01:
		return
	global_position = (from + to) / 2.0
	look_at(to, Vector3.UP)
	_beam.scale = Vector3(1.0, 1.0, length)


## Le temps passe : le rayon pulse et, à chaque coup, frappe ce qu'il traverse. Renvoie le nombre
## de Sourdines touchées.
func tick(delta: float) -> int:
	var tuning: TuningData = Tuning.data
	_time += delta
	var pulse: float = 1.0 + PULSE * sin(_time * PULSE_SPEED)
	_beam.scale.x = pulse
	_beam.scale.y = pulse
	_tick_left -= delta
	if _tick_left > 0.0:
		return 0
	_tick_left = tuning.dance_thread_tick
	var touched: int = 0
	if is_instance_valid(shooter):
		for node: Node in get_tree().get_nodes_in_group(&"muets"):
			var muet: Muet = node as Muet
			if muet == null or muet.is_freed():
				continue
			if DanceMath.distance_to_segment(muet.global_position, _from, _to) > tuning.dance_thread_width + muet.hurtbox.radius:
				continue
			var hit: HitData = make_hit.call(muet.hurtbox)
			if muet.hurtbox.receive(hit):
				shooter.hitbox.landed.emit(hit, muet.hurtbox)
				touched += 1
	var fx: Effects = Effects.of(self)
	if fx:
		fx.burst(_to, 1, tuning.fx_charge_speed * 0.5, tuning.fx_gold_hue)
	return touched
