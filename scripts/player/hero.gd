class_name Hero
extends CharacterBody3D
## Le héros : lit les commandes, garde la mémoire des appuis et délègue le mouvement
## à sa machine à états (Ground, Air, Roll, AirDash). Les états utilisent les outils ci-dessous.

const BUTTON_ACTIONS: Array[StringName] = [&"jump", &"dodge", &"attack"]

## Joystick tactile ; s'il n'est pas touché, on lit le clavier ou la manette.
@export var joystick: FloatingJoystick

## Faux dans les tests : les commandes sont alors fixées à la main (input_move, input_jump_held, press).
var reads_player_input: bool = true
## Direction demandée à l'écran : x vers la droite, y vers le bas, longueur de 0 à 1.
var input_move: Vector2 = Vector2.ZERO
## Vrai tant que le bouton de saut est tenu.
var input_jump_held: bool = false

## Orientation du héros (radians, 0 = regarde vers -Z).
var facing_yaw: float = 0.0
## Sauts faits depuis le dernier contact avec le sol.
var jumps_used: int = 0
## Élans aériens faits depuis le dernier contact avec le sol.
var air_dashes_used: int = 0
## Temps restant pour sauter après avoir quitté un bord sans sauter (s).
var coyote_left: float = 0.0
## Temps restant avant de pouvoir relancer une roulade (s).
var roll_cooldown_left: float = 0.0
## Vrai pendant les fenêtres d'invulnérabilité (roulade, élan aérien).
var invulnerable: bool = false

var tuning: TuningData = Tuning.data

var _buffer: InputBuffer
var _clock: float = 0.0
var _spawn: Transform3D

@onready var state_machine: StateMachine = $StateMachine
@onready var visual: HeroVisual = $Visual
@onready var _collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	_buffer = InputBuffer.new(tuning.input_buffer_time)
	_spawn = global_transform
	floor_snap_length = tuning.step_height
	var capsule: CapsuleShape3D = _collision.shape as CapsuleShape3D
	capsule.radius = tuning.hero_radius
	capsule.height = tuning.hero_height
	_collision.position = Vector3.UP * tuning.hero_height / 2.0
	visual.setup(tuning.hero_height, tuning.hero_radius)
	add_to_group(&"debug_info")
	state_machine.start()


func _physics_process(delta: float) -> void:
	_clock += delta
	coyote_left = maxf(coyote_left - delta, 0.0)
	roll_cooldown_left = maxf(roll_cooldown_left - delta, 0.0)
	if reads_player_input:
		_read_player_input()
	state_machine.physics_update(delta)
	visual.update_pose(facing_yaw, delta)
	if global_position.y < _spawn.origin.y - tuning.respawn_fall_depth:
		respawn()


## Enregistre un appui ; il reste valable input_buffer_time secondes.
func press(action: StringName) -> void:
	_buffer.press(action, _clock)


## Vrai si l'action a été appuyée récemment ; l'appui est alors consommé.
func consume_press(action: StringName) -> bool:
	return _buffer.consume(action, _clock)


## Direction de déplacement demandée, dans le monde (longueur de 0 à 1).
func move_direction() -> Vector3:
	return HeroMotion.world_direction(input_move)


## Direction du regard, horizontale et normalisée.
func facing_direction() -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, facing_yaw)


## Direction demandée si le joueur en donne une, sinon celle du regard.
func intended_direction() -> Vector3:
	var direction: Vector3 = move_direction()
	return facing_direction() if direction.is_zero_approx() else direction.normalized()


func horizontal_velocity() -> Vector3:
	return Vector3(velocity.x, 0.0, velocity.z)


func set_horizontal_velocity(horizontal: Vector3) -> void:
	velocity.x = horizontal.x
	velocity.z = horizontal.z


## Rapproche la vitesse horizontale de `target` avec un lissage de `rate` par seconde.
func approach_horizontal_velocity(target: Vector3, rate: float, delta: float) -> void:
	set_horizontal_velocity(horizontal_velocity().lerp(target, Smoothing.weight(rate, delta)))


## Tourne progressivement le regard vers `direction`, avec un lissage de `rate` par seconde.
func turn_toward(direction: Vector3, rate: float, delta: float) -> void:
	if direction.is_zero_approx():
		return
	facing_yaw = lerp_angle(facing_yaw, HeroMotion.yaw_of(direction), Smoothing.weight(rate, delta))


## Tourne le regard vers `direction` immédiatement.
func face_now(direction: Vector3) -> void:
	facing_yaw = HeroMotion.yaw_of(direction)


func apply_gravity(delta: float) -> void:
	velocity.y -= HeroMotion.gravity(velocity.y, input_jump_held, tuning) * delta


## Saute avec la vitesse verticale `speed` ; le dernier saut autorisé est le salto.
func jump(speed: float) -> void:
	velocity.y = speed
	jumps_used += 1
	coyote_left = 0.0
	if jumps_used >= tuning.max_jumps:
		visual.play_salto(tuning.salto_duration)


## Saute en l'air s'il reste un saut : saut normal pendant la tolérance de bord, sinon salto.
## Consomme l'appui seulement si le saut a lieu ; sinon il reste en mémoire pour l'atterrissage.
func try_air_jump() -> bool:
	if coyote_left > 0.0:
		if not consume_press(&"jump"):
			return false
		jump(tuning.jump_speed)
		return true
	if jumps_used >= tuning.max_jumps or not consume_press(&"jump"):
		return false
	# Tombé d'un bord sans sauter : le saut en l'air est directement le salto.
	jumps_used = maxi(jumps_used, tuning.max_jumps - 1)
	jump(tuning.double_jump_speed)
	return true


## Déplace le corps selon `velocity`, en montant les petites marches.
func move(delta: float) -> void:
	_step_up(delta)
	move_and_slide()


## Ramène le héros au point de départ.
func respawn() -> void:
	global_transform = _spawn
	velocity = Vector3.ZERO
	_buffer.clear()
	reset_physics_interpolation()
	state_machine.transition_to(&"Air")


## Ligne affichée par l'overlay de mise au point.
func debug_text() -> String:
	return "%s · sauts %d/%d · élans %d/%d%s" % [
		state_machine.current.name,
		jumps_used,
		tuning.max_jumps,
		air_dashes_used,
		tuning.air_dashes_per_jump,
		" · invulnérable" if invulnerable else "",
	]


func _read_player_input() -> void:
	if joystick and joystick.is_active():
		input_move = joystick.vector
	else:
		input_move = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	input_jump_held = Input.is_action_pressed(&"jump")
	for action: StringName in BUTTON_ACTIONS:
		if Input.is_action_just_pressed(action):
			press(action)


## Monte une marche d'au plus step_height si un obstacle bas bloque la course :
## on vérifie qu'il y a la place au-dessus, puis un sol où poser le pied.
func _step_up(delta: float) -> void:
	var motion: Vector3 = horizontal_velocity() * delta
	if not is_on_floor() or motion.is_zero_approx():
		return
	if not test_move(global_transform, motion):
		return
	var rise: Vector3 = Vector3.UP * tuning.step_height
	if test_move(global_transform, rise):
		return
	var raised: Transform3D = global_transform.translated(rise)
	if test_move(raised, motion):
		return
	var landing := KinematicCollision3D.new()
	if not test_move(raised.translated(motion), -rise, landing):
		return
	if landing.get_normal().angle_to(Vector3.UP) > floor_max_angle:
		return
	global_position += rise + landing.get_travel()
