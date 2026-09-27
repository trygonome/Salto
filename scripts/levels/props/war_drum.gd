class_name WarDrum
extends Node3D
## Tambour de guerre (version 2.6) : un grand tambour posé dans la clairière. Le frapper fait
## gronder une onde : les Muets autour sont étourdis et ébranlés, le groove monte. Il lui faut
## ensuite un moment pour se recharger ; prêt, il bat au rythme de la musique.

## Modèle voxel du tambour (drum_model.tscn), son de la frappe.
var model_scene: PackedScene
var sound: AudioStream

## Battement du tambour prêt : gonflement puis retour (s).
const PULSE_UP := 0.05
const PULSE_DOWN := 0.15

var _left: float = 0.0
var _model: Node3D
var _player: AudioStreamPlayer3D
var _hurtbox: Hurtbox


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	add_to_group(&"war_drums")
	if model_scene:
		_model = model_scene.instantiate() as Node3D
		_model.scale = Vector3.ONE * tuning.war_drum_scale
		add_child(_model)
	_player = AudioStreamPlayer3D.new()
	_player.stream = sound
	add_child(_player)
	_hurtbox = Hurtbox.new()
	_hurtbox.name = "Hurtbox"
	_hurtbox.collision_layer = 16
	_hurtbox.collision_mask = 0
	_hurtbox.monitoring = false
	_hurtbox.radius = tuning.war_drum_radius
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = tuning.war_drum_radius
	capsule.height = tuning.war_drum_radius * 3.0
	shape.shape = capsule
	shape.position = Vector3.UP * tuning.war_drum_radius * 1.5
	_hurtbox.add_child(shape)
	add_child(_hurtbox)
	_hurtbox.hurt.connect(_on_hurt)
	Rhythm.beat.connect(_on_beat)


func is_ready() -> bool:
	return _left <= 0.0


func _physics_process(delta: float) -> void:
	_left = maxf(_left - delta, 0.0)


func _on_beat(_index: int) -> void:
	if is_ready() and _model:
		var tuning: TuningData = Tuning.data
		var tween: Tween = create_tween()
		tween.tween_property(_model, "scale", Vector3.ONE * tuning.war_drum_scale * tuning.war_drum_pulse, PULSE_UP)
		tween.tween_property(_model, "scale", Vector3.ONE * tuning.war_drum_scale, PULSE_DOWN)


func _on_hurt(hit: HitData) -> void:
	if not is_ready() or not hit.attacker is Hero:
		return
	boom(hit.attacker as Hero)


## L'onde du tambour : les Muets à portée sont étourdis et ébranlés.
func boom(hero: Hero) -> void:
	var tuning: TuningData = Tuning.data
	_left = tuning.war_drum_cooldown
	if _player.stream:
		_player.play()
	Feedback.shake(tuning.shake_trauma_dive, Vector3.ZERO)
	var fx: Effects = Effects.of(self)
	if fx:
		fx.ring(global_position, tuning.war_drum_reach, fx.gold, tuning.fx_break_ring_time, true)
		fx.burst(global_position + Vector3.UP, tuning.fx_break_cubes, tuning.fx_break_speed, tuning.fx_gold_hue)
	if hero:
		hero.groove.add(tuning.groove_answer * hero.stats.groove)
	for node: Node in get_tree().get_nodes_in_group(&"muets"):
		var muet: Muet = node as Muet
		if muet.is_freed() or muet.flat_distance_to(global_position) > tuning.war_drum_reach:
			continue
		if not muet.take_poise(tuning.war_drum_poise):
			muet.stun(tuning.war_drum_stun)
