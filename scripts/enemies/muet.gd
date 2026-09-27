class_name Muet
extends CharacterBody3D
## Un Muet : ancien musicien du village. Base commune à toutes les espèces, comme dans le
## prototype : il repère le héros et le garde en vue un moment, sautille au rythme de la musique
## (chacun avec un léger décalage), blesse au contact, attaque quand son temps de repos est écoulé
## (état propre à l'espèce) ; touché, il recule, brille et renonce à l'attaque qu'il préparait ;
## à zéro point de vie, il est libéré (il retrouve sa voix) et disparaît.
## Équilibre (version 2.3) : chaque coup l'entame ; brisé, le Muet chancelle (étourdi, plus
## fragile) et attend le coup de grâce. Projeté assez fort, il se blesse contre ce qu'il heurte
## (arbre, pilier) et un autre Muet heurté part à son tour.
## Version 2.4 : élites (couronne d'or, plus forts, une particularité), protection du totem
## chanteur, esquive du danseur, phases du Grand Muet.

## Un Muet vient d'être libéré.
signal freed(muet: Muet)
## Son équilibre vient de se briser : il chancelle.
signal staggered_now(muet: Muet)

## Particularités d'élite (voir Tuning, groupe « Élites »).
const ELITE_SWIFT := &"swift"
const ELITE_ARMORED := &"armored"
const ELITE_VOLATILE := &"volatile"
const ELITE_CALLER := &"caller"
const ELITE_GOLDEN := &"golden"
const ELITES: Array[StringName] = [ELITE_SWIFT, ELITE_ARMORED, ELITE_VOLATILE, ELITE_CALLER, ELITE_GOLDEN]
## Coups qu'un danseur n'esquive pas (brisent la garde, passent par-dessus, ou ne visent personne).
const UNDODGEABLE: Array[StringName] = [&"thorns", &"finale", &"shadow", &"impact"]

## Sons du choc (projeté contre un obstacle) et de l'équilibre brisé.
const IMPACT_SOUND: AudioStream = preload("res://assets/audio/sfx/impact.wav")
const BREAK_SOUND: AudioStream = preload("res://assets/audio/sfx/break.wav")
## Barre d'équilibre au-dessus de la tête.
const POISE_BAR_SHADER: Shader = preload("res://scenes/enemies/poise_bar.gdshader")

## Espèce : préfixe de ses réglages dans Tuning (hopper, flyer, charger, shielder, spitter, boss).
@export var species: StringName
## Gardien (reste près de son poste) ou errant (s'en éloigne davantage).
@export var guardian: bool
## Chasseur (expédition) : il voit le héros de partout et le poursuit sans revenir à son poste.
var hunter: bool = false
## Particularité d'élite (vide : Muet ordinaire ; voir ELITES).
var elite: StringName = &""
## Brûlure en cours (don « Pied de braise ») : temps restant (s), dégâts par seconde, étincelles.
var _burn_left: float = 0.0
var _burn_dps: float = 0.0
var _burn_spark: float = 0.0
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
## Équilibre (voir EnemyMath.max_poise) ; vrai tant qu'il chancelle, équilibre brisé.
var poise: float = 0.0
var poise_max: float = 0.0
var staggered: bool = false
var _poise_idle: float = 0.0
## Projection en cours assez forte pour un choc : sa force et l'attaque du héros qui l'a lancé.
var _launch: float = 0.0
var _launch_power: float = 0.0
var _poise_bar: MeshInstance3D
var _impact_sound: AudioStreamPlayer3D
## Protection du totem chanteur : temps restant (s) et facteur des dégâts reçus.
var _ward_left: float = 0.0
var _ward_multiplier: float = 1.0
## Danseur : temps avant de pouvoir esquiver de nouveau (s).
var _evade_left: float = 0.0
## Élite appelant : les renforts sont déjà venus. Grand Muet : sa phase (1 à 3).
var _called: bool = false
var _phase: int = 1

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
	body.elite = elite != &""
	add_to_group(&"muets")
	if is_boss() or elite != &"":
		add_to_group(&"bosses")
	if elite != &"" and display_name == "":
		display_name = GameTexts.elite_name(species, elite)
	body.setup(stat(&"scale") * tuning.voxel_unit * (tuning.elite_scale if elite != &"" else 1.0), shadow * (tuning.elite_scale if elite != &"" else 1.0))
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
	hurtbox.modifier = _answer
	if species == &"shielder":
		hurtbox.blocker = _blocks
		hurtbox.blocked.connect(_on_blocked)
	elif species == &"dancer":
		hurtbox.blocker = _evades
		hurtbox.blocked.connect(_on_evaded)
	poise_max = EnemyMath.max_poise(stat_or(&"poise", 0.0), tuning.muet_poise_per_tier, tier) * (tuning.elite_poise if elite != &"" else 1.0)
	poise = poise_max
	_make_poise_bar()
	_impact_sound = AudioStreamPlayer3D.new()
	_impact_sound.name = "ImpactSound"
	add_child(_impact_sound)
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
	_ward_left = maxf(_ward_left - delta, 0.0)
	_evade_left = maxf(_evade_left - delta, 0.0)
	_update_burn(delta)
	_update_poise(delta)
	state_machine.physics_update(delta)
	hitbox.update(delta)
	_check_contact()


## Brûlure (don « Pied de braise ») : `dps` dégâts par seconde pendant `duration` s.
func burn(dps: float, duration: float) -> void:
	if health.is_depleted():
		return
	_burn_dps = maxf(_burn_dps, dps)
	_burn_left = duration


func is_burning() -> bool:
	return _burn_left > 0.0


func _update_burn(delta: float) -> void:
	if _burn_left <= 0.0 or health.is_depleted():
		return
	var tuning: TuningData = Tuning.data
	_burn_left -= delta
	health.take(_burn_dps * delta)
	_burn_spark -= delta
	if _burn_spark <= 0.0:
		_burn_spark = tuning.burn_spark_period
		var fx: Effects = effects()
		if fx:
			fx.burst(global_position + Vector3.UP * body.height, tuning.fx_burn_cubes, tuning.fx_burn_speed, tuning.fx_burn_hue)
	if _burn_left <= 0.0:
		_burn_dps = 0.0


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


var _level: Level


func _terrain_speed() -> float:
	if not is_instance_valid(_level):
		_level = get_tree().get_first_node_in_group(&"night_level") as Level
	return _level.terrain_speed(global_position) if _level else 1.0


## Le héros de la nuit (gardé en mémoire).
func _hero() -> Hero:
	if not is_instance_valid(_hero_ref):
		_hero_ref = get_tree().get_first_node_in_group(&"hero") as Hero
	return _hero_ref


## Réglage de l'espèce : Tuning.<espèce>_<nom> (par exemple hopper_health) ; null s'il n'existe pas.
## Un élite rapide bondit plus vite et attaque plus souvent.
func stat(stat_name: StringName) -> Variant:
	var value: Variant = Tuning.data.get("%s_%s" % [species, stat_name])
	if elite == ELITE_SWIFT and value != null:
		if stat_name == &"hop_time":
			return float(value) * Tuning.data.elite_swift_time
		if stat_name == &"act_cooldown":
			return maxi(1, int(value) - Tuning.data.elite_swift_cooldown)
	return value


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
	return roundf(base * (tuning.king_health_factor if king else 1.0) * (tuning.elite_health if elite != &"" else 1.0))


## Rayon de la frappe au sol (plus large pour le Roi Muet).
func slam_radius() -> float:
	return Tuning.data.king_slam_radius if king else Tuning.data.boss_slam_radius


## Dégâts d'un de ses coups (`stat_name` : damage, slam_damage…), plus par rang, plus par nuit.
func damage_of(stat_name: StringName) -> float:
	var tuning: TuningData = Tuning.data
	var per_tier: float = stat_or(StringName(String(stat_name) + "_per_tier"), -1.0) if is_boss() else -1.0
	if per_tier < 0.0:
		per_tier = tuning.muet_damage_per_tier
	var damage: float = EnemyMath.scaled(stat(stat_name), per_tier, tier, tuning.muet_damage_per_night, Game.night)
	return damage * (tuning.elite_damage if elite != &"" else 1.0)


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
	var hero: Hero = get_tree().get_first_node_in_group(&"hero") as Hero
	if hunter:
		target = hero if hero and not hero.fainted_now else null
		return
	var leash: float = tuning.muet_leash_guard if guardian else tuning.muet_leash_wander
	if EnemyMath.beyond_leash(post, global_position, leash):
		target = null
		return
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


## Temps de repos après une attaque (le Grand Muet en rage attaque plus souvent, et encore plus
## dans sa dernière phase).
func act_rest_beats() -> int:
	if is_boss() and _phase >= 3:
		return Tuning.data.boss_act_cooldown_phase3
	if is_boss() and enraged:
		return Tuning.data.boss_act_cooldown_enraged
	return int(stat_or(&"act_cooldown", 0.0))


## Phase du Grand Muet (1 ; 2 en rage, sous la moitié de ses PV ; 3 sous le quart) ; 1 pour les autres.
func phase() -> int:
	return _phase


## Protégé par le chant du totem : dégâts reçus ×`multiplier` pendant `duration` s.
func ward(duration: float, multiplier: float) -> void:
	if is_freed():
		return
	_ward_left = duration
	_ward_multiplier = multiplier
	body.glimmer(Tuning.data.answer_glimmer, duration)


func is_warded() -> bool:
	return _ward_left > 0.0


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
		var keep_min: float = stat_or(&"keep_min", 0.0)
		if keep_min > 0.0:
			var way: Vector3 = EnemyMath.keep_between(direction, distance, beat_index, parity, keep_min, stat_or(&"keep_max", keep_min), tuning.spitter_strafe_beats)
			return way * step
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
	elif not flies:
		# L'eau ralentit (voir Level.terrain_speed).
		flat *= _terrain_speed()
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
	if _launch > 0.0:
		if _knockback_left > 0.0:
			_check_impact()
		else:
			_launch = 0.0


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


## Couronne de bulles de silence tout autour de lui (Grand Muet, Reine des Cimes).
func orb_crown(orb_scene: PackedScene) -> void:
	var tuning: TuningData = Tuning.data
	if orb_scene == null:
		return
	var turn: float = rng.randf() * TAU
	for i: int in tuning.boss_orb_count:
		var angle: float = turn + TAU * i / tuning.boss_orb_count
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var orb: SilenceOrb = orb_scene.instantiate() as SilenceOrb
		orb.direction = direction
		orb.speed = tuning.boss_orb_speed
		orb.damage = damage_of(&"damage") * tuning.boss_orb_damage_factor
		orb.source = self
		get_parent().add_child(orb)
		orb.global_position = Vector3(global_position.x, post.y, global_position.z) + direction * tuning.boss_orb_spawn_distance + Vector3.UP * tuning.spitter_orb_height


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


## La réponse attendue par ce Muet (docs/GDD.md §7, Tuning.muet_answers) fait plus de dégâts ;
## le reste (couleurs, groove, note) suit dans _on_hurt.
func _answer(hit: HitData) -> void:
	var tuning: TuningData = Tuning.data
	var answers: PackedStringArray = tuning.muet_answers.get(species, PackedStringArray())
	var stunned: bool = state_machine.current != null and state_machine.current.name == &"Stunned"
	var behind: bool = species == &"shielder" and not EnemyMath.shield_blocks(facing(), hit.direction, tuning.shielder_block_angle)
	if EnemyMath.is_answer(answers, hit.move, stunned, behind):
		hit.answer = true
		hit.damage *= tuning.answer_damage
	if elite == ELITE_ARMORED:
		hit.damage *= tuning.elite_armor
	if is_warded():
		hit.damage *= _ward_multiplier


func _on_hurt(hit: HitData) -> void:
	var tuning: TuningData = Tuning.data
	body.flash(tuning.muet_hit_flash_time)
	if hit.answer:
		_on_answered(hit)
	var factor: float = stat_or(&"knockback_factor", 1.0)
	_knockback = hit.direction * EnemyMath.knockback_speed(hit.launch, factor, tuning)
	_knockback_left = EnemyMath.knockback_time(hit.launch, factor, tuning)
	if EnemyMath.is_launched(hit.launch, factor, tuning) and not is_boss():
		_launch = hit.launch * factor
		_launch_power = hit.power
	if hit.attacker is Hero:
		target = hit.attacker as Hero
	if is_boss() and not enraged and EnemyMath.boss_enraged(health.current / health.maximum, tuning):
		enraged = true
		act_cooldown = 1
		body.set_enraged(true)
		_phase = 2
	if is_boss() and _phase < 3 and health.current / health.maximum <= tuning.boss_phase3_fraction and not health.is_depleted():
		_enter_last_phase()
	if elite == ELITE_CALLER and not _called and health.current / health.maximum <= tuning.elite_call_fraction and not health.is_depleted():
		_called = true
		get_tree().call_group(&"night_level", &"call_help", self, tuning.elite_call_count)
	if health.is_depleted():
		return
	var state: MuetState = state_machine.current as MuetState
	if take_poise(hit.poise):
		return
	if hit.stun_time > 0.0:
		stun(hit.stun_time)
	elif species == &"shielder" and (EnemyMath.goes_over_shield(hit.move) or hit.move == &"charged"):
		stun(tuning.shielder_dive_stun)
	elif state and state.interruptible() and not is_boss():
		state_machine.transition_to(state_machine.initial_state.name)


## Dernière phase du Grand Muet : il rugit (anneau, secousse), appelle ses gardiens et attaquera
## plus souvent.
func _enter_last_phase() -> void:
	var tuning: TuningData = Tuning.data
	_phase = 3
	enraged = true
	act_cooldown = 1
	Feedback.shake(tuning.shake_trauma_dive, Vector3.ZERO)
	var fx: Effects = effects()
	if fx:
		fx.ring(global_position, slam_radius(), fx.red, tuning.fx_break_ring_time, true)
		fx.burst(global_position + Vector3.UP * body.height, tuning.fx_break_cubes, tuning.fx_break_speed)
	get_tree().call_group(&"night_level", &"summon_guards", self)


## Entame l'équilibre de `amount` ; renvoie vrai s'il vient de se briser (le Muet chancelle).
func take_poise(amount: float) -> bool:
	if poise_max <= 0.0 or staggered or amount <= 0.0 or is_freed():
		return false
	poise -= amount
	_poise_idle = 0.0
	if poise > 0.0:
		return false
	_break_poise()
	return true


## Vrai si le Muet chancelle et peut recevoir le coup de grâce.
func can_receive_grace() -> bool:
	return staggered and not is_freed()


## Fin de l'étourdissement : s'il chancelait, il se redresse, l'équilibre retrouvé.
func end_stagger() -> void:
	if not staggered:
		return
	staggered = false
	poise = poise_max
	_poise_idle = 0.0


## Équilibre brisé : il chancelle, étourdi et plus fragile ; tout le jeu marque le coup.
func _break_poise() -> void:
	var tuning: TuningData = Tuning.data
	# Étourdi d'abord (la fin d'un étourdissement en cours redresserait le Muet), puis il chancelle.
	stun(tuning.boss_poise_break_time if is_boss() else tuning.poise_break_time)
	staggered = true
	poise = 0.0
	hurtbox.damage_taken_multiplier = maxf(hurtbox.damage_taken_multiplier, tuning.stagger_damage_multiplier)
	Feedback.hit_stop(tuning.hit_stop_break)
	Feedback.shake(tuning.shake_trauma_hit, Vector3.ZERO)
	_play(BREAK_SOUND)
	var fx: Effects = effects()
	if fx:
		var head: Vector3 = global_position + Vector3.UP * body.height
		fx.ring(global_position, stat(&"radius") * tuning.fx_break_ring, fx.gold, tuning.fx_break_ring_time)
		fx.burst(head, tuning.fx_break_cubes, tuning.fx_break_speed, tuning.fx_gold_hue)
		fx.word(GameTexts.WORD_BREAK, head, fx.gold)
	staggered_now.emit(self)


## L'équilibre revient après un moment sans coup reçu ; la barre le montre.
func _update_poise(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	if not staggered:
		_poise_idle += delta
		poise = EnemyMath.recovered_poise(poise, poise_max, _poise_idle, tuning.poise_recover_delay, tuning.poise_recover_rate, delta)
	if _poise_bar == null:
		return
	var shown: bool = poise_max > 0.0 and (poise < poise_max or staggered) and not is_freed()
	_poise_bar.visible = shown
	if shown:
		_poise_bar.position.y = body.height + tuning.poise_bar_lift
		var material: ShaderMaterial = _poise_bar.material_override as ShaderMaterial
		material.set_shader_parameter(&"ratio", 1.0 if staggered else poise / poise_max)
		material.set_shader_parameter(&"broken", 1.0 if staggered else 0.0)


func _make_poise_bar() -> void:
	var tuning: TuningData = Tuning.data
	if poise_max <= 0.0:
		return
	var quad := QuadMesh.new()
	quad.size = tuning.poise_bar_size
	var material := ShaderMaterial.new()
	material.shader = POISE_BAR_SHADER
	_poise_bar = MeshInstance3D.new()
	_poise_bar.name = "PoiseBar"
	_poise_bar.mesh = quad
	_poise_bar.material_override = material
	_poise_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_poise_bar.visible = false
	add_child(_poise_bar)


## Projeté : s'il heurte un autre Muet, les deux se blessent et l'autre part à son tour ; s'il
## heurte un obstacle de face (arbre, pilier, mur), il se blesse et reste étourdi un moment.
func _check_impact() -> void:
	var direction: Vector3 = _knockback.normalized()
	var margin: float = Tuning.data.muet_contact_margin
	for node: Node in get_tree().get_nodes_in_group(&"muets"):
		var other: Muet = node as Muet
		if other == self or other.is_freed() or other.asleep:
			continue
		var reach: float = stat(&"radius") + other.stat(&"radius") + margin
		if flat_distance_to(other.global_position) <= reach and direction.dot(flat_direction_to(other.global_position)) > 0.0:
			_bump(other, direction)
			return
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision3D = get_slide_collision(i)
		var hit_muet: Muet = collision.get_collider() as Muet
		if hit_muet:
			if not hit_muet.is_freed():
				_bump(hit_muet, direction)
				return
			continue
		var normal: Vector3 = collision.get_normal()
		var flat_normal := Vector3(normal.x, 0.0, normal.z)
		if flat_normal.length() < 0.5:
			continue
		if flat_normal.normalized().dot(direction) < -0.5:
			_impact(direction)
			return


## Billard : le Muet projeté heurte `other`, les deux se blessent et l'autre part à son tour.
func _bump(other: Muet, direction: Vector3) -> void:
	var launch: float = _launch
	var power: float = _launch_power
	_impact(direction)
	other.receive_impact(direction, launch * Tuning.data.impact_chain_share, power)


## Heurté par un Muet projeté (`direction` du choc, force de projection, attaque du héros) : il se
## blesse et part à son tour.
func receive_impact(direction: Vector3, launch: float, power: float) -> void:
	if is_freed():
		return
	hurtbox.receive(_impact_hit(direction, launch, power))


## Le choc : dégâts (attaque du héros × Tuning.impact_damage), équilibre entamé, étourdi.
func _impact(direction: Vector3) -> void:
	var tuning: TuningData = Tuning.data
	var power: float = _launch_power
	_launch = 0.0
	_knockback_left = 0.0
	Feedback.hit_stop(tuning.hit_stop_impact)
	Feedback.shake(tuning.shake_trauma_hit, direction)
	_play(IMPACT_SOUND)
	var fx: Effects = effects()
	if fx:
		fx.stunned_against_wall(global_position + Vector3.UP * body.height)
		fx.dust(global_position, tuning.fx_impact_dust, tuning.fx_impact_dust_speed)
	hurtbox.receive(_impact_hit(-direction, 0.0, power))
	if not is_freed() and not staggered:
		stun(tuning.impact_stun_time)


func _impact_hit(direction: Vector3, launch: float, power: float) -> HitData:
	var tuning: TuningData = Tuning.data
	var hit := HitData.new()
	hit.attacker = _hero()
	hit.target = hurtbox
	hit.move = &"impact"
	hit.damage = power * tuning.impact_damage
	hit.direction = direction
	hit.point = hurtbox.center()
	hit.poise = tuning.impact_poise
	hit.launch = launch
	hit.power = power
	return hit


func _play(stream: AudioStream) -> void:
	if _impact_sound == null:
		return
	_impact_sound.stream = stream
	_impact_sound.play()


## Bonne réponse : ses couleurs reviennent un instant dans une gerbe de cubes ; le héros l'entend.
func _on_answered(hit: HitData) -> void:
	var tuning: TuningData = Tuning.data
	body.glimmer(tuning.answer_glimmer, tuning.answer_glimmer_time)
	var fx: Effects = effects()
	if fx:
		fx.burst(global_position + Vector3.UP * body.height, tuning.fx_answer_cubes, tuning.fx_answer_speed)
	var hero: Hero = hit.attacker as Hero
	if hero:
		hero.on_answer(species)


## Le porte-bouclier bloque les coups venus de face (sauf s'il est étourdi, et sauf les plongeons
## qui passent par-dessus).
func _blocks(hit: HitData) -> bool:
	if state_machine.current.name == &"Stunned" or EnemyMath.goes_over_shield(hit.move) or EnemyMath.breaks_guard(hit.move):
		return false
	return EnemyMath.shield_blocks(facing(), hit.direction, Tuning.data.shielder_block_angle)


func _on_blocked(hit: HitData) -> void:
	var tuning: TuningData = Tuning.data
	# Le bouclier encaisse, mais le porte-bouclier vacille : à force, sa garde cède.
	if take_poise(hit.poise * tuning.guard_poise_share):
		return
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


## Le danseur esquive un coup ordinaire, une fois de temps en temps (au hasard), s'il n'est pas
## occupé à attaquer ni sonné.
func _evades(hit: HitData) -> bool:
	var tuning: TuningData = Tuning.data
	if _evade_left > 0.0 or staggered or state_machine.current != state_machine.initial_state:
		return false
	if EnemyMath.breaks_guard(hit.move) or EnemyMath.goes_over_shield(hit.move) or UNDODGEABLE.has(hit.move):
		return false
	return rng.randf() < tuning.dancer_evade_chance


## Esquive du danseur : un pas de côté, puis il contre dès le temps suivant.
func _on_evaded(hit: HitData) -> void:
	var tuning: TuningData = Tuning.data
	_evade_left = tuning.dancer_evade_cooldown
	var side := Vector3(-hit.direction.z, 0.0, hit.direction.x) * (1.0 if rng.randf() < 0.5 else -1.0)
	hop(side * tuning.dancer_evade_distance, tuning.dancer_evade_time, stat(&"hop_height"))
	act_cooldown = 1
	var fx: Effects = effects()
	if fx:
		fx.word(GameTexts.WORD_EVADED, global_position + Vector3.UP * body.height, fx.pink)


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
	Game.on_muet_freed(self)
	if elite == ELITE_VOLATILE:
		_burst()
	if elite != &"":
		get_tree().call_group(&"night_level", &"on_elite_freed", self)
	freed.emit(self)


## Élite éclatant : libéré, il éclate un temps plus tard (cercle annoncé) ; le héros dedans est blessé.
func _burst() -> void:
	var tuning: TuningData = Tuning.data
	var center: Vector3 = global_position
	var duration: float = beats_to_seconds(tuning.elite_burst_beats)
	telegraph().show_circle(center, tuning.elite_burst_radius, duration)
	var fx: Effects = effects()
	var tree: SceneTree = get_tree()
	var damage: float = tuning.elite_burst_damage * (1.0 + tuning.muet_damage_per_night * maxi(Game.night - 1, 0))
	tree.create_timer(duration, false).timeout.connect(func() -> void:
		if fx and is_instance_valid(fx):
			fx.ring(center, tuning.elite_burst_radius, fx.red, tuning.fx_break_ring_time)
			fx.burst(center + Vector3.UP, tuning.fx_break_cubes, tuning.fx_break_speed)
		var hero: Hero = tree.get_first_node_in_group(&"hero") as Hero
		if hero == null or Vector2(hero.global_position.x - center.x, hero.global_position.z - center.z).length() > tuning.elite_burst_radius:
			return
		var hit := HitData.new()
		hit.damage = damage
		hit.big = true
		hit.move = &"burst"
		var flat := Vector3(hero.global_position.x - center.x, 0.0, hero.global_position.z - center.z)
		hit.direction = flat.normalized() if not flat.is_zero_approx() else Vector3.BACK
		hit.point = hero.hurtbox.center()
		hero.hurtbox.receive(hit))
