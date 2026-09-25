class_name Muet
extends CharacterBody3D
## Un Muet : ancien musicien du village. Base commune à toutes les espèces : points de vie,
## zone où il est touché, zone de ses coups, machine à états propre à l'espèce.
## Il agit au rythme de la musique, chacun avec un léger décalage ; touché, il recule et
## brille ; à zéro point de vie, il est libéré (il retrouve sa voix) et disparaît.

## Un Muet vient d'être libéré.
signal freed(muet: Muet)

## Espèce : préfixe de ses réglages dans Tuning (hopper, flyer, charger, boss).
@export var species: StringName
## Gardien (reste près de son poste) ou errant (s'en éloigne davantage).
@export var guardian: bool
## Vrai pour une espèce qui vole (pas de gravité ni de collisions avec le décor).
@export var flies: bool
## Annonce d'attaque posée au sol.
@export var telegraph_scene: PackedScene

## Position de départ, à laquelle il revient s'il s'en éloigne trop.
var post: Vector3
## Héros repéré (ou null).
var target: Hero
var rng := RandomNumberGenerator.new()

var _beat_offset: float = 0.0
var _knockback_left: float = 0.0
var _knockback: Vector3 = Vector3.ZERO

@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $Hitbox
@onready var body: MuetBody = $Body
@onready var state_machine: StateMachine = $StateMachine
@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _freed_sound: AudioStreamPlayer3D = $FreedSound


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	post = global_position
	rng.randomize()
	_beat_offset = rng.randf_range(0.0, tuning.muet_beat_jitter_max)
	var radius: float = stat(&"radius")
	var height: float = stat(&"height")
	for shape_node: CollisionShape3D in [_collision, $Hurtbox/CollisionShape3D as CollisionShape3D]:
		var capsule: CapsuleShape3D = shape_node.shape as CapsuleShape3D
		capsule.radius = radius
		capsule.height = maxf(height, radius * 2.0)
		shape_node.position = Vector3.UP * height / 2.0
	($Hitbox/CollisionShape3D as CollisionShape3D).position = Vector3.UP * height / 2.0
	hurtbox.radius = radius
	hitbox.vertical_reach = tuning.attack_vertical_reach
	health.setup(stat(&"health"))
	health.depleted.connect(_on_depleted)
	hurtbox.hurt.connect(_on_hurt)
	body.setup(height)
	Rhythm.beat.connect(_on_beat)
	state_machine.start()


func _physics_process(delta: float) -> void:
	if _knockback_left > 0.0:
		_knockback_left -= delta
	state_machine.physics_update(delta)
	hitbox.update(delta)


## Réglage de l'espèce : Tuning.<espèce>_<nom> (par exemple hopper_health).
func stat(stat_name: StringName) -> Variant:
	return Tuning.data.get("%s_%s" % [species, stat_name])


## Reçoit un temps de la musique (appelé directement dans les tests).
func receive_beat(index: int) -> void:
	var state: MuetState = state_machine.current as MuetState
	if state:
		state.on_beat(index)


## Cherche le héros : repéré s'il est à portée de détection, perdu si le Muet s'est trop
## éloigné de son poste.
func update_target() -> void:
	var tuning: TuningData = Tuning.data
	var leash: float = tuning.muet_leash_guard if guardian else tuning.muet_leash_wander
	if EnemyMath.beyond_leash(post, global_position, leash):
		target = null
		return
	var hero: Hero = get_tree().get_first_node_in_group(&"hero") as Hero
	if hero and flat_distance_to(hero.global_position) <= tuning.muet_detection_range:
		target = hero
	elif hero == null or EnemyMath.beyond_leash(global_position, hero.global_position, leash):
		target = null


func flat_distance_to(point: Vector3) -> float:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length()


## Direction horizontale (normalisée) vers `point`.
func flat_direction_to(point: Vector3) -> Vector3:
	var flat := Vector3(point.x - global_position.x, 0.0, point.z - global_position.z)
	return flat.normalized() if not flat.is_zero_approx() else Vector3.FORWARD


## Tourne le corps vers `direction`.
func face(direction: Vector3) -> void:
	if not direction.is_zero_approx():
		body.rotation.y = HeroMotion.yaw_of(direction)


## Vitesse horizontale voulue, remplacée par le recul tant qu'il dure ; puis gravité et
## déplacement.
func move(horizontal: Vector3, delta: float) -> void:
	var flat: Vector3 = _knockback if _knockback_left > 0.0 else horizontal
	velocity.x = flat.x
	velocity.z = flat.z
	if not flies:
		velocity.y -= Tuning.data.muet_gravity * delta
	move_and_slide()


## Coup du Muet : touche le héros à au plus `reach` (plus son rayon), dans un arc de `arc_deg`
## autour de `forward`, pendant `duration` secondes.
func strike(reach: float, arc_deg: float, forward: Vector3, duration: float, damage: float, big: bool) -> void:
	hitbox.activate(reach, arc_deg, forward, duration, _make_hit.bind(damage, big))


## Pose une annonce au sol et la renvoie (pour la déplacer si besoin).
func telegraph() -> Telegraph:
	var mark: Telegraph = telegraph_scene.instantiate() as Telegraph
	get_parent().add_child(mark)
	return mark


## Étourdit le Muet pendant `duration` secondes.
func stun(duration: float) -> void:
	if state_machine.current.name == &"Freed":
		return
	(state_machine.get_node(^"Stunned") as MuetStunnedState).duration = duration
	state_machine.transition_to(&"Stunned")


## Durée de `beats` temps de musique (s).
func beats_to_seconds(beats: int) -> float:
	return beats * RhythmMath.beat_length(Tuning.data)


func _make_hit(target_hurtbox: Hurtbox, damage: float, big: bool) -> HitData:
	var hit := HitData.new()
	hit.attacker = self
	hit.damage = damage
	hit.big = big
	hit.move = species
	var flat: Vector3 = target_hurtbox.global_position - global_position
	flat.y = 0.0
	hit.direction = flat.normalized() if not flat.is_zero_approx() else Vector3.BACK
	hit.point = target_hurtbox.center()
	return hit


func _on_beat(index: int) -> void:
	# Chaque Muet a son petit décalage : ils ne bougent jamais tous exactement ensemble.
	if _beat_offset > 0.0:
		get_tree().create_timer(_beat_offset, false).timeout.connect(receive_beat.bind(index))
	else:
		receive_beat(index)


func _on_hurt(hit: HitData) -> void:
	var tuning: TuningData = Tuning.data
	body.flash(tuning.muet_hit_flash_time)
	_knockback = hit.direction * tuning.muet_knockback_speed
	_knockback_left = tuning.muet_knockback_time
	if hit.stun_time > 0.0 and not health.is_depleted():
		stun(hit.stun_time)


func _on_depleted() -> void:
	state_machine.transition_to(&"Freed")


## Libération : plus de collisions ni de coups, le rire, les couleurs qui reviennent.
func release() -> void:
	collision_layer = 0
	collision_mask = 0
	hurtbox.set_deferred(&"monitorable", false)
	hitbox.deactivate()
	_freed_sound.play()
	body.play_freed(Tuning.data.muet_freed_time)
	get_tree().call_group(&"hero", &"on_enemy_freed", self)
	Game.on_muet_freed(self)
	freed.emit(self)
