class_name SilenceOrb
extends Node3D
## Bulle de silence crachée par un cracheur : elle file droit à hauteur de poitrine, tourne sur
## elle-même, éclate contre un obstacle, au bout de sa course, ou sur le héros (qu'elle blesse,
## sauf s'il roule à travers : esquive parfaite). Un plongeon la fait éclater.

## Matériau voxel des petits assemblages (voxel_actor.tres).
@export var material: Material

## Direction (horizontale, normalisée), dégâts et Muet qui l'a crachée (fixés au départ).
var direction: Vector3 = Vector3.FORWARD
var damage: float = 0.0
var source: Node3D

var _life: float = 0.0
var _time: float = 0.0
var _dodged: bool = false

@onready var _visual: Node3D = $Visual


## Un seul gros cube sombre, comme dans le prototype.
const COLOR := Vector3(2.8, 0.75, 0.2)


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	_life = tuning.spitter_orb_life
	add_to_group(&"silence_orbs")
	var cells := PackedFloat32Array()
	VoxelMesh.add(cells, 0.0, 0.0, 0.0, COLOR)
	_visual.add_child(VoxelMesh.create(cells, material))
	_visual.scale = Vector3.ONE * tuning.voxel_unit


func _physics_process(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_time += delta
	_life -= delta
	global_position += direction * tuning.spitter_orb_speed * delta
	_visual.rotation = Vector3(_time * tuning.orb_spin_x, _time * tuning.orb_spin_y, 0.0)
	_visual.position.y = sin(_time * tuning.orb_bob_speed) * tuning.orb_bob_height
	if _life <= 0.0 or _hits_wall():
		pop()
		return
	var hero: Hero = get_tree().get_first_node_in_group(&"hero") as Hero
	if hero == null:
		return
	var flat := Vector2(hero.global_position.x - global_position.x, hero.global_position.z - global_position.z)
	var above: float = global_position.y - hero.global_position.y
	if flat.length() > tuning.spitter_orb_radius + hero.hurtbox.radius or above < -tuning.orb_hero_below or above > tuning.hero_height:
		return
	var hit := HitData.new()
	hit.attacker = source if is_instance_valid(source) else self
	hit.damage = damage
	hit.direction = direction
	hit.point = global_position
	hit.move = &"orb"
	if hero.hurtbox.receive(hit):
		pop()
	elif not _dodged:
		_dodged = true


## La bulle éclate en petits cubes sombres.
func pop() -> void:
	var fx: Effects = Effects.of(self)
	if fx:
		fx.orb_popped(global_position)
	queue_free()


func _hits_wall() -> bool:
	var tuning: TuningData = Tuning.data
	var query := PhysicsRayQueryParameters3D.create(global_position, global_position + direction * (tuning.spitter_orb_radius + tuning.spitter_orb_speed * get_physics_process_delta_time()), 1)
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()
