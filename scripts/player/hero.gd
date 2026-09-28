class_name Hero
extends CharacterBody3D
## Le héros : lit les commandes, garde la mémoire des appuis et délègue le mouvement
## à sa machine à états (Ground, Air, Roll, AirDash, Attack, Charge, Dive). Les états utilisent les
## outils ci-dessous ; les coups passent par la Hitbox et déclenchent les retours d'impact.
## Version 2.3 : Frappe maintenue charge un coup chargé ; après une esquive parfaite, Frappe est
## une riposte sur le Muet esquivé ; près d'un Muet qui chancelle, Frappe est le coup de grâce.

## Un coup du héros a touché.
signal hit_landed(hit: HitData)
## Un appui sur Frappe vient d'être jugé par rapport au temps.
signal judged(judgement: RhythmMath.Judgement)
## Le héros vient d'être ramené au village.
signal respawned
## PV à zéro sans second souffle : la sortie se termine.
signal fainted
## Le second souffle l'a relevé.
signal second_wind
## Un appui sur Saut, Esquive ou Frappe (aides contextuelles).
signal action_pressed(action: StringName)
## Un Muet de l'espèce `species` a reçu la réponse qu'il attendait (docs/GDD.md §7).
signal answered(species: StringName)
## Une danse demandée n'a pas assez de groove : rien ne part (le bouton Danse le montre).
signal dance_fizzled

const BUTTON_ACTIONS: Array[StringName] = [&"jump", &"dodge", &"attack"]
## Sons du coup chargé (qui monte), du coup de grâce et de la riposte.
const CHARGE_SOUND: AudioStream = preload("res://assets/audio/sfx/charge.wav")
const GRACE_SOUND: AudioStream = preload("res://assets/audio/sfx/grace.wav")
const RIPOSTE_SOUND: AudioStream = preload("res://assets/audio/sfx/riposte.wav")
## Sons des danses de l'Onde (version 4.1) : un par figure, et le pas manqué (pas assez de groove).
const DANCE_SOUNDS: Dictionary[StringName, AudioStream] = {
	&"palm": preload("res://assets/audio/sfx/dance_palm.wav"),
	&"spiral": preload("res://assets/audio/sfx/dance_spiral.wav"),
	&"rain": preload("res://assets/audio/sfx/dance_rain.wav"),
	&"thread": preload("res://assets/audio/sfx/dance_thread.wav"),
	&"fizzle": preload("res://assets/audio/sfx/dance_fizzle.wav"),
}

## Groupe des Hurtbox que le héros peut frapper (orientation automatique).
const TARGET_GROUP := &"enemy_hurtbox"
## Demi-tons dans une octave (hauteur du carillon).
const SEMITONES_PER_OCTAVE := 12.0

## Joystick tactile ; s'il n'est pas touché, on lit le clavier ou la manette.
@export var joystick: FloatingJoystick

## Faux dans les tests : les commandes sont alors fixées à la main (input_move, input_jump_held, press).
var reads_player_input: bool = true
## Direction demandée à l'écran : x vers la droite, y vers le bas, longueur de 0 à 1.
var input_move: Vector2 = Vector2.ZERO
## Vrai tant que le bouton de saut est tenu.
var input_jump_held: bool = false
## Vrai tant que Frappe est tenue (coup chargé).
var input_attack_held: bool = false
## Charge du coup chargé en cours ou qui part (0 à 1).
var charge_level: float = 0.0
## Muet visé par le coup en cours (coup de grâce, riposte) ; null pour un coup ordinaire.
var attack_target: Muet

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
## Vrai pendant les fenêtres d'invulnérabilité des esquives (roulade, élan aérien, Salto
## arc-en-ciel) : un coup qui arrive alors est une esquive parfaite.
var invulnerable: bool = false
## Niveau du héros.
var level: int = 0
## Coups qui touchent à la suite.
var combo: ComboCounter
## Jauge de groove : pleine, Frappe en l'air lance le Salto arc-en-ciel.
var groove: GrooveGauge
## Juge un appui fait maintenant (remplacé dans les tests pour choisir le jugement).
var judge: Callable = _judge_now
## Forces du héros (niveau, talents, objets portés), recalculées quand le profil change.
var stats: HeroStats
## Le second souffle a déjà servi pendant cette sortie.
var second_wind_used: bool = false
## Évanoui : il ne bouge plus jusqu'à la fin de la sortie.
var fainted_now: bool = false
## Tirages des coups critiques (graine réglable dans les tests).
var rng := RandomNumberGenerator.new()
## Dernier coup qui a touché (mise au point).
var last_hit: HitData

var tuning: TuningData = Tuning.data

var _combo_step: int = 0
var _judgements: Dictionary[StringName, RhythmMath.Judgement] = {}
var _pending_groove: float = 0.0
var _hurt_invuln_left: float = 0.0
var _next_hit_critical: bool = false
var _last_attack_end: float = -INF
var _roll_end: float = -INF

## Danse (version 4.1) : visée du pouce pour la prochaine danse (longueur 0 à 1 ; `dance_manual`
## faux : visée automatique), fil d'écho tenu, visée montrée au sol pendant qu'on glisse.
var dance_stick: Vector2 = Vector2.ZERO
var dance_manual: bool = false
var thread_held: bool = false
var dance_aiming: bool = false
## Figure qui va être dansée (choisie quand la danse est acceptée).
var pending_figure: StringName = &""
var _dance_step: int = 0
var _dance_aim: DanceAim
var _journal_groove: float = 0.0
var _last_dance_end: float = -INF
var _riposte_target: Muet
var _riposte_until: float = -INF
var _move_sound: AudioStreamPlayer

var _buffer: InputBuffer
var _clock: float = 0.0
var _spawn: Transform3D
## Point le plus haut atteint depuis le dernier contact avec le sol (m) : hauteur de chute.
var _air_peak: float = 0.0

@onready var state_machine: StateMachine = $StateMachine
@onready var visual: HeroVisual = $Visual
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: Health = $Health
@onready var beat_ring: BeatRing = $BeatRing
@onready var _hit_sound: AudioStreamPlayer = $HitSound
@onready var _chime: AudioStreamPlayer = $ChimeSound
@onready var _answer_sound: AudioStreamPlayer = $AnswerSound
@onready var _hurt_sound: AudioStreamPlayer = $HurtSound
@onready var _dodge_sound: AudioStreamPlayer = $DodgeSound
@onready var _jump_sound: AudioStreamPlayer = $JumpSound
@onready var _salto_sound: AudioStreamPlayer = $SaltoSound
@onready var _land_sound: AudioStreamPlayer = $LandSound
@onready var _roll_sound: AudioStreamPlayer = $RollSound
@onready var _swing_sound: AudioStreamPlayer = $SwingSound
@onready var _carried_drum: Node3D = $Visual/CarriedDrum
@onready var _collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	_buffer = InputBuffer.new(tuning.input_buffer_time)
	_spawn = global_transform
	floor_snap_length = tuning.step_height
	var capsule: CapsuleShape3D = _collision.shape as CapsuleShape3D
	capsule.radius = tuning.hero_radius
	capsule.height = tuning.hero_height
	_collision.position = Vector3.UP * tuning.hero_height / 2.0
	visual.setup(tuning.hero_height, tuning.hero_roll_drop)
	visual.trail.lifetime = tuning.trail_time
	visual.trail.inner_reach = tuning.trail_inner_reach
	visual.trail.outer_reach = tuning.trail_outer_reach
	level = tuning.hero_start_level
	stats = HeroStats.compute(Game.profile, tuning, _run_boons(), _run_pacts())
	combo = ComboCounter.new(tuning.combo_timeout)
	groove = GrooveGauge.new(tuning.groove_max)
	rng.randomize()
	var reach_shape: CollisionShape3D = $Hitbox/CollisionShape3D
	(reach_shape.shape as SphereShape3D).radius = tuning.hitbox_radius
	reach_shape.position = Vector3.UP * tuning.hero_height / 2.0
	hitbox.vertical_reach = tuning.attack_vertical_reach
	hitbox.landed.connect(_on_hit_landed)
	var body_shape: CollisionShape3D = $Hurtbox/CollisionShape3D
	(body_shape.shape as CapsuleShape3D).radius = tuning.hero_radius
	(body_shape.shape as CapsuleShape3D).height = tuning.hero_height
	body_shape.position = Vector3.UP * tuning.hero_height / 2.0
	hurtbox.radius = tuning.hero_radius
	health.setup(stats.max_health)
	hurtbox.damage_taken_multiplier = stats.damage_taken
	equip(Game.run.weapon if Game.run else (Game.profile.weapon if Game.profile else &""))
	Game.stats_changed.connect(_on_stats_changed)
	Game.level_up.connect(_on_level_up)
	hurtbox.hurt.connect(_on_hurt)
	hurtbox.dodged.connect(_on_dodged)
	add_to_group(&"debug_info")
	add_to_group(&"hero")
	_carried_drum.visible = false
	# Combat libre (version 3.1) : plus d'anneau du battement au sol.
	beat_ring.visible = false
	beat_ring.set_process(false)
	Game.drum_picked.connect(func() -> void: _carried_drum.visible = true)
	Game.drum_dropped.connect(func() -> void: _carried_drum.visible = false)
	Game.drum_returned.connect(func(_count: int) -> void: _carried_drum.visible = false)
	_move_sound = AudioStreamPlayer.new()
	_move_sound.name = "MoveSound"
	add_child(_move_sound)
	_dance_aim = DanceAim.new()
	_dance_aim.name = "DanceAim"
	add_child(_dance_aim)
	state_machine.start()


func _physics_process(delta: float) -> void:
	# Arrêt sur image : le temps ne passe pas. Un pas de physique de durée nulle peut rendre une
	# position invalide (NaN) : rien ne bouge pendant l'arrêt.
	if delta <= 0.0:
		return
	_clock += delta
	coyote_left = maxf(coyote_left - delta, 0.0)
	roll_cooldown_left = maxf(roll_cooldown_left - delta, 0.0)
	_hurt_invuln_left = maxf(_hurt_invuln_left - delta, 0.0)
	combo.update(_clock)
	groove.drain(delta, tuning.groove_idle_time, tuning.groove_drain_rate)
	# Journal de jeu : le groove gagné et perdu (dépensé ou retombé) depuis l'image précédente.
	var groove_change: float = groove.value - _journal_groove
	if groove_change != 0.0:
		Journal.count("groove_up" if groove_change > 0.0 else "groove_down", absf(groove_change))
		_journal_groove = groove.value
	if reads_player_input:
		_read_player_input()
	state_machine.physics_update(delta)
	hurtbox.can_be_hit = not invulnerable and _hurt_invuln_left <= 0.0
	hitbox.update(delta)
	visual.update_pose(facing_yaw, delta)
	_update_dance_aim()
	visual.visible = _hurt_invuln_left <= 0.0 or fposmod(_hurt_invuln_left, tuning.hurt_blink_period) < tuning.hurt_blink_period / 2.0
	if global_position.y < _spawn.origin.y - tuning.respawn_fall_depth or not global_position.is_finite():
		respawn()


## Enregistre un appui ; il reste valable input_buffer_time secondes.
## Frappe est jugée tout de suite par rapport au temps (au moment de l'appui, pas du coup).
func press(action: StringName) -> void:
	_buffer.press(action, _clock)
	Journal.count("press:" + action)
	action_pressed.emit(action)
	if action == &"attack":
		var judgement: RhythmMath.Judgement = judge.call()
		_judgements[action] = judgement
		_on_judged(judgement)


## Jugement du dernier appui sur `action` (raté s'il n'y en a pas) ; il ne sert qu'une fois.
func take_judgement(action: StringName) -> RhythmMath.Judgement:
	var judgement: RhythmMath.Judgement = _judgements.get(action, RhythmMath.Judgement.MISS)
	_judgements.erase(action)
	return judgement


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


var _level: Level
## Instrument-arme en main (version 2.8 ; voir WeaponData).
var weapon: WeaponData


## Prend l'instrument `id` en main : son enchaînement remplace le précédent.
func equip(weapon_id: StringName) -> void:
	weapon = tuning.weapon(weapon_id)
	_combo_step = 0
	if weapon:
		visual.show_instrument(weapon)


## Dons de l'expédition en cours (aucun hors expédition).
func _run_boons() -> Dictionary[StringName, int]:
	var boons: Dictionary[StringName, int] = {}
	if Game.run:
		boons = Game.run.boons
	return boons


## Pactes de l'expédition en cours (aucun hors expédition).
func _run_pacts() -> Array[StringName]:
	var pacts: Array[StringName] = []
	if Game.run:
		pacts = Game.run.pacts
	return pacts


## Enchaînement de l'instrument en main.
func combo_attacks() -> Array[AttackData]:
	return weapon.combo if weapon and not weapon.combo.is_empty() else tuning.combo_attacks


## Part de la vitesse de course permise par le sol sous le héros (l'eau ralentit, version 2.6).
func terrain_speed() -> float:
	if not is_instance_valid(_level):
		_level = get_tree().get_first_node_in_group(&"night_level") as Level
	return _level.terrain_speed(global_position) if _level else 1.0


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


## Sauts autorisés avant de retoucher le sol (le dernier est le salto) : un de plus avec le
## Triple saut.
func max_jumps() -> int:
	return tuning.max_jumps + stats.extra_jumps


## Saute avec la vitesse verticale `speed` ; le dernier saut autorisé est le salto.
func jump(speed: float) -> void:
	velocity.y = speed
	jumps_used += 1
	coyote_left = 0.0
	visual.squash(tuning.hero_squash_jump)
	var fx: Effects = Effects.of(self)
	if jumps_used >= max_jumps():
		visual.play_salto(tuning.salto_duration)
		_salto_sound.play()
		if fx:
			fx.ring(global_position, tuning.fx_double_ring, fx.white, tuning.fx_double_ring_time)
			fx.burst(global_position + Vector3.UP * tuning.fx_double_height, tuning.fx_double_cubes, tuning.fx_double_speed)
	else:
		_jump_sound.play()
		if fx and is_on_floor():
			fx.dust(global_position, tuning.fx_jump_dust, tuning.fx_jump_dust_speed)


## Saute en l'air s'il reste un saut : saut normal pendant la tolérance de bord, sinon salto.
## Consomme l'appui seulement si le saut a lieu ; sinon il reste en mémoire pour l'atterrissage.
func try_air_jump() -> bool:
	if coyote_left > 0.0:
		if not consume_press(&"jump"):
			return false
		jump(tuning.jump_speed)
		return true
	if jumps_used >= max_jumps() or not consume_press(&"jump"):
		return false
	# Tombé d'un bord sans sauter : le saut en l'air est directement le salto.
	jumps_used = maxi(jumps_used, max_jumps() - 1)
	jump(tuning.double_jump_speed)
	return true


## Déplace le corps selon `velocity`, en montant les petites marches.
func move(delta: float) -> void:
	if not velocity.is_finite():
		velocity = Vector3.ZERO
	var falling_speed: float = 0.0 if is_on_floor() else -velocity.y
	var before: Vector3 = global_position
	_step_up(delta)
	move_and_slide()
	# Rarement, le moteur physique rend une position invalide : on reste où l'on était.
	if not global_position.is_finite() or not velocity.is_finite():
		global_position = before
		velocity = Vector3.ZERO
		return
	_slide_off_muets(delta)
	if falling_speed > 0.0 and is_on_floor():
		_on_landed(falling_speed)
	if is_on_floor():
		_air_peak = global_position.y
	else:
		_air_peak = maxf(_air_peak, global_position.y)


## On ne tient pas debout sur une Sourdine (bug trouvé par le robot joueur, version 4.2.1) : posé
## sur l'une d'elles, le héros glisse de côté ; sinon ses coups, portés à hauteur de buste,
## passeraient au-dessus d'elle.
func _slide_off_muets(delta: float) -> void:
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision3D = get_slide_collision(i)
		var muet: Muet = collision.get_collider() as Muet
		if muet == null or collision.get_normal().y < tuning.hero_floor_normal_min:
			continue
		var away := Vector3(global_position.x - muet.global_position.x, 0.0, global_position.z - muet.global_position.z)
		if away.is_zero_approx():
			away = facing_direction()
		global_position += away.normalized() * tuning.hero_slide_off_speed * delta
		return


## Son d'un mouvement : « roll » (roulade), « swing » (coup dans le vide), « charge » (le coup
## chargé monte), « grace » (coup de grâce), « riposte », une figure de danse ou « fizzle » (pas
## manqué) ; « stop » coupe la charge et le fil d'écho.
func play_move_sound(sound: StringName) -> void:
	match sound:
		&"roll":
			_roll_sound.play()
		&"swing":
			_swing_sound.pitch_scale = 1.0 + rng.randf_range(-tuning.hit_pitch_variation, tuning.hit_pitch_variation)
			_swing_sound.play()
		&"charge", &"grace", &"riposte":
			_move_sound.stream = {&"charge": CHARGE_SOUND, &"grace": GRACE_SOUND, &"riposte": RIPOSTE_SOUND}[sound]
			_move_sound.play()
		&"palm", &"spiral", &"rain", &"thread", &"fizzle":
			_move_sound.stream = DANCE_SOUNDS[sound]
			_move_sound.play()
		&"stop":
			if _move_sound.stream == CHARGE_SOUND or _move_sound.stream == DANCE_SOUNDS[&"thread"]:
				_move_sound.stop()


## Atterrissage à `speed` m/s : un bruit sourd, et de la poussière d'autant plus que la chute
## était haute.
func _on_landed(speed: float) -> void:
	if speed >= tuning.land_sound_speed:
		_land_sound.play()
	var fall: float = _air_peak - global_position.y
	visual.squash(-minf(tuning.hero_squash_land_max, tuning.hero_squash_land_base + fall * tuning.hero_squash_land_per_meter))
	visual.animator.land(fall)
	var fx: Effects = Effects.of(self)
	if fx and fall > tuning.fx_land_min_fall:
		var count: int = mini(tuning.fx_land_dust_max, tuning.fx_land_dust_min + floori(fall * tuning.fx_land_dust_per_meter))
		fx.dust(global_position, count, tuning.fx_land_dust_speed)


## Temps de jeu écoulé depuis l'apparition du héros (s).
func clock() -> float:
	return _clock


## Coup à jouer quand Frappe est appuyée au sol : le coup de grâce près d'un Muet qui chancelle,
## la riposte juste après une esquive parfaite, le coup chargé qu'on relâche, le coup roulé pendant
## ou juste après une roulade, sinon le coup suivant de l'enchaînement s'il est encore ouvert, sinon
## le premier. `attack_target` : le Muet visé (grâce, riposte), sinon null.
func next_attack(previous_state: StringName) -> AttackData:
	attack_target = null
	var graced: Muet = grace_target()
	if graced:
		_combo_step = 0
		attack_target = graced
		return tuning.grace_attack
	if riposte_ready():
		_combo_step = 0
		attack_target = _riposte_target
		_riposte_until = -INF
		return tuning.riposte_attack
	if previous_state == &"Charge":
		_combo_step = 0
		return tuning.charged_attack
	if previous_state == &"Roll" or _clock - _roll_end <= tuning.rolling_kick_grace:
		_combo_step = 0
		return tuning.rolling_kick
	if previous_state != &"Attack" and _clock - _last_attack_end > tuning.combo_chain_window:
		_combo_step = 0
	var combo_list: Array[AttackData] = combo_attacks()
	_combo_step = _combo_step % combo_list.size()
	var attack: AttackData = combo_list[_combo_step]
	_combo_step = (_combo_step + 1) % combo_list.size()
	return attack


## Note la fin d'un coup (pour savoir si l'enchaînement reste ouvert).
func end_attack() -> void:
	_last_attack_end = _clock


## Note la fin d'une roulade (pour le coup roulé).
func end_roll() -> void:
	_roll_end = _clock


## Le Muet qui chancelle le plus proche, à portée du coup de grâce (ou null).
func grace_target() -> Muet:
	var best: Muet = null
	var best_distance: float = tuning.grace_range
	for node: Node in get_tree().get_nodes_in_group(&"muets"):
		var muet: Muet = node as Muet
		if muet == null or not muet.can_receive_grace():
			continue
		var distance: float = Vector2(muet.global_position.x - global_position.x, muet.global_position.z - global_position.z).length()
		if distance <= best_distance:
			best = muet
			best_distance = distance
	return best


## Vrai si une riposte est possible : esquive parfaite récente, Muet esquivé encore là et à portée.
func riposte_ready() -> bool:
	if _clock > _riposte_until or not is_instance_valid(_riposte_target) or _riposte_target.is_freed():
		return false
	var flat := Vector2(_riposte_target.global_position.x - global_position.x, _riposte_target.global_position.z - global_position.z)
	return flat.length() <= tuning.riposte_range


## Direction du coup `attack` : vers le Muet visé (grâce, riposte), sinon la visée automatique.
func attack_direction() -> Vector3:
	if is_instance_valid(attack_target):
		var flat := Vector3(attack_target.global_position.x - global_position.x, 0.0, attack_target.global_position.z - global_position.z)
		if not flat.is_zero_approx():
			return flat.normalized()
	return aim_direction()


## Élan du coup `attack` (m) : vers le Muet visé, jusqu'à mi-portée ; sinon celui du coup.
func attack_lunge(attack: AttackData) -> float:
	if not is_instance_valid(attack_target):
		return attack.lunge
	var distance: float = Vector2(attack_target.global_position.x - global_position.x, attack_target.global_position.z - global_position.z).length()
	return CombatMath.lunge_to(distance, attack_target.hurtbox.radius, attack.reach, tuning.riposte_range)


## Frappe relâchée : le coup chargé part, jugé sur le temps au moment où l'on relâche.
func release_charge() -> void:
	var judgement: RhythmMath.Judgement = judge.call()
	_judgements[&"attack"] = judgement
	_on_judged(judgement)


## Roulade épineuse (don) : les Muets traversés pendant la roulade sont blessés.
func roll_strike() -> void:
	# Roulade épineuse (dégâts) et Ressac (elle repousse les Muets traversés).
	if stats.roll_damage <= 0.0 and stats.tide <= 0.0:
		return
	var make_hit: Callable = _make_hit.bind(stats.roll_damage, &"thorns", RhythmMath.Judgement.MISS, 0.0, tuning.thorns_poise, stats.tide)
	hitbox.activate(tuning.thorns_radius, CombatMath.FULL_CIRCLE_DEG, facing_direction(), tuning.roll_duration, make_hit)


## Direction du prochain coup : vers la cible la plus proche dans le cône d'orientation
## automatique, sinon la direction demandée (ou le regard).
func aim_direction() -> Vector3:
	var forward: Vector3 = intended_direction()
	var targets: Array[Node] = get_tree().get_nodes_in_group(TARGET_GROUP)
	var positions := PackedVector3Array()
	for target: Node in targets:
		positions.append((target as Node3D).global_position)
	var index: int = CombatMath.pick_target(global_position, forward, positions, tuning.auto_aim_range, tuning.auto_aim_cone_deg)
	if index < 0:
		return forward
	var to_target: Vector3 = positions[index] - global_position
	return Vector3(to_target.x, 0.0, to_target.z).normalized()


## Porte le coup `attack` dans `direction` : la zone de coup est active à partir de maintenant,
## pendant `active_time` secondes (par défaut attack_active_time). `power` multiplie ses dégâts,
## son coup à l'équilibre et sa projection (coup chargé).
func strike(attack: AttackData, direction: Vector3, judgement: RhythmMath.Judgement, active_time: float = -1.0, power: float = 1.0) -> void:
	_pending_groove = action_groove(RhythmMath.groove_gain(judgement, tuning))
	var make_hit: Callable = _make_hit.bind(attack.damage_multiplier * power, attack.id, judgement, 0.0, attack.poise * power, attack.launch * power)
	if attack.projectiles > 0:
		_shoot(attack, direction, make_hit)
		return
	var duration: float = active_time if active_time >= 0.0 else tuning.attack_active_time
	hitbox.activate(attack.reach, attack.arc_deg, direction, duration, make_hit)


## Groove gagné par un coup qui touche (version 3.1) : une part fixe, plus avec le combo (et le
## bonus d'un jugement, si un test en impose un).
func action_groove(judged_bonus: float) -> float:
	return tuning.groove_hit * (1.0 + minf(float(combo.hits), tuning.groove_combo_cap) * tuning.groove_combo_step) + judged_bonus


## Geyser (don double) : l'esquive parfaite fait jaillir une onde brûlante ; les Muets autour
## (Tuning.drumroll_radius) sont touchés sans passer par la zone de coup.
func _geyser() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"muets"):
		var muet: Muet = node as Muet
		if muet.is_freed() or muet.flat_distance_to(global_position) > tuning.drumroll_radius + muet.hurtbox.radius:
			continue
		var hit: HitData = _make_hit(muet.hurtbox, stats.geyser, &"geyser", RhythmMath.Judgement.MISS, 0.0, tuning.quake_poise, tuning.quake_launch)
		if muet.hurtbox.receive(hit):
			hitbox.landed.emit(hit, muet.hurtbox)
			muet.burn(stats.attack * stats.geyser, tuning.burn_time)
	var fx: Effects = Effects.of(self)
	if fx:
		fx.ring(global_position, tuning.drumroll_radius, fx.gold, tuning.fx_quake_ring_time)


## Danses de l'Onde (version 4.1) : demande une danse, visée par le pouce (`stick`, longueur 0 à 1)
## si `manual`, sinon vers la Sourdine la plus proche.
func request_dance(stick: Vector2, manual: bool) -> void:
	dance_stick = stick
	dance_manual = manual and not stick.is_zero_approx()
	press(&"dance")


## Vrai si le héros a appris à danser (voie de l'Onde).
func can_dance() -> bool:
	return DanceMath.can_dance(stats.dance)


## Figure qui viendrait à la prochaine danse (l'enchaînement retombe à la première après un temps).
func next_dance_figure() -> StringName:
	return DanceMath.figure(_chain_step(), stats.dance)


## Pas de l'enchaînement des danses : on continue si la dernière vibration est partie il y a peu.
func _chain_step() -> int:
	return _dance_step if _clock - _last_dance_end <= tuning.dance_chain_window else 0


## Vrai si une danse part maintenant : le fil d'écho tenu, ou un appui sur Danse ; `pending_figure`
## dit laquelle. Sans assez de groove, rien ne part : un pas manqué, que le bouton montre.
func wants_dance() -> bool:
	if not can_dance():
		_buffer.consume(&"dance", _clock)
		return false
	if thread_held and stats.dance.has(DanceMath.THREAD):
		return _accept_dance(DanceMath.THREAD)
	if consume_press(&"dance"):
		return _accept_dance(next_dance_figure())
	return false


func _accept_dance(figure: StringName) -> bool:
	if figure == &"":
		return false
	if groove.value < DanceMath.cost(figure, tuning):
		Journal.count("dance:fizzle")
		thread_held = false
		play_move_sound(&"fizzle")
		var fx: Effects = Effects.of(self)
		if fx:
			fx.dust(hand_point(), tuning.fx_step_dust, tuning.fx_step_dust_speed)
		dance_fizzled.emit()
		return false
	pending_figure = figure
	Journal.count("dance:" + figure)
	Journal.count("dance:manual" if dance_manual else "dance:auto")
	if figure != DanceMath.THREAD:
		groove.add(-DanceMath.cost(figure, tuning))
		_dance_step = _chain_step() + 1
	return true


## Note le départ de la vibration (l'enchaînement vers la figure suivante reste ouvert un moment).
func end_dance() -> void:
	_last_dance_end = _clock


## Visée de la danse `figure` : direction (horizontale, normalisée) et point visé (pour la pluie
## de pas). Glisser-relâcher : là où pointe le pouce ; sinon la Sourdine la plus proche à portée,
## sinon droit devant.
func dance_aim(figure: StringName) -> Dictionary:
	var direction: Vector3 = DanceMath.aim_direction(dance_stick) if dance_manual else Vector3.ZERO
	var distance: float = DanceMath.rain_distance(dance_stick, tuning)
	if direction.is_zero_approx():
		var positions := PackedVector3Array()
		for node: Node in get_tree().get_nodes_in_group(&"muets"):
			var muet: Muet = node as Muet
			if muet and not muet.is_freed():
				positions.append(muet.global_position)
		var index: int = DanceMath.auto_target(global_position, positions, tuning.dance_range)
		if index >= 0:
			var flat := Vector3(positions[index].x - global_position.x, 0.0, positions[index].z - global_position.z)
			direction = flat.normalized() if not flat.is_zero_approx() else facing_direction()
			distance = clampf(flat.length(), tuning.dance_rain_min, tuning.dance_rain_max) if figure == DanceMath.RAIN else flat.length()
		else:
			direction = facing_direction()
	return {&"direction": direction, &"point": global_position + direction * distance}


## Visée montrée au sol tant qu'on tient le bouton Danse (pas pendant la danse elle-même).
func _update_dance_aim() -> void:
	if not dance_aiming or not can_dance() or state_machine.current.name == &"Dance":
		_dance_aim.visible = false
		return
	var figure: StringName = DanceMath.THREAD if thread_held else next_dance_figure()
	var aim: Dictionary = dance_aim(figure)
	_dance_aim.show_aim(figure, global_position, aim[&"direction"], aim[&"point"])


## Bout des doigts de la main qui danse (monde), d'où part la vibration.
func hand_point(right: bool = true) -> Vector3:
	if visual and visual.character:
		return visual.character.hand_point(right)
	return global_position + Vector3.UP * tuning.dance_wave_height


## Fabrique d'un coup de la figure `figure` (dégâts selon son rang ; pas de groove gagné).
func dance_hit(figure: StringName) -> Callable:
	var multiplier: float = DanceMath.damage(figure, int(stats.dance.get(figure, 1)), tuning)
	if figure == DanceMath.THREAD:
		multiplier *= tuning.dance_thread_tick
	return _make_hit.bind(multiplier, figure, RhythmMath.Judgement.MISS, 0.0, tuning.dance_poise, 0.0)


## La vibration part : l'onde de paume droit devant, les orbes de la spirale, ou la pluie de pas au
## point visé.
func cast_dance(figure: StringName, direction: Vector3, point: Vector3) -> void:
	var parent: Node = get_parent()
	var start: Vector3 = hand_point()
	start.y = global_position.y + tuning.dance_wave_height
	match figure:
		DanceMath.PALM, DanceMath.SPIRAL:
			var count: int = 1 if figure == DanceMath.PALM else tuning.dance_spiral_orbs
			for i: int in count:
				var wave := DanceWave.new()
				wave.figure = figure
				wave.direction = direction
				wave.reach = tuning.dance_range
				wave.phase = TAU * i / count
				wave.make_hit = dance_hit(figure)
				wave.shooter = self
				wave.material = visual.prop_material
				parent.add_child(wave)
				wave.global_position = start
		DanceMath.RAIN:
			var rain := DanceRain.new()
			rain.make_hit = dance_hit(figure)
			rain.shooter = self
			parent.add_child(rain)
			rain.global_position = Vector3(point.x, global_position.y, point.z)
	Feedback.vibrate(tuning.vibration_hit)


## Le fil d'écho commence : le rayon est créé (le DanceState le place et le fait frapper).
func start_thread() -> DanceThread:
	var thread := DanceThread.new()
	thread.make_hit = dance_hit(DanceMath.THREAD)
	thread.shooter = self
	get_parent().add_child(thread)
	return thread


## Sarbacane : les fléchettes du coup `attack` partent en éventail autour de `direction`.
func _shoot(attack: AttackData, direction: Vector3, make_hit: Callable) -> void:
	var parent: Node = get_parent()
	for i: int in attack.projectiles:
		var offset: float = (i - (attack.projectiles - 1) / 2.0) * deg_to_rad(tuning.dart_spread_deg)
		var dart := Dart.new()
		dart.direction = direction.rotated(Vector3.UP, offset)
		dart.speed = tuning.dart_speed
		dart.reach = tuning.dart_range
		dart.pierce = attack.pierce
		dart.make_hit = make_hit
		dart.shooter = self
		dart.material = visual.prop_material
		parent.add_child(dart)
		dart.global_position = global_position + Vector3.UP * tuning.dart_height + dart.direction * tuning.hero_radius


## Onde à l'atterrissage d'un plongeon : touche tout autour dans `radius` mètres.
## `colors` : une onde par couleur, de plus en plus grande (une seule pour le plongeon normal).
func shockwave(radius: float, multiplier: float, move: StringName, judgement: RhythmMath.Judgement, stun_time: float, colors: Array[Color]) -> void:
	_pending_groove = action_groove(RhythmMath.groove_gain(judgement, tuning))
	var rainbow: bool = move == &"rainbow"
	var poise: float = tuning.rainbow_poise if rainbow else tuning.dive_poise
	var launch: float = tuning.rainbow_launch if rainbow else tuning.dive_launch
	var make_hit: Callable = _make_hit.bind(multiplier, move, judgement, stun_time, poise, launch)
	hitbox.activate(radius, CombatMath.FULL_CIRCLE_DEG, facing_direction(), tuning.attack_active_time, make_hit)
	Feedback.shake(tuning.shake_trauma_dive, Vector3.ZERO)
	for orb: Node in get_tree().get_nodes_in_group(&"silence_orbs"):
		var at: Vector3 = (orb as Node3D).global_position
		if Vector2(at.x - global_position.x, at.z - global_position.z).length() < radius:
			orb.call(&"pop")
	if move == &"rainbow":
		get_tree().call_group(&"world_mood", &"burst")
		Feedback.vibrate(tuning.vibration_rainbow)
		# Floraison (don double) : le Salto arc-en-ciel soigne.
		if stats.bloom > 0.0:
			health.heal(health.maximum * stats.bloom)
	var fx: Effects = Effects.of(self)
	if fx == null:
		return
	if move == &"rainbow":
		fx.burst(global_position + Vector3.UP * tuning.fx_double_height, tuning.fx_rainbow_cubes, tuning.fx_rainbow_speed)
		fx.ring(global_position, tuning.fx_rainbow_ring, fx.white, tuning.fx_rainbow_ring_time, true)
	for i: int in colors.size():
		fx.ring(global_position, radius * (i + 1) / colors.size(), colors[i], tuning.fx_dive_ring_time)
	fx.dust(global_position, tuning.fx_dive_dust, tuning.fx_dive_dust_speed)


## Rebond d'un champignon-trampoline : le héros repart vers le haut à `speed` ; comme après un
## saut, le salto reste possible.
func bounce(speed: float) -> void:
	var fx: Effects = Effects.of(self)
	if fx:
		fx.ring(global_position, tuning.fx_bounce_ring, fx.pink, tuning.fx_bounce_ring_time)
	velocity.y = speed
	jumps_used = 1
	coyote_left = 0.0
	visual.stop_spin()
	state_machine.transition_to(&"Air")


## Ramène le héros au village (point de départ), avec tous ses points de vie ; le tambour
## qu'il portait est perdu (il retourne à son sanctuaire).
func respawn() -> void:
	global_transform = _spawn
	velocity = Vector3.ZERO
	_buffer.clear()
	health.restore()
	Game.drop_drum()
	reset_physics_interpolation()
	state_machine.transition_to(&"Air")
	respawned.emit()


## Une sortie commence : forces recalculées, tous les PV, second souffle de nouveau disponible.
func begin_sortie() -> void:
	equip(Game.run.weapon if Game.run else Game.profile.weapon)
	_on_stats_changed()
	health.restore()
	second_wind_used = false
	fainted_now = false


## Le héros a donné à un Muet de l'espèce `species` la réponse qu'il attendait (docs/GDD.md §7) :
## une note, et la jauge de groove se remplit (le cercle de couleurs grandit).
func on_answer(species: StringName) -> void:
	groove.add(tuning.groove_answer * stats.groove)
	_answer_sound.pitch_scale = 1.0 + rng.randf_range(-tuning.hit_pitch_variation, tuning.hit_pitch_variation)
	_answer_sound.play()
	answered.emit(species)


## Un Muet vient d'être libéré (appelé par le Muet sur le groupe « hero »).
func on_enemy_freed(muet: Node) -> void:
	groove.add(tuning.groove_enemy_freed * stats.groove + stats.splash)
	if stats.heal_per_muet > 0.0 and not health.is_depleted():
		health.heal(stats.heal_per_muet)
	# Cendres : le Muet libéré enflamme ceux qui l'entourent.
	var freed: Node3D = muet as Node3D
	if stats.cinders > 0.0 and freed:
		for node: Node in get_tree().get_nodes_in_group(&"muets"):
			var other: Muet = node as Muet
			if other != freed and not other.is_freed() and other.flat_distance_to(freed.global_position) <= tuning.cinders_radius:
				other.burn(stats.attack * stats.cinders, tuning.burn_time)


## Une onde de choc est passée sous le héros en l'air.
func on_wave_jumped() -> void:
	groove.add(tuning.groove_wave_jumped * stats.groove)


## Lignes affichées par l'overlay de mise au point.
func debug_text() -> String:
	var text: String = "%s · sauts %d/%d · élans %d/%d%s%s" % [
		state_machine.current.name,
		jumps_used,
		max_jumps(),
		air_dashes_used,
		stats.air_dashes,
		" · invulnérable" if invulnerable else "",
		" · tambour" if Game.progress.carrying_drum else "",
	]
	text += "\nPV %.0f/%.0f · combo %d · groove %.1f/%.0f" % [health.current, health.maximum, combo.hits, groove.value, groove.maximum]
	text += "\ntambours %d/%d · pages %d · xp à rapporter %.0f%s" % [
		Game.progress.drums_returned,
		Game.progress.drums_required,
		Game.progress.pages.size(),
		Game.progress.xp_carried,
		" · nuit accomplie" if Game.progress.is_complete() else "",
	]
	if last_hit:
		text += " · %s %.1f%s" % [last_hit.move, last_hit.damage, " critique" if last_hit.critical else ""]
	return text


func _make_hit(hurtbox: Hurtbox, multiplier: float, move: StringName, judgement: RhythmMath.Judgement, stun_time: float, poise: float, launch: float) -> HitData:
	var hit := HitData.new()
	hit.attacker = self
	hit.target = hurtbox
	hit.move = move
	hit.judgement = judgement
	hit.stun_time = stun_time
	hit.critical = _next_hit_critical or rng.randf() < stats.crit_chance or move == &"riposte"
	_next_hit_critical = false
	var attack: float = stats.attack
	var move_multiplier: float = multiplier * RhythmMath.damage_multiplier(judgement, tuning)
	if judgement == RhythmMath.Judgement.PERFECT:
		move_multiplier *= stats.perfect_damage
	hit.damage = CombatMath.damage(attack, move_multiplier, CombatMath.combo_multiplier(combo.hits, tuning), hit.critical, tuning)
	hit.poise = poise * (tuning.poise_perfect_multiplier if judgement == RhythmMath.Judgement.PERFECT else 1.0) * (1.0 + stats.anchor)
	hit.launch = launch
	hit.power = attack
	var muet: Muet = hurtbox.get_parent() as Muet
	# Dons 2.8 : Brasier (Muet en feu), Coup de forge, Contrepoint (riposte), Prisme (critique),
	# Éblouissement (étourdit parfois).
	if muet and muet.is_burning():
		hit.damage *= 1.0 + stats.blaze
	if move == &"charged":
		hit.damage *= 1.0 + stats.forge
	elif move == &"riposte":
		hit.damage *= 1.0 + stats.counterpoint
	if hit.critical:
		hit.damage *= 1.0 + stats.prism
	if stats.dazzle > 0.0 and rng.randf() < stats.dazzle:
		hit.stun_time = maxf(hit.stun_time, tuning.dazzle_stun)
	# Coup de grâce : il libère le Muet qui chancelle ; le Grand Muet, lui, encaisse un grand coup.
	if move == &"grace" and muet and muet.can_receive_grace():
		hit.damage = attack * tuning.grace_boss_damage if muet.is_boss() else muet.health.current / hurtbox.damage_taken_multiplier
	var to_target: Vector3 = hurtbox.global_position - global_position
	to_target.y = 0.0
	hit.direction = facing_direction() if to_target.is_zero_approx() else to_target.normalized()
	hit.point = hurtbox.center() - hit.direction * hurtbox.radius
	return hit


func _on_hit_landed(hit: HitData, _hurtbox: Hurtbox) -> void:
	combo.register_hit(_clock)
	last_hit = hit
	Journal.count("hit:" + hit.move)
	Journal.count("dmg", hit.damage)
	if hit.critical:
		Journal.count("crit")
	if hit.target:
		var muet: Muet = hit.target.get_parent() as Muet
		# Braise : Pied de braise, Coup de forge (le coup chargé), Feu de joie (un critique).
		var burn: float = stats.burn
		if hit.move == &"charged":
			burn = maxf(burn, stats.forge)
		if hit.critical:
			burn = maxf(burn, stats.wildfire)
		if muet and burn > 0.0:
			muet.burn(stats.attack * burn, tuning.burn_time)
	# Le groove d'un coup en rythme n'est gagné qu'une fois, au premier contact.
	var perfect: bool = hit.judgement == RhythmMath.Judgement.PERFECT
	var danced: bool = DanceMath.FIGURES.has(hit.move)
	if _pending_groove > 0.0 and not danced:
		groove.add(_pending_groove * stats.groove * (stats.perfect_groove if perfect else 1.0))
		_play_combo_note()
	if not danced:
		_pending_groove = 0.0
	# Cœur Battant (légendaire, version 3.1) : un coup critique soigne.
	if hit.critical and stats.perfect_heal > 0.0:
		health.heal(stats.perfect_heal)
	# Givre (don) : le Muet touché est ralenti.
	if stats.frost > 0.0 and hit.target:
		var chilled: Muet = hit.target.get_parent() as Muet
		if chilled:
			chilled.chill(stats.frost, tuning.frost_time)
	# Le fil d'écho frappe à petits coups : ni arrêt sur image ni secousse à chacun.
	if hit.move != DanceMath.THREAD:
		Feedback.hit_stop(tuning.hit_stop_perfect if perfect else tuning.hit_stop_hit)
		Feedback.vibrate(tuning.vibration_strong if perfect or hit.critical or hit.answer else tuning.vibration_hit)
		Feedback.shake(tuning.shake_trauma_hit, hit.direction)
	_hit_sound.pitch_scale = 1.0 + rng.randf_range(-tuning.hit_pitch_variation, tuning.hit_pitch_variation)
	_hit_sound.play()
	var fx: Effects = Effects.of(self)
	if fx:
		fx.spark(hit.point, tuning.fx_spark_size_crit if hit.critical else tuning.fx_spark_size, fx.gold if hit.critical else fx.white)
	if hit.move == &"grace":
		_on_grace(hit, fx)
	elif hit.move == &"riposte" and fx:
		fx.ring(hit.point, tuning.fx_dodge_ring, fx.cyan, tuning.fx_dodge_ring_time)
		fx.word(GameTexts.WORD_RIPOSTE, hit.point + Vector3.UP * tuning.hero_height, fx.cyan)
	hit_landed.emit(hit)


## Coup de grâce porté : ralenti, gerbe de couleurs, le groove monte.
func _on_grace(hit: HitData, fx: Effects) -> void:
	Feedback.slow_motion(tuning.grace_slow_time, tuning.grace_time_scale)
	Feedback.shake(tuning.shake_trauma_dive, hit.direction)
	Feedback.vibrate(tuning.vibration_strong)
	groove.add(tuning.groove_grace * stats.groove)
	if fx:
		fx.burst(hit.point + Vector3.UP * tuning.fx_double_height, tuning.fx_rainbow_cubes, tuning.fx_rainbow_speed)
		fx.ring(hit.point, tuning.fx_level_ring, fx.gold, tuning.fx_level_ring_time, true)
		fx.word(GameTexts.WORD_GRACE, hit.point + Vector3.UP * tuning.hero_height, fx.gold, true)


## Coup reçu : le combo est perdu, le héros est repoussé, clignote et devient intouchable un
## moment. À zéro point de vie, retour au point de départ.
func _on_hurt(hit: HitData) -> void:
	combo.reset()
	var source: Muet = hit.attacker as Muet
	Journal.count("hurt:" + (String(source.species) if source else String(hit.move) if hit.move != &"" else "piège"))
	Journal.count("hurtdmg", hit.damage)
	_hurt_invuln_left = tuning.hero_hurt_invuln
	Feedback.hit_stop(tuning.hit_stop_hero)
	Feedback.vibrate(tuning.vibration_hurt)
	Feedback.shake(tuning.shake_trauma_hurt, hit.direction)
	_hurt_sound.play()
	if health.is_depleted():
		_faint()
		return
	var recoil: float = (tuning.hero_recoil_big_speed if hit.big else tuning.hero_recoil_speed) + hit.launch * tuning.hero_throw_speed
	set_horizontal_velocity(hit.direction * recoil)
	state_machine.transition_to(&"Hurt")


## Coup arrivé pendant une invulnérabilité : pendant une esquive, c'est une esquive parfaite
## (ralenti, prochain coup critique, groove). Après un coup reçu, rien de spécial.
func _on_dodged(hit: HitData) -> void:
	if not invulnerable:
		return
	Journal.count("perfect_dodge")
	# Le Muet esquivé s'offre à la riposte un moment.
	var attacker: Muet = hit.attacker as Muet
	if attacker and not attacker.is_freed():
		_riposte_target = attacker
		_riposte_until = _clock + tuning.riposte_window
	Feedback.slow_motion(tuning.perfect_dodge_slow_time, tuning.perfect_dodge_time_scale)
	var fx: Effects = Effects.of(self)
	if fx:
		fx.ring(global_position, tuning.fx_dodge_ring, fx.cyan, tuning.fx_dodge_ring_time)
		fx.word(GameTexts.WORD_PERFECT_DODGE, global_position + Vector3.UP * tuning.hero_height, fx.cyan, true)
	_next_hit_critical = true
	groove.add(tuning.groove_perfect_dodge * stats.groove)
	# Bosquet sacré (don double) : l'esquive parfaite soigne ; Geyser : elle fait jaillir une onde.
	if stats.sacred_grove > 0.0:
		health.heal(stats.sacred_grove)
	if stats.geyser > 0.0:
		_geyser()
	if stats.shadow:
		quake(tuning.shadow_quake_radius, tuning.shadow_quake_damage, &"shadow")
	_dodge_sound.play()


## Retour immédiat d'un appui jugé : carillon (qui monte avec le combo) et éclat de l'anneau.
func _on_judged(judgement: RhythmMath.Judgement) -> void:
	judged.emit(judgement)


## Une note qui monte avec le combo, quand un coup touche (la musique récompense l'action).
func _play_combo_note() -> void:
	var notes: PackedFloat32Array = tuning.chime_scale_semitones
	var semitones: float = notes[mini(combo.hits, notes.size() - 1)]
	_chime.pitch_scale = pow(2.0, semitones / SEMITONES_PER_OCTAVE)
	_chime.volume_db = tuning.good_chime_volume_db
	_chime.play()


func _read_player_input() -> void:
	if joystick and joystick.is_active():
		input_move = joystick.vector
	else:
		input_move = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	input_jump_held = Input.is_action_pressed(&"jump")
	input_attack_held = Input.is_action_pressed(&"attack")
	for action: StringName in BUTTON_ACTIONS:
		if Input.is_action_just_pressed(action):
			press(action)
	# Danse au clavier : visée automatique.
	if Input.is_action_just_pressed(&"dance"):
		request_dance(Vector2.ZERO, false)


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


## Onde qui touche tous les Muets autour du héros (Final fracassant, Pas de l'Ombre) : rayon (m),
## dégâts en multiples de l'attaque.
func quake(radius: float, damage: float, move: StringName) -> void:
	var make_hit: Callable = _make_hit.bind(damage, move, RhythmMath.Judgement.MISS, 0.0, tuning.quake_poise, tuning.quake_launch)
	hitbox.activate(radius, CombatMath.FULL_CIRCLE_DEG, facing_direction(), tuning.attack_active_time, make_hit)
	var fx: Effects = Effects.of(self)
	if fx:
		fx.ring(global_position, radius, fx.violet, tuning.fx_quake_ring_time)
		fx.burst(global_position + Vector3.UP * tuning.fx_double_height, tuning.fx_quake_cubes, tuning.fx_quake_speed, tuning.fx_quake_hue)


## Combat libre (version 3.1) : plus de jugement des appuis ; chaque coup vaut pareil, quel que
## soit l'instant. (Les tests peuvent encore remplacer `judge`.)
func _judge_now() -> RhythmMath.Judgement:
	return RhythmMath.Judgement.MISS


## PV à zéro : une fois par sortie, le second souffle le relève ; sinon il s'évanouit.
func _faint() -> void:
	if stats.second_wind > 0.0 and not second_wind_used:
		second_wind_used = true
		health.restore()
		health.current = health.maximum * stats.second_wind
		_hurt_invuln_left = tuning.second_wind_invuln
		var fx: Effects = Effects.of(self)
		if fx:
			fx.burst(global_position + Vector3.UP * tuning.fx_double_height, tuning.fx_level_cubes, tuning.fx_level_speed, tuning.fx_gold_hue)
			fx.ring(global_position, tuning.fx_level_ring, fx.gold, tuning.fx_level_ring_time)
		second_wind.emit()
		return
	fainted_now = true
	reads_player_input = false
	input_move = Vector2.ZERO
	Game.drop_drum()
	state_machine.transition_to(&"Hurt")
	fainted.emit()


## Niveau, talents ou objets ont changé : nouvelles forces, les PV suivent le nouveau maximum.
func _on_stats_changed() -> void:
	var before: float = health.maximum
	# Les dons de l'expédition en cours comptent aussi (ils changeaient les forces calculées par
	# Game, pas celles du héros : corrigé en 2.8).
	stats = HeroStats.compute(Game.profile, tuning, _run_boons(), _run_pacts())
	hurtbox.damage_taken_multiplier = stats.damage_taken
	health.set_maximum(stats.max_health)
	if stats.max_health > before:
		health.heal(stats.max_health - before)


## Niveau gagné : une partie des PV revient, gerbe et anneau.
func _on_level_up(_level: int) -> void:
	_on_stats_changed()
	health.heal(health.maximum * tuning.level_up_heal)
	var fx: Effects = Effects.of(self)
	if fx:
		fx.burst(global_position + Vector3.UP * tuning.fx_double_height, tuning.fx_level_cubes, tuning.fx_level_speed)
		fx.ring(global_position, tuning.fx_level_ring, fx.green, tuning.fx_level_ring_time)
