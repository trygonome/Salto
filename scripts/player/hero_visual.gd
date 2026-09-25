class_name HeroVisual
extends Node3D
## Apparence du héros : un enfant de la jungle en voxels, comme les villageois (le personnage du
## prototype, avec sa plume). Orientation, tour complet du salto et de la roulade (qui démarrent
## et finissent en douceur, la roulade au ras du sol), rotation des coups tournoyants, corps en
## gelée qui s'étire au saut et s'écrase à l'atterrissage, tambour porté qui tourne au-dessus de
## sa tête, traînée du pied qui frappe. Les poses sont calculées par HeroAnimator.

## Matériau des assemblages articulés (voxel_rig.tres).
@export var material: Material

var character: VoxelCharacter

var _spin_time: float = 0.0
var _spin_duration: float = 0.0
var _rolling: bool = false
var _roll_drop: float = 0.0
var _yaw_offset: float = 0.0
var _squash: float = 0.0
var _squash_speed: float = 0.0
## Hanche et pied de chaque jambe (L, R), où s'accroche la traînée.
var _legs: Dictionary = {}

@onready var animator: HeroAnimator = $Animator
@onready var trail: RibbonTrail = $Trail
@onready var _carried_drum: Node3D = $CarriedDrum


## Construit le personnage à la taille du héros ; la roulade le fait descendre de `roll_drop` m.
func setup(height: float, roll_drop: float) -> void:
	var tuning: TuningData = Tuning.data
	character = VoxelCharacter.new()
	character.name = "Body"
	character.material = material
	# Le corps voxel regarde vers +z ; le héros regarde vers -z.
	character.rotation.y = PI
	add_child(character)
	character.build(VoxelStyles.hero(), height / (VoxelCharacter.HEIGHT * tuning.character_voxel * tuning.voxel_unit), "hero")
	_roll_drop = roll_drop
	for side: String in ["L", "R"]:
		_legs[side] = [_attach("hip" + side), _attach("ankle" + side)]
	_use_leg("R")
	animator.character = character


## Salto : un tour complet vers l'avant autour du centre du corps.
func play_salto(duration: float) -> void:
	_start_spin(duration, false)


## Roulade : un tour complet vers l'avant, le corps descendu près du sol.
func play_roll(duration: float) -> void:
	_start_spin(duration, true)


## Interrompt le tour en cours (roulade ou salto coupés par une autre action).
func stop_spin() -> void:
	_spin_duration = 0.0
	_rolling = false


## Vrai pendant un salto (pas une roulade).
func is_flipping() -> bool:
	return _spin_duration > 0.0 and not _rolling


## Rotation du corps autour de la verticale, en plus du regard (coups tournoyants).
func set_yaw_offset_deg(degrees: float) -> void:
	_yaw_offset = deg_to_rad(degrees)


## Élan donné au corps en gelée : positif, il s'étire (saut) ; négatif, il s'écrase.
func squash(impulse: float) -> void:
	_squash_speed += impulse


## Oriente le corps et fait avancer rotations, gelée et poses. Appelé à chaque image physique.
func update_pose(yaw: float, delta: float) -> void:
	var tuning: TuningData = Tuning.data
	rotation.y = yaw + _yaw_offset
	var spin: float = 0.0
	var drop: float = 0.0
	if _spin_duration > 0.0:
		_spin_time += delta
		var fraction: float = minf(_spin_time / _spin_duration, 1.0)
		spin = TAU * Smoothing.ease_in_out(fraction)
		if _rolling:
			drop = -_roll_drop * sin(PI * fraction)
		if fraction >= 1.0:
			stop_spin()
			spin = 0.0
			drop = 0.0
	character.spin.rotation.x = spin
	character.position.y = drop
	_squash_speed += (-tuning.hero_squash_stiffness * _squash - tuning.hero_squash_damping * _squash_speed) * delta
	_squash = clampf(_squash + _squash_speed * delta, -tuning.hero_squash_limit, tuning.hero_squash_limit)
	var wide: float = 1.0 - _squash * tuning.hero_squash_widen
	character.spin.scale = Vector3(wide, 1.0 + _squash, wide)
	_use_leg("L" if animator.kicks_with_left_leg() else "R")
	animator.update(delta, is_flipping())
	character.update_blink(delta)
	if _carried_drum.visible:
		_carried_drum.rotation.y += tuning.carried_drum_spin * delta


func _start_spin(duration: float, rolling: bool) -> void:
	_spin_time = 0.0
	_spin_duration = duration
	_rolling = rolling


func _use_leg(side: String) -> void:
	var leg: Array = _legs[side]
	trail.root_node = leg[0]
	trail.tip_node = leg[1]


func _attach(bone: String) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone
	character.body.skeleton.add_child(attachment)
	return attachment
