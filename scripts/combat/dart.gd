class_name Dart
extends Area3D
## Fléchette de la sarbacane (version 2.8) : elle file droit, touche le premier Muet (ou tous ceux
## qu'elle traverse), puis tombe à sa portée. Ses coups sont ceux du héros (dégâts, rythme, dons).

## Direction (horizontale), vitesse (m/s), portée (m), traverse-t-elle les Muets ?
var direction: Vector3 = Vector3.FORWARD
var speed: float = 0.0
var reach: float = 0.0
var pierce: bool = false
## Fabrique le coup pour une Hurtbox touchée (voir Hero._make_hit) ; le héros qui a tiré.
var make_hit: Callable
var shooter: Hero
## Matériau voxel de la fléchette.
var material: Material

## Cubes de la fléchette (cases) : longueur, couleurs codées (bambou, plume rose).
const LENGTH := 4
const SHAFT := Vector3(2.28, 0.5, 0.7)
const FEATHER := Vector3(2.95, 0.85, 0.65)
const CELL := 0.07

var _travelled: float = 0.0
var _hit: Array[Hurtbox] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = 16
	monitorable = false
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = Tuning.data.dart_radius
	shape.shape = sphere
	add_child(shape)
	var cells := PackedFloat32Array()
	for i: int in LENGTH:
		VoxelMesh.add(cells, 0.0, 0.0, -i, SHAFT if i > 0 else FEATHER, 0.8)
	var mesh: MultiMeshInstance3D = VoxelMesh.create(cells, material)
	mesh.scale = Vector3.ONE * CELL
	add_child(mesh)
	look_at(global_position + direction, Vector3.UP)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	var step: float = speed * delta
	global_position += direction * step
	_travelled += step
	if _travelled >= reach:
		queue_free()


func _on_area_entered(area: Area3D) -> void:
	var hurtbox: Hurtbox = area as Hurtbox
	if hurtbox == null or _hit.has(hurtbox) or not is_instance_valid(shooter) or hurtbox == shooter.hurtbox:
		return
	_hit.append(hurtbox)
	var hit: HitData = make_hit.call(hurtbox)
	if hurtbox.receive(hit):
		shooter.hitbox.landed.emit(hit, hurtbox)
	if not pierce:
		queue_free()
