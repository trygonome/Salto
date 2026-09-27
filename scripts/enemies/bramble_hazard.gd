class_name BrambleHazard
extends Node3D
## Ronces du tisserand : un buisson d'épines en cubes qui pousse, pique le héros qui s'y tient
## (au plus une fois toutes les Tuning.weaver_bramble_tick s ; la roulade passe à travers), puis se
## fane au bout de Tuning.weaver_bramble_time s.

## Matériau voxel des petits assemblages (voxel_actor.tres).
@export var material: Material

## Dégâts d'une piqûre et Muet qui l'a tissée (fixés au départ).
var damage: float = 0.0
var source: Node3D

var _age: float = 0.0
var _tick: float = 0.0
var _visual: Node3D

## Couleurs codées : tiges vertes sombres, épines claires.
const STEM := Vector3(2.3, 0.55, 0.22)
const THORN := Vector3(2.16, 0.35, 0.72)


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	add_to_group(&"hazards")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(global_position)
	var cells := PackedFloat32Array()
	var reach: float = tuning.weaver_bramble_radius / tuning.voxel_unit
	for i: int in 14:
		var a: float = rng.randf() * TAU
		var d: float = sqrt(rng.randf()) * reach * 0.85
		var x: float = cos(a) * d
		var z: float = sin(a) * d
		var h: int = rng.randi_range(2, 4)
		for y: int in h:
			VoxelMesh.add(cells, x + (y % 2) * 0.3, y + 0.5, z, STEM, 0.8)
		VoxelMesh.add(cells, x + 0.5, h, z, THORN, 0.45)
		VoxelMesh.add(cells, x - 0.5, h - 0.6, z + 0.3, THORN, 0.4)
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_visual.add_child(VoxelMesh.create(cells, material))
	_visual.scale = Vector3(1.0, 0.0, 1.0) * tuning.voxel_unit


func _physics_process(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	if delta <= 0.0:
		return
	_age += delta
	_tick -= delta
	var grow: float = minf(_age / tuning.weaver_bramble_grow, 1.0)
	var fade: float = clampf((tuning.weaver_bramble_time - _age) / tuning.weaver_bramble_grow, 0.0, 1.0)
	_visual.scale = Vector3(1.0, minf(grow, fade), 1.0) * tuning.voxel_unit
	if _age >= tuning.weaver_bramble_time:
		queue_free()
		return
	if grow < 1.0 or _tick > 0.0:
		return
	var hero: Hero = get_tree().get_first_node_in_group(&"hero") as Hero
	if hero == null:
		return
	var flat := Vector2(hero.global_position.x - global_position.x, hero.global_position.z - global_position.z)
	if flat.length() > tuning.weaver_bramble_radius or hero.global_position.y > global_position.y + tuning.hero_height:
		return
	_tick = tuning.weaver_bramble_tick
	var hit := HitData.new()
	hit.attacker = source if is_instance_valid(source) else self
	hit.damage = damage
	hit.move = &"bramble"
	hit.direction = Vector3(flat.x, 0.0, flat.y).normalized() if not flat.is_zero_approx() else Vector3.BACK
	hit.point = hero.hurtbox.center()
	hero.hurtbox.receive(hit)


## Vrai si `point` est dans les ronces (mètres).
func covers(point: Vector3) -> bool:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length() <= Tuning.data.weaver_bramble_radius
