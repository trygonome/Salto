class_name ShockWaveHazard
extends Node3D
## Onde de choc du Grand Muet en rage : un anneau qui s'élargit au sol. Quand son front passe
## le héros, il est touché s'il a les pieds au sol ; s'il est en l'air, il gagne du groove.

## Dégâts infligés au héros resté au sol (fixés par le Grand Muet).
var damage: float = 0.0

var _radius: float = 0.0
var _passed_hero: bool = false

@onready var _ring: Node3D = $Ring


func _physics_process(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_radius += tuning.boss_wave_speed * delta
	_ring.scale = Vector3(_radius, 1.0, _radius)
	var hero: Hero = get_tree().get_first_node_in_group(&"hero") as Hero
	if hero and not _passed_hero:
		var flat: Vector3 = hero.global_position - global_position
		flat.y = 0.0
		if flat.length() <= _radius:
			_passed_hero = true
			if hero.global_position.y - global_position.y < tuning.boss_wave_clearance:
				var hit := HitData.new()
				hit.attacker = self
				hit.damage = damage
				hit.direction = flat.normalized() if not flat.is_zero_approx() else Vector3.BACK
				hit.point = hero.global_position
				hit.move = &"wave"
				hero.hurtbox.receive(hit)
			else:
				hero.on_wave_jumped()
	if _radius >= tuning.boss_wave_range:
		queue_free()
