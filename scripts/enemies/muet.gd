class_name Muet
extends CharacterBody3D
## Un Muet : ancien musicien du village. Base commune à toutes les espèces, comme dans le
## prototype : il repère le héros et le garde en vue un moment, sautille au rythme de la musique
## (chacun avec un léger décalage), blesse au contact, attaque quand son temps de repos est écoulé
## (état propre à l'espèce) ; touché, il recule, brille et renonce à l'attaque qu'il préparait ;
## à zéro point de vie, il est libéré (il retrouve sa voix) et disparaît.

## Un Muet vient d'être libéré.
signal freed(muet: Muet)

## Espèce : préfixe de ses réglages dans Tuning (hopper, flyer, charger, shielder, spitter, boss).
@export var species: StringName
## Gardien (reste près de son poste) ou errant (s'en éloigne davantage).
@export var guardian: bool
## Vrai pour une espèce qui vole (pas de gravité ni de contact au sol).
@export var flies: bool
## Annonce d'attaque posée au sol.
@export var telegraph_scene: PackedScene

## Position de départ, à laquelle il revient s'il s'en éloigne trop.
var post: Vector3
## Rang du sanctuaire gardé (0, 1, 2) : plus loin, plus fort.
var tier: int = 0
## Roi Muet (Grand Muet de la dernière nuit) : plus gros, plus fort, frappe plus large.
var king: bool = false
## Nom affiché au-dessus de sa barre de PV (Grands Muets).
var display_name: String = ""
## Zone où les Muets n'entrent pas et où ils laissent le héros tranquille (le village) ;
## rayon 0 : aucune.
var safe_zone_center: Vector3 = Vector3.ZERO
var safe_zone_radius: float = 0.0
## Héros repéré (ou null).
var target: Hero
## Temps avant sa prochaine attaque (compte les temps pendant la poursuite).
var act_cooldown: int = 0
## Parité des temps où il bondit (0 ou 1) : ils ne bondissent pas tous ensemble.
var parity: int = 0
## En rage (Grand Muet sous la moitié de ses PV).
var enraged: bool = false
## Endormi : trop loin du héros pour qu'on le voie (voir _update_sleep).
var asleep: bool = false
var _hero_ref: Hero
## États d'attaque (annonce ou coup) : le héros devrait esquiver.
const THREAT_STATES: Array[StringName] = [&"Telegraph", &"Prepare", &"Charge", &"Dive", &"Slam", &"Bash"]
var rng := RandomNumberGenerator.new()

var _beat_offset: float = 0.0
var _knockback_left: float = 0.0
var _knockback: Vector3 = Vector3.ZERO
var _contact_left: float = 0.0
var _hop_vector: Vector3 = Vector3.ZERO
var _hop_time: float = 0.0
var _hop_duration: float = 0.0
var _hop_height: float = 0.0
var _hop_landing: Callable
var _last_hit_move: StringName = &""

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
	act_cooldown = rng.randi_range(tuning.muet_first_act_min, tuning.muet_first_act_max)
	parity = rng.randi_range(0, 1)
	var radius: float = stat(&"radius")
	var shadow: float = radius * (tuning.flyer_shadow_fraction if flies else 1.0)
	body.king = king
	add_to_group(&"muets")
	if is_boss():
		add_to_group(&"bosses")
	body.setup(stat(&"scale") * tuning.voxel_unit, shadow)
	body.turn_rate = stat_or(&"turn_rate", tuning.muet_turn_rate)
	var height: float = body.height
	for shape_node: CollisionShape3D in [_collision, $Hurtbox/CollisionShape3D as CollisionShape3D]:
		var capsule: CapsuleShape3D = shape_node.shape as CapsuleShape3D
		capsule.radius = radius
		capsule.height = maxf(height, radius * 2.0)
		shape_node.position = Vector3.UP * height / 2.0
	($Hitbox/CollisionShape3D as CollisionShape3D).position = Vector3.UP * height / 2.0
	hurtbox.radius = radius
	hitbox.vertical_reach = tuning.attack_vertical_reach
	health.setup(max_health())
	health.depleted.connect(_on_depleted)
	hurtbox.hurt.connect(_on_hurt)
	if species == &"shielder":
		hurtbox.blocker = _blocks
		hurtbox.blocked.connect(_on_blocked)
	Rhythm.beat.connect(_on_beat)
	state_machine.start()


func _physics_process(delta: float) -> void:
	# Arrêt sur image : le temps ne passe pas (et les vitesses se calculent en divisant par delta).
	if delta <= 0.0:
		return
	_update_sleep()
	if asleep:
		return
	if _knockback_left > 0.0:
		_knockback_left -= delta
	_contact_left -= delta
	state_machine.physics_update(delta)
	hitbox.update(delta)
	_check_contact()


## Loin du héros, sans cible, revenu à son poste et au repos (ni bond, ni recul, ni attaque en
## cours), le Muet dort : il ne bouge plus et son corps ne s'anime plus, jusqu'à ce que le héros
## approche. On ne le voit pas de là, et le téléphone a moins à calculer.
func _update_sleep() -> void:
	var tuning: TuningData = Tuning.data
	var hero: Hero = _hero()
	var far: bool = hero != null and flat_distance_to(hero.global_position) > tuning.muet_sleep_distance
	var leash: float = tuning.muet_leash_guard if guardian else tuning.muet_leash_wander
	var home: bool = flat_distance_to(post) <= leash * tuning.muet_return_fraction
	var resting: bool = not is_hopping() and _knockback_left <= 0.0 and state_machine.current == state_machine.initial_state
	var sleep: bool = far and home and target == null and (asleep or resting)
	if sleep == asleep:
		return
	asleep = sleep
	body.process_mode = Node.PROCESS_MODE_DISABLED if asleep else Node.PROCESS_MODE_INHERIT
	if asleep:
		velocity = Vector3.ZERO


## Le héros de la nuit (gardé en mémoire).
func _hero() -> Hero:
	if not is_instance_valid(_hero_ref):
		_hero_ref = get_tree().get_first_node_in_group(&"hero") as Hero
	return _hero_ref


## Réglage de l'espèce : Tuning.<espèce>_<nom> (par exemple hopper_health) ; null s'il n'existe pas.
func stat(stat_name: StringName) -> Variant:
	return Tuning.data.get("%s_%s" % [species, stat_name])


## Réglage de l'espèce, ou `fallback` si l'espèce n'en a pas.
func stat_or(stat_name: StringName, fallback: float) -> float:
	var value: Variant = stat(stat_name)
	return fallback if value == null else float(value)


## Vrai pendant une attaque annoncée ou lancée (le héros devrait esquiver).
func is_threatening() -> bool:
	return state_machine.current != null and THREAT_STATES.has(state_machine.current.name)


## Vrai une fois libéré.
func is_freed() -> bool:
	return health.is_depleted()


func is_boss() -> bool:
	return species == &"boss"


## PV de départ : ceux de l'espèce, plus par rang de sanctuaire, plus nuit après nuit.
func max_health() -> float:
	var tuning: TuningData = Tuning.data
	var per_tier: float = tuning.boss_health_per_tier if is_boss() else tuning.muet_health_per_tier
	var base: float = EnemyMath.scaled(stat(&"health"), per_tier, tier, tuning.muet_health_per_night, Game.night)
	return roundf(base * (tuning.king_health_factor if king else 1.0))


## Rayon de la frappe au sol (plus large pour le Roi Muet).
func slam_radius() -> float:
	return Tuning.data.king_slam_radius if king else Tuning.data.boss_slam_radius


## Dégâts d'un de ses coups (`stat_name` : damage, slam_damage…), plus par rang, plus par nuit.
func damage_of(stat_name: StringName) -> float:
	var tuning: TuningData = Tuning.data
	var per_tier: float = stat_or(StringName(String(stat_name) + "_per_tier"), -1.0) if is_boss() else -1.0
	if per_tier < 0.0:
		per_tier = tuning.muet_damage_per_tier
	return EnemyMath.scaled(stat(stat_name), per_tier, tier, tuning.muet_damage_per_night, Game.night)


## Reçoit un temps de la musique (appelé directement dans les tests).
func receive_beat(index: int) -> void:
	_update_sleep()
	if asleep:
		return
	var state: MuetState = state_machine.current as MuetState
	if state:
		state.on_beat(index)


## Cherche le héros : repéré à portée de détection, gardé en vue un peu plus loin une fois
## lancé, perdu si le Muet s'est trop éloigné de son poste ou si le héros est au village.
func update_target() -> void:
	var tuning: TuningData = Tuning.data
	var leash: float = tuning.muet_leash_guard if guardian else tuning.muet_leash_wander
	if EnemyMath.beyond_leash(post, global_position, leash):
		target = null
		return
	var hero: Hero = get_tree().get_first_node_in_group(&"hero") as Hero
	if hero == null or in_safe_zone(hero.global_position):
		target = null
		return
	var reach: float = tuning.muet_detection_range * (tuning.muet_detection_keep if target else 1.0)
	target = hero if flat_distance_to(hero.global_position) <= reach else null


## Vrai si `point` est dans la zone où les Muets n'entrent pas.
func in_safe_zone(point: Vector3) -> bool:
	return safe_zone_radius > 0.0 and Vector2(point.x - safe_zone_center.x, point.z - safe_zone_center.z).length() < safe_zone_radius


func flat_distance_to(point: Vector3) -> float:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length()


## Direction horizontale (normalisée) vers `point`.
func flat_direction_to(point: Vector3) -> Vector3:
	var flat := Vector3(point.x - global_position.x, 0.0, point.z - global_position.z)
	return flat.normalized() if not flat.is_zero_approx() else Vector3.FORWARD


## Tourne le corps vers `direction` (à sa vitesse de rotation).
func face(direction: Vector3) -> void:
	if not direction.is_zero_approx():
		body.target_yaw = EnemyMath.yaw_of(direction)


## Direction du regard du corps (horizontale).
func facing() -> Vector3:
	return Vector3(sin(body.rotation.y), 0.0, cos(body.rotation.y))


## Vrai si le héros repéré est à portée de l'attaque de l'espèce.
func act_in_range() -> bool:
	if target == null:
		return false
	var distance: float = flat_distance_to(target.global_position)
	return distance >= stat_or(&"act_min_range", 0.0) and distance < stat_or(&"act_max_range", 0.0)


## Temps de repos après une attaque (le Grand Muet en rage attaque plus souvent).
func act_rest_beats() -> int:
	if is_boss() and enraged:
		return Tuning.data.boss_act_cooldown_enraged
	return int(stat_or(&"act_cooldown", 0.0))


## Bond de `offset` (déplacement horizontal) en `duration` s, à `height` m de haut ; `on_land`
## est appelé à l'atterrissage.
func hop(offset: Vector3, duration: float, height: float, on_land: Callable = Callable()) -> void:
	_hop_vector = Vector3(offset.x, 0.0, offset.z)
	_hop_duration = duration
	_hop_time = 0.0
	_hop_height = height
	_hop_landing = on_land
	body.squash(Tuning.data.muet_squash_hop)
	face(_hop_vector)


func is_hopping() -> bool:
	return _hop_time < _hop_duration


## Hauteur du bond en cours (m).
func hop_lift() -> float:
	return sin(PI * minf(_hop_time / _hop_duration, 1.0)) * _hop_height if is_hopping() else 0.0


## Prochain bond du prototype (déplacement horizontal, nul s'il reste sur place) : vers le héros
## repéré (le cracheur garde ses distances), sinon vers son poste s'il s'en est éloigné, sinon au
## hasard de temps en temps.
func next_hop(beat_index: int) -> Vector3:
	var tuning: TuningData = Tuning.data
	var step: float = stat(&"hop_distance")
	if target:
		var distance: float = flat_distance_to(target.global_position)
		var direction: Vector3 = flat_direction_to(target.global_position)
		if species == &"spitter":
			return EnemyMath.keep_distance(direction, distance, beat_index, parity, tuning) * step
		var reach: float = stat(&"radius") + target.hurtbox.radius + tuning.muet_approach_margin
		return direction * minf(step, maxf(0.0, distance - reach))
	var leash: float = tuning.muet_leash_guard if guardian else tuning.muet_leash_wander
	if flat_distance_to(post) > leash * tuning.muet_return_fraction:
		return flat_direction_to(post) * step
	if rng.randf() >= tuning.muet_idle_hop_chance:
		return Vector3.ZERO
	var angle: float = rng.randf() * TAU
	return Vector3(cos(angle), 0.0, sin(angle)) * step * tuning.muet_idle_hop_fraction


## Vitesse horizontale voulue, remplacée par le bond en cours ou par le recul tant qu'il dure ;
## puis gravité et déplacement.
func move(horizontal: Vector3, delta: float) -> void:
	var tuning: TuningData = Tuning.data
	var flat: Vector3 = horizontal
	if is_hopping():
		var before: float = _hop_time / _hop_duration
		_hop_time += delta
		var after: float = minf(_hop_time / _hop_duration, 1.0)
		flat = _hop_vector * (EnemyMath.ease_out(after) - EnemyMath.ease_out(before)) / delta
		velocity.y = (sin(PI * after) - sin(PI * before)) * _hop_height / delta
		if not is_hopping():
			_land()
	elif not flies:
		velocity.y -= tuning.muet_gravity * delta
	if _knockback_left > 0.0:
		flat = _knockback
	velocity.x = flat.x
	velocity.z = flat.z
	var before: Vector3 = global_position
	move_and_slide()
	# Rarement, un Muet posé contre un obstacle sort du pas de physique avec une position non finie :
	# il reste où il était.
	if not global_position.is_finite() or not velocity.is_finite():
		global_position = before
		velocity = Vector3.ZERO
	_keep_out_of_safe_zone()


## Repousse le Muet au bord de la zone interdite (le village), avec une petite marge.
func _keep_out_of_safe_zone() -> void:
	if safe_zone_radius <= 0.0:
		return
	var flat := Vector2(global_position.x - safe_zone_center.x, global_position.z - safe_zone_center.z)
	var limit: float = safe_zone_radius + Tuning.data.muet_village_margin + stat(&"radius")
	if flat.length() < limit and not flat.is_zero_approx():
		flat = flat.normalized() * limit
		global_position = Vector3(safe_zone_center.x + flat.x, global_position.y, safe_zone_center.z + flat.y)


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


## Effets du niveau (cubes, anneaux, textes), s'il y en a.
func effects() -> Effects:
	return Effects.of(self)


func _land() -> void:
	body.squash(-Tuning.data.muet_squash_land)
	if _hop_landing.is_valid():
		var landing: Callable = _hop_landing
		_hop_landing = Callable()
		landing.call()


## Contact : le héros qui touche le Muet est blessé, au plus une fois par moment de repos, sauf
## si le Muet est en l'air ou si le héros lui passe au-dessus.
func _check_contact() -> void:
	var tuning: TuningData = Tuning.data
	var state: MuetState = state_machine.current as MuetState
	if flies or _contact_left > 0.0 or state == null or not state.allows_contact():
		return
	if hop_lift() > tuning.muet_contact_max_lift:
		return
	var hero: Hero = get_tree().get_first_node_in_group(&"hero") as Hero
	if hero == null:
		return
	var reach: float = stat(&"radius") + hero.hurtbox.radius + tuning.muet_contact_margin
	if flat_distance_to(hero.global_position) > reach:
		return
	if hero.global_position.y > global_position.y + body.height * tuning.muet_contact_hero_above:
		return
	_contact_left = tuning.muet_contact_cooldown
	var damage: float = damage_of(&"damage") * stat_or(&"contact_fraction", 1.0)
	hero.hurtbox.receive(_make_hit(hero.hurtbox, damage, false))


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
	_last_hit_move = hit.move
	body.flash(tuning.muet_hit_flash_time)
	_knockback = hit.direction * tuning.muet_knockback_speed * stat_or(&"knockback_factor", 1.0)
	_knockback_left = tuning.muet_knockback_time
	if hit.attacker is Hero:
		target = hit.attacker as Hero
	if is_boss() and not enraged and EnemyMath.boss_enraged(health.current / health.maximum, tuning):
		enraged = true
		act_cooldown = 1
		body.set_enraged(true)
	if health.is_depleted():
		return
	var state: MuetState = state_machine.current as MuetState
	if hit.stun_time > 0.0:
		stun(hit.stun_time)
	elif species == &"shielder" and EnemyMath.goes_over_shield(hit.move):
		stun(tuning.shielder_dive_stun)
	elif state and state.interruptible() and not is_boss():
		state_machine.transition_to(state_machine.initial_state.name)


## Le porte-bouclier bloque les coups venus de face (sauf s'il est étourdi, et sauf les plongeons
## qui passent par-dessus).
func _blocks(hit: HitData) -> bool:
	if state_machine.current.name == &"Stunned" or EnemyMath.goes_over_shield(hit.move):
		return false
	return EnemyMath.shield_blocks(facing(), hit.direction, Tuning.data.shielder_block_angle)


func _on_blocked(hit: HitData) -> void:
	var tuning: TuningData = Tuning.data
	body.raise_shield()
	var sound: AudioStreamPlayer3D = get_node_or_null(^"BlockSound") as AudioStreamPlayer3D
	if sound:
		sound.play()
	var fx: Effects = effects()
	if fx:
		fx.blocked(global_position + Vector3.UP * body.height)
	var hero: Hero = hit.attacker as Hero
	if hero:
		hero.set_horizontal_velocity(-hit.direction * tuning.shielder_block_push)


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
	var fx: Effects = effects()
	if fx:
		fx.muet_freed(global_position, body.height, is_boss())
	get_tree().call_group(&"hero", &"on_enemy_freed", self)
	if EnemyMath.goes_over_shield(_last_hit_move):
		Game.on_dive_kill()
	Game.on_muet_freed(self)
	freed.emit(self)
