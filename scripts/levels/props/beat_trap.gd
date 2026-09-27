class_name BeatTrap
extends Node3D
## Piège au tempo (version 2.6), qui blesse le héros comme les Muets :
##  - épines : tous les Tuning.trap_spike_period temps, elles jaillissent du sol (un cercle rouge
##    les annonce le temps d'avant) ;
##  - liane fouet : tous les Tuning.trap_whip_period temps, une liane balaie une ligne (annoncée le
##    temps d'avant).
## Un Muet projeté dans des épines s'y blesse aussi : le rythme se joue à deux.

const SPIKES := &"spikes"
const WHIP := &"whip"
## Couleurs codées : dalle sombre, épines claires, liane verte.
const PLATE := Vector3(4.72, 0.12, 0.2)
const SPIKE := Vector3(2.1, 0.12, 0.82)
const VINE := Vector3(2.3, 0.7, 0.3)

## Genre, temps de décalage (0 : il frappe sur les temps multiples de la période), direction de la
## liane (rad, depuis le nord), annonce au sol, matériau voxel.
var kind: StringName = SPIKES
var phase: int = 0
var angle: float = 0.0
var telegraph_scene: PackedScene
var material: Material

var _spikes: Node3D
var _vine: Node3D


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	add_to_group(&"beat_traps")
	var unit: float = tuning.voxel_unit
	if kind == SPIKES:
		var plate := PackedFloat32Array()
		var spikes := PackedFloat32Array()
		var n: int = ceili(tuning.trap_spike_radius / unit)
		for x: int in range(-n, n + 1):
			for z: int in range(-n, n + 1):
				if Vector2(x, z).length() > n:
					continue
				VoxelMesh.add(plate, x, 0.1, z, PLATE, 0.95)
				if posmod(x + z, 2) == 0:
					VoxelMesh.add(spikes, x, 0.6, z, SPIKE, 0.45)
					VoxelMesh.add(spikes, x, 1.2, z, SPIKE, 0.25)
		var plate_mesh: MultiMeshInstance3D = VoxelMesh.create(plate, material)
		plate_mesh.scale = Vector3.ONE * unit
		add_child(plate_mesh)
		_spikes = Node3D.new()
		_spikes.name = "Spikes"
		var spike_mesh: MultiMeshInstance3D = VoxelMesh.create(spikes, material)
		spike_mesh.scale = Vector3.ONE * unit
		_spikes.add_child(spike_mesh)
		_spikes.scale = Vector3(1.0, tuning.trap_spike_rest, 1.0)
		add_child(_spikes)
	else:
		var vine := PackedFloat32Array()
		var cells: int = ceili(tuning.trap_whip_length / unit)
		for i: int in cells:
			VoxelMesh.add(vine, 0.0, 2.0 + sin(i * 0.8) * 0.4, -i, VINE, 0.7)
			if i % 3 == 0:
				VoxelMesh.add(vine, 0.6, 2.2, -i, Vector3(2.32, 0.8, 0.4), 0.6)
		_vine = Node3D.new()
		_vine.name = "Vine"
		var vine_mesh: MultiMeshInstance3D = VoxelMesh.create(vine, material)
		vine_mesh.scale = Vector3.ONE * unit
		_vine.add_child(vine_mesh)
		_vine.rotation.y = -angle
		_vine.scale = Vector3(1.0, 1.0, 0.05)
		add_child(_vine)
	Rhythm.beat.connect(receive_beat)


## Un temps de la musique (appelé directement dans les tests).
func receive_beat(index: int) -> void:
	var tuning: TuningData = Tuning.data
	if not is_inside_tree():
		return
	var period: int = tuning.trap_spike_period if kind == SPIKES else tuning.trap_whip_period
	var step: int = posmod(index - phase, period)
	if step == period - 1:
		_warn()
	elif step == 0:
		strike()


## Direction de la liane (horizontale, depuis son pied).
func whip_direction() -> Vector3:
	return Vector3(sin(angle), 0.0, -cos(angle))


func _warn() -> void:
	var tuning: TuningData = Tuning.data
	if telegraph_scene == null:
		return
	var mark: Telegraph = telegraph_scene.instantiate() as Telegraph
	get_parent().add_child(mark)
	var duration: float = RhythmMath.beat_length(tuning)
	if kind == SPIKES:
		mark.show_circle(global_position, tuning.trap_spike_radius, duration)
	else:
		mark.show_line(global_position, global_position + whip_direction() * tuning.trap_whip_length, tuning.trap_whip_width, duration)


## Le piège frappe : épines dressées ou liane qui balaie ; tout ce qui est dessus est touché.
func strike() -> void:
	var tuning: TuningData = Tuning.data
	var hold: float = RhythmMath.beat_length(tuning) * tuning.trap_hold_fraction
	var target: Node3D = _spikes if kind == SPIKES else _vine
	var tween: Tween = create_tween()
	if kind == SPIKES:
		tween.tween_property(target, "scale:y", 1.0, tuning.trap_rise_time)
		tween.tween_interval(hold)
		tween.tween_property(target, "scale:y", tuning.trap_spike_rest, tuning.trap_rise_time)
	else:
		tween.tween_property(target, "scale:z", 1.0, tuning.trap_rise_time)
		tween.tween_interval(hold)
		tween.tween_property(target, "scale:z", 0.05, tuning.trap_rise_time)
	var hero: Hero = get_tree().get_first_node_in_group(&"hero") as Hero
	if hero and covers(hero.global_position):
		hero.hurtbox.receive(_hit(hero.hurtbox, tuning.trap_damage, hero.global_position))
	for node: Node in get_tree().get_nodes_in_group(&"muets"):
		var muet: Muet = node as Muet
		if muet.is_freed() or muet.flies or not covers(muet.global_position):
			continue
		var hit: HitData = _hit(muet.hurtbox, tuning.trap_muet_damage, muet.global_position)
		hit.poise = tuning.trap_poise
		muet.hurtbox.receive(hit)


## Vrai si `point` (m) est dans la zone du piège.
func covers(point: Vector3) -> bool:
	var tuning: TuningData = Tuning.data
	var flat := Vector2(point.x - global_position.x, point.z - global_position.z)
	if kind == SPIKES:
		return flat.length() <= tuning.trap_spike_radius
	var dir := Vector2(sin(angle), -cos(angle))
	var along: float = flat.dot(dir)
	return along >= 0.0 and along <= tuning.trap_whip_length and absf(flat.dot(Vector2(-dir.y, dir.x))) <= tuning.trap_whip_width / 2.0


func _hit(hurtbox: Hurtbox, damage: float, at: Vector3) -> HitData:
	var hit := HitData.new()
	hit.attacker = self
	hit.target = hurtbox
	hit.damage = damage
	hit.move = &"trap"
	var flat := Vector3(at.x - global_position.x, 0.0, at.z - global_position.z)
	hit.direction = flat.normalized() if not flat.is_zero_approx() else whip_direction()
	hit.point = hurtbox.center()
	return hit
