extends MuetState
## Gardien des Ruines, pluie de piliers : il lève les bras ; un cercle s'annonce sous le héros à
## chaque temps (trois fois) ; à la fin de chaque annonce, un pilier de pierre s'abat : qui est
## dessous prend un gros coup. Les piliers retombent en poussière. On s'en sort en bougeant au rythme.

## Matériau voxel des piliers (voxel_actor.tres).
@export var pillar_material: Material

## Pierre du pilier (couleur codée : fixe, bue par le silence).
const STONE := Vector3(4.58, 0.12, 0.42)

var _left: float = 0.0
var _placed: int = 0


func enter(_previous: StringName) -> void:
	_placed = 0
	_left = muet.beats_to_seconds(Tuning.data.boss_pillar_count + 1)
	_place()


func on_beat(_index: int) -> void:
	if _placed < Tuning.data.boss_pillar_count:
		_place()


func physics_update(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	muet.body.set_motion(false, 0.0, tuning.boss_slam_inflate, false, false)
	muet.move(Vector3.ZERO, delta)
	_left -= delta
	if _left <= 0.0:
		machine.transition_to(&"Hop")


## Un cercle sous le héros ; le pilier tombe un temps plus tard.
func _place() -> void:
	var tuning: TuningData = Tuning.data
	_placed += 1
	var hero: Hero = muet.get_tree().get_first_node_in_group(&"hero") as Hero
	if hero == null:
		return
	var at := Vector3(hero.global_position.x, muet.post.y, hero.global_position.z)
	var duration: float = muet.beats_to_seconds(1)
	muet.telegraph().show_circle(at, tuning.boss_pillar_radius, duration)
	var damage: float = muet.damage_of(&"slam_damage") * tuning.boss_pillar_damage_factor
	var parent: Node = muet.get_parent()
	muet.get_tree().create_timer(duration, false).timeout.connect(_fall.bind(at, damage, parent))


func _fall(at: Vector3, damage: float, parent: Node) -> void:
	var tuning: TuningData = Tuning.data
	if not is_instance_valid(parent):
		return
	var cells := PackedFloat32Array()
	var n: int = ceili(tuning.boss_pillar_radius / tuning.voxel_unit * 0.6)
	for y: int in tuning.boss_pillar_height:
		for x: int in range(-n, n + 1):
			for z: int in range(-n, n + 1):
				if Vector2(x, z).length() <= n:
					VoxelMesh.add(cells, x, y + 0.5, z, STONE)
	var pillar: MultiMeshInstance3D = VoxelMesh.create(cells, pillar_material)
	pillar.scale = Vector3.ONE * tuning.voxel_unit
	parent.add_child(pillar)
	pillar.global_position = at + Vector3.UP * tuning.boss_pillar_drop
	var tween: Tween = pillar.create_tween()
	tween.tween_property(pillar, "global_position:y", at.y, tuning.trap_rise_time)
	tween.tween_interval(tuning.boss_pillar_linger)
	tween.tween_property(pillar, "scale:y", 0.0, tuning.boss_pillar_sink)
	tween.tween_callback(pillar.queue_free)
	Feedback.shake(tuning.shake_trauma_hit, Vector3.ZERO)
	var fx: Effects = Effects.of(parent)
	if fx:
		fx.dust(at, tuning.fx_impact_dust, tuning.fx_impact_dust_speed)
	var hero: Hero = parent.get_tree().get_first_node_in_group(&"hero") as Hero
	if hero == null or Vector2(hero.global_position.x - at.x, hero.global_position.z - at.z).length() > tuning.boss_pillar_radius:
		return
	var hit := HitData.new()
	hit.damage = damage
	hit.big = true
	hit.move = &"pillar"
	var flat := Vector3(hero.global_position.x - at.x, 0.0, hero.global_position.z - at.z)
	hit.direction = flat.normalized() if not flat.is_zero_approx() else Vector3.BACK
	hit.point = hero.hurtbox.center()
	hero.hurtbox.receive(hit)
