class_name MuetBody
extends Node3D
## Apparence d'un Muet en voxels, comme dans le prototype (makeMuet, animEnemy) : une boule de
## cubes qui s'écrase et rebondit comme de la gelée (bonds, coups reçus), respire, cligne des yeux,
## bat des ailes, lève son bouclier ; ses yeux tournent quand il est étourdi. Touché, il brille ;
## en rage, il rougit ; libéré, il retrouve ses couleurs, grossit un peu et disparaît.
## Un seul maillage articulé (VoxelRig) : corps, yeux, ailes, bouclier.

## Forme (hop, fly, shield, charge, spit ; voir MuetShapes), Grand Muet, Roi Muet.
@export var kind: StringName = &"hop"
@export var boss: bool
@export var king: bool
## Matériau des assemblages articulés (voxel_rig.tres) ; chaque Muet en a sa copie (éclat, rage).
@export var material: ShaderMaterial
@export var shadow_material: Material

## Hauteur du corps (m), connue après setup().
var height: float = 0.0
## Orientation visée (rad) : le corps y tourne à sa vitesse (turn_rate, rad/s).
var target_yaw: float = 0.0
var turn_rate: float = 0.0

var rig: VoxelRig
var _material: ShaderMaterial
var _rng := RandomNumberGenerator.new()
var _cell: float = 0.0
var _center: float = 0.0
var _eyes: int = -1
var _wings: PackedInt32Array = []
var _wing_rest: Array[Vector3] = []
var _shield: int = -1
var _shield_rest := Vector3.ZERO
var _squash: float = 0.0
var _squash_speed: float = 0.0
var _hit_left: float = 0.0
var _flash_left: float = 0.0
var _flash_time: float = 0.0
var _blink: float = 0.0
var _time: float = 0.0
var _flap_phase: float = 0.0
var _stunned: bool = false
var _enraged: bool = false
var _freed: bool = false
var _block_left: float = 0.0
## Élan du moment (voir set_motion) : bond, penché en avant, gonflé, piqué.
var _hopping: bool = false
var _lean: float = 0.0
var _inflate: float = 0.0
var _crouch: bool = false
var _swooping: bool = false


## Construit le corps : `cell_size` (m par case) donne la taille de l'espèce, `shadow_radius` (m)
## celle de son ombre.
func setup(cell_size: float, shadow_radius: float) -> void:
	var tuning: TuningData = Tuning.data
	_rng.randomize()
	_cell = cell_size
	_blink = _rng.randf_range(tuning.muet_blink_min, tuning.muet_blink_max)
	_flap_phase = _rng.randf() * TAU
	var tip: int = _rng.randi_range(0, tuning.muet_tip_variants - 1)
	var shape: Dictionary = MuetShapes.build(kind, boss, king, float(tip) / tuning.muet_tip_variants)
	var r: float = shape[&"radius"]
	height = MuetShapes.height(r) * cell_size
	_center = MuetShapes.center_height(r) * cell_size
	_material = material.duplicate() as ShaderMaterial
	rig = VoxelRig.new()
	rig.name = "Rig"
	rig.add_part(&"body", &"", Vector3.ZERO, shape[&"body"])
	rig.add_part(&"eyes", &"body", Vector3.ZERO, shape[&"eyes"])
	for side: String in ["left", "right"]:
		if shape.has(StringName("wing_" + side)):
			rig.add_part(StringName("wing_" + side), &"body", shape[StringName("wing_%s_at" % side)], shape[StringName("wing_" + side)])
	if shape.has(&"shield"):
		rig.add_part(&"shield", &"body", shape[&"shield_at"], shape[&"shield"])
	rig.build(_material, "muet_%s_%s_%s_%d" % [kind, boss, king, tip])
	add_child(rig)
	_eyes = rig.bone(&"eyes")
	for side: String in ["left", "right"]:
		var wing: int = rig.bone(StringName("wing_" + side))
		if wing >= 0:
			_wings.append(wing)
			_wing_rest.append(shape[StringName("wing_%s_at" % side)])
	_shield = rig.bone(&"shield")
	if _shield >= 0:
		_shield_rest = shape[&"shield_at"]
	var shadow := BlobShadow.new()
	shadow.name = "Shadow"
	shadow.radius = shadow_radius
	shadow.material = shadow_material
	add_child(shadow)
	_pose(0.0)


## Donne un élan au ressort du corps : positif, il s'étire (départ d'un bond) ; négatif, il
## s'écrase (atterrissage, coup reçu).
func squash(impulse: float) -> void:
	_squash_speed += impulse


## Coup reçu : il brille et se tasse un instant.
func flash(duration: float) -> void:
	_flash_time = duration
	_flash_left = duration
	_hit_left = Tuning.data.muet_hit_time
	squash(-Tuning.data.muet_squash_hit)


func set_stunned(stunned: bool) -> void:
	_stunned = stunned


func set_enraged(enraged: bool) -> void:
	_enraged = enraged


## Bouclier levé un instant (coup bloqué).
func raise_shield() -> void:
	_block_left = Tuning.data.shielder_block_time


## Élan du moment : en plein bond (il ne respire pas), penché en avant (charge, piqué : rad),
## gonflé (crachat, frappe qui se prépare : part de sa taille en plus), tassé (charge ou coup de
## bouclier annoncé), en piqué (ailes plus lentes).
func set_motion(hopping: bool, lean: float, inflate: float, crouch: bool, swooping: bool) -> void:
	_hopping = hopping
	_lean = lean
	_inflate = inflate
	_crouch = crouch
	_swooping = swooping


## Libération : les couleurs reviennent, le corps grossit un peu puis disparaît en `duration` s.
func play_freed(duration: float) -> void:
	_freed = true
	_stunned = false
	var tween: Tween = create_tween()
	tween.tween_property(_material, "shader_parameter/vivid", 1.0, duration / 2.0)
	tween.parallel().tween_property(self, "scale", Vector3.ONE * Tuning.data.muet_freed_pop_scale, duration / 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector3.ZERO, duration / 2.0).set_ease(Tween.EASE_IN)


## Bonne réponse : ses couleurs reviennent un instant (part `amount` de l'arc-en-ciel), puis
## repartent en `duration` secondes.
func glimmer(amount: float, duration: float) -> void:
	if _freed:
		return
	_material.set_shader_parameter(&"vivid", amount)
	var tween: Tween = create_tween()
	tween.tween_property(_material, "shader_parameter/vivid", 0.0, duration).set_ease(Tween.EASE_IN)


## Libéré pour de bon (troupe du village) : ses couleurs lui sont rendues.
func show_healed() -> void:
	_freed = true
	_stunned = false
	_material.set_shader_parameter(&"healed", 1.0)


## Ressort du corps (étirement positif, écrasement négatif), pour les tests.
func squash_amount() -> float:
	return _squash


func _process(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_time += delta
	_squash_speed += (-tuning.muet_squash_stiffness * _squash - tuning.muet_squash_damping * _squash_speed) * delta
	_squash = clampf(_squash + _squash_speed * delta, -tuning.muet_squash_limit, tuning.muet_squash_limit)
	_hit_left = maxf(0.0, _hit_left - delta)
	_block_left = maxf(0.0, _block_left - delta)
	if _flash_left > 0.0:
		_flash_left = maxf(_flash_left - delta, 0.0)
	_material.set_shader_parameter(&"flash", tuning.muet_hit_flash_strength * _flash_left / _flash_time if _flash_time > 0.0 else 0.0)
	_material.set_shader_parameter(&"rage", 1.0 if _enraged and not _freed else 0.0)
	rotation.y = rotate_toward(rotation.y, target_yaw, turn_rate * delta)
	_pose(delta)


func _pose(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	var sq: float = minf(_squash, -tuning.muet_squash_crouch) if _crouch else _squash
	var hit: float = _hit_left / tuning.muet_hit_time
	var grow: float = _cell * (1.0 + _inflate)
	var wide: float = 1.0 - sq * tuning.muet_squash_widen + hit * tuning.muet_hit_widen
	rig.scale = Vector3(wide, 1.0 + sq - hit * tuning.muet_hit_widen, wide) * grow
	var bob: float = 0.0 if _hopping or kind == &"fly" else sin(_time * tuning.muet_bob_speed) * tuning.muet_bob_height
	rig.position.y = _center * (1.0 + minf(0.0, sq) * tuning.muet_squash_sink) + bob
	rig.rotation.x = _lean
	_blink -= delta
	if _blink < -tuning.blink_time:
		_blink = _rng.randf_range(tuning.muet_blink_min, tuning.muet_blink_max)
	var eyes_shut: bool = _blink < 0.0 or hit > tuning.muet_hit_eyes_shut
	rig.set_part_scale(_eyes, Vector3(1.0, tuning.blink_squash if eyes_shut else 1.0, 1.0))
	rig.set_part_rotation(_eyes, Vector3(0.0, 0.0, _time * tuning.muet_stun_eye_spin if _stunned else 0.0))
	var flap_speed: float = tuning.flyer_flap_speed_swoop if _swooping else tuning.flyer_flap_speed
	var flap: float = sin(_time * flap_speed + _flap_phase) * tuning.flyer_flap_angle
	for i: int in _wings.size():
		rig.set_part_rotation(_wings[i], Vector3(0.0, 0.0, flap if i == 0 else -flap))
	if _shield >= 0:
		var up: float = 1.0 if _block_left > 0.0 else 0.0
		rig.set_part_position(_shield, _shield_rest + Vector3.UP * up * tuning.shielder_raise)
		rig.set_part_scale(_shield, Vector3.ONE * (1.0 + up * tuning.shielder_raise_scale))
