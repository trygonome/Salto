class_name DanceWave
extends Area3D
## Vibration lancée par une danse (version 4.1) : l'onde de paume, un arc de cubes qui file droit en
## s'élargissant et traverse les Sourdines ; ou un orbe de la spirale, qui avance en tournant autour
## de la ligne visée. Elle laisse derrière elle quelques cubes dorés. Ses coups sont ceux du héros
## (dégâts, dons), sans rendre de groove : la danse le dépense.

## Figure (DanceMath.PALM ou DanceMath.SPIRAL), direction (horizontale), portée (m).
var figure: StringName = DanceMath.PALM
var direction: Vector3 = Vector3.FORWARD
var reach: float = 0.0
## Décalage de phase de l'orbe dans la spirale (radians).
var phase: float = 0.0
## Fabrique le coup pour une Hurtbox touchée (voir Hero._make_hit) ; le héros qui a dansé.
var make_hit: Callable
var shooter: Hero
## Matériau voxel.
var material: Material

## Cubes de l'onde : un arc de ARC_CELLS cases de rayon ARC_RADIUS, sur ARC_SPAN radians ; un orbe
## est un petit amas. Couleur codée : or vif (mode 1), la couleur du groove.
const ARC_CELLS := 13
const ARC_RADIUS := 6.0
const ARC_SPAN := 2.1
const ORB_CELLS: Array[Vector3] = [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, -1)]
const COLOR := Vector3(1.13, 1.0, 0.6)
const CELL := 0.12
## L'onde s'élargit en avançant : taille au départ et à la fin de sa course.
const GROW_FROM := 1.2
const GROW_TO := 2.6

var _travelled: float = 0.0
var _time: float = 0.0
var _origin: Vector3
var _hit: Array[Hurtbox] = []
var _mesh: MultiMeshInstance3D
var _trail_left: float = 0.0


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	collision_layer = 0
	collision_mask = 16
	monitorable = false
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = tuning.dance_wave_radius
	capsule.height = maxf(tuning.dance_wave_height * 2.0, capsule.radius * 2.0)
	shape.shape = capsule
	add_child(shape)
	var cells := PackedFloat32Array()
	if figure == DanceMath.SPIRAL:
		for c: Vector3 in ORB_CELLS:
			VoxelMesh.add(cells, c.x, c.y, c.z, COLOR, 0.9)
	else:
		for i: int in ARC_CELLS:
			var a: float = -ARC_SPAN / 2.0 + ARC_SPAN * i / (ARC_CELLS - 1)
			VoxelMesh.add(cells, sin(a) * ARC_RADIUS, cos(a) * ARC_RADIUS - ARC_RADIUS * 0.5, 0.0, COLOR, 0.9)
	_mesh = VoxelMesh.create(cells, material)
	_mesh.scale = Vector3.ONE * CELL * (GROW_FROM if figure == DanceMath.PALM else 1.4)
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	# Le lanceur place la vibration après l'avoir ajoutée : son point de départ est pris ici.
	if _time == 0.0:
		_origin = global_position
		look_at(global_position + direction, Vector3.UP)
	_time += delta
	if figure == DanceMath.SPIRAL:
		var before: Vector3 = global_position
		global_position = _origin + DanceMath.spiral_offset(direction, _time, phase, tuning)
		_travelled += before.distance_to(global_position)
		_mesh.rotation += Vector3(delta, delta * 1.3, 0.0) * tuning.dance_spiral_turn_speed * 0.5
	else:
		var step: float = tuning.dance_wave_speed * delta
		global_position += direction * step
		_travelled += step
		_mesh.scale = Vector3.ONE * CELL * lerpf(GROW_FROM, GROW_TO, minf(1.0, _travelled / maxf(reach, 0.01)))
	_trail_left -= delta
	if _trail_left <= 0.0:
		_trail_left = tuning.dance_spark_period
		var fx: Effects = Effects.of(self)
		if fx:
			fx.burst(global_position, 1, tuning.fx_charge_speed * 0.5, tuning.fx_gold_hue)
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
	# Un orbe de la spirale s'éteint au premier contact ; l'onde de paume traverse.
	if figure == DanceMath.SPIRAL:
		queue_free()
