class_name DanceRain
extends Node3D
## Pluie de pas (version 4.1) : là où le héros a visé, un anneau doré se resserre un instant, puis
## la vibration éclate et frappe toutes les Sourdines dans son rayon. Il faut anticiper : elles
## bougent pendant qu'elle tombe.

## Fabrique le coup pour une Hurtbox touchée (voir Hero._make_hit) ; le héros qui a dansé.
var make_hit: Callable
var shooter: Hero

var _left: float = -1.0


func _physics_process(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	# Le lanceur place la pluie après l'avoir ajoutée : l'anneau d'annonce part ici.
	if _left < 0.0:
		_left = tuning.dance_rain_delay
		var fx: Effects = Effects.of(self)
		if fx:
			fx.ring(global_position, tuning.dance_rain_radius, fx.gold, tuning.dance_rain_delay)
	_left -= delta
	if _left <= 0.0:
		_burst()
		queue_free()


func _burst() -> void:
	var tuning: TuningData = Tuning.data
	if is_instance_valid(shooter):
		for node: Node in get_tree().get_nodes_in_group(&"muets"):
			var muet: Muet = node as Muet
			if muet == null or muet.is_freed() or muet.flat_distance_to(global_position) > tuning.dance_rain_radius + muet.hurtbox.radius:
				continue
			var hit: HitData = make_hit.call(muet.hurtbox)
			if muet.hurtbox.receive(hit):
				shooter.hitbox.landed.emit(hit, muet.hurtbox)
	Feedback.shake(tuning.shake_trauma_hit, Vector3.ZERO)
	var fx: Effects = Effects.of(self)
	if fx:
		fx.ring(global_position, tuning.dance_rain_radius, fx.gold, tuning.fx_dive_ring_time, true)
		fx.burst(global_position + Vector3.UP * tuning.fx_double_height, tuning.fx_quake_cubes, tuning.fx_quake_speed, tuning.fx_gold_hue)
		fx.dust(global_position, tuning.fx_dive_dust, tuning.fx_dive_dust_speed)
