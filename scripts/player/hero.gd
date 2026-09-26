class_name Hero
extends CharacterBody3D
## Le héros : lit les commandes, garde la mémoire des appuis et délègue le mouvement
## à sa machine à états (Ground, Air, Roll, AirDash, Attack, Dive). Les états utilisent les outils
## ci-dessous ; les coups passent par la Hitbox et déclenchent les retours d'impact.

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

const BUTTON_ACTIONS: Array[StringName] = [&"jump", &"dodge", &"attack"]

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
	stats = HeroStats.compute(Game.profile, tuning)
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
	Game.stats_changed.connect(_on_stats_changed)
	Game.level_up.connect(_on_level_up)
	hurtbox.hurt.connect(_on_hurt)
	hurtbox.dodged.connect(_on_dodged)
	add_to_group(&"debug_info")
	add_to_group(&"hero")
	_carried_drum.visible = false
	Game.drum_picked.connect(func() -> void: _carried_drum.visible = true)
	Game.drum_dropped.connect(func() -> void: _carried_drum.visible = false)
	Game.drum_returned.connect(func(_count: int) -> void: _carried_drum.visible = false)
	state_machine.start()


func _physics_process(delta: float) -> void:
	_clock += delta
	coyote_left = maxf(coyote_left - delta, 0.0)
	roll_cooldown_left = maxf(roll_cooldown_left - delta, 0.0)
	_hurt_invuln_left = maxf(_hurt_invuln_left - delta, 0.0)
	combo.update(_clock)
	groove.drain(delta, tuning.groove_idle_time, tuning.groove_drain_rate)
	if reads_player_input:
		_read_player_input()
	state_machine.physics_update(delta)
	hurtbox.can_be_hit = not invulnerable and _hurt_invuln_left <= 0.0
	hitbox.update(delta)
	visual.update_pose(facing_yaw, delta)
	visual.visible = _hurt_invuln_left <= 0.0 or fposmod(_hurt_invuln_left, tuning.hurt_blink_period) < tuning.hurt_blink_period / 2.0
	if global_position.y < _spawn.origin.y - tuning.respawn_fall_depth:
		respawn()


## Enregistre un appui ; il reste valable input_buffer_time secondes.
## Frappe est jugée tout de suite par rapport au temps (au moment de l'appui, pas du coup).
func press(action: StringName) -> void:
	_buffer.press(action, _clock)
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
	var falling_speed: float = 0.0 if is_on_floor() else -velocity.y
	_step_up(delta)
	move_and_slide()
	if falling_speed > 0.0 and is_on_floor():
		_on_landed(falling_speed)
	if is_on_floor():
		_air_peak = global_position.y
	else:
		_air_peak = maxf(_air_peak, global_position.y)


## Son d'un mouvement : « roll » (roulade) ou « swing » (coup dans le vide).
func play_move_sound(sound: StringName) -> void:
	match sound:
		&"roll":
			_roll_sound.play()
		&"swing":
			_swing_sound.pitch_scale = 1.0 + rng.randf_range(-tuning.hit_pitch_variation, tuning.hit_pitch_variation)
			_swing_sound.play()


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


## Coup à jouer quand Frappe est appuyée au sol : le coup roulé pendant ou juste après une roulade,
## sinon le coup suivant de l'enchaînement s'il est encore ouvert, sinon le premier.
func next_attack(previous_state: StringName) -> AttackData:
	if previous_state == &"Roll" or _clock - _roll_end <= tuning.rolling_kick_grace:
		_combo_step = 0
		return tuning.rolling_kick
	if previous_state != &"Attack" and _clock - _last_attack_end > tuning.combo_chain_window:
		_combo_step = 0
	var attack: AttackData = tuning.combo_attacks[_combo_step]
	_combo_step = (_combo_step + 1) % tuning.combo_attacks.size()
	return attack


## Note la fin d'un coup (pour savoir si l'enchaînement reste ouvert).
func end_attack() -> void:
	_last_attack_end = _clock


## Note la fin d'une roulade (pour le coup roulé).
func end_roll() -> void:
	_roll_end = _clock


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
## pendant `active_time` secondes (par défaut attack_active_time).
func strike(attack: AttackData, direction: Vector3, judgement: RhythmMath.Judgement, active_time: float = -1.0) -> void:
	_pending_groove = RhythmMath.groove_gain(judgement, tuning)
	var make_hit: Callable = _make_hit.bind(attack.damage_multiplier, attack.id, judgement, 0.0)
	var duration: float = active_time if active_time >= 0.0 else tuning.attack_active_time
	hitbox.activate(attack.reach, attack.arc_deg, direction, duration, make_hit)


## Onde à l'atterrissage d'un plongeon : touche tout autour dans `radius` mètres.
## `colors` : une onde par couleur, de plus en plus grande (une seule pour le plongeon normal).
func shockwave(radius: float, multiplier: float, move: StringName, judgement: RhythmMath.Judgement, stun_time: float, colors: Array[Color]) -> void:
	_pending_groove = RhythmMath.groove_gain(judgement, tuning)
	var make_hit: Callable = _make_hit.bind(multiplier, move, judgement, stun_time)
	hitbox.activate(radius, CombatMath.FULL_CIRCLE_DEG, facing_direction(), tuning.attack_active_time, make_hit)
	Feedback.shake(tuning.shake_trauma_dive, Vector3.ZERO)
	for orb: Node in get_tree().get_nodes_in_group(&"silence_orbs"):
		var at: Vector3 = (orb as Node3D).global_position
		if Vector2(at.x - global_position.x, at.z - global_position.z).length() < radius:
			orb.call(&"pop")
	if move == &"rainbow":
		get_tree().call_group(&"world_mood", &"burst")
		Feedback.vibrate(tuning.vibration_rainbow)
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
func on_enemy_freed(_muet: Node) -> void:
	groove.add(tuning.groove_enemy_freed * stats.groove)
	if stats.heal_per_muet > 0.0 and not health.is_depleted():
		health.heal(stats.heal_per_muet)


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


func _make_hit(hurtbox: Hurtbox, multiplier: float, move: StringName, judgement: RhythmMath.Judgement, stun_time: float) -> HitData:
	var hit := HitData.new()
	hit.attacker = self
	hit.target = hurtbox
	hit.move = move
	hit.judgement = judgement
	hit.stun_time = stun_time
	hit.critical = _next_hit_critical or rng.randf() < stats.crit_chance
	_next_hit_critical = false
	var attack: float = stats.attack
	var move_multiplier: float = multiplier * RhythmMath.damage_multiplier(judgement, tuning)
	hit.damage = CombatMath.damage(attack, move_multiplier, CombatMath.combo_multiplier(combo.hits, tuning), hit.critical, tuning)
	var to_target: Vector3 = hurtbox.global_position - global_position
	to_target.y = 0.0
	hit.direction = facing_direction() if to_target.is_zero_approx() else to_target.normalized()
	hit.point = hurtbox.center() - hit.direction * hurtbox.radius
	return hit


func _on_hit_landed(hit: HitData, _hurtbox: Hurtbox) -> void:
	combo.register_hit(_clock)
	last_hit = hit
	# Le groove d'un coup en rythme n'est gagné qu'une fois, au premier contact.
	var perfect: bool = hit.judgement == RhythmMath.Judgement.PERFECT
	if _pending_groove > 0.0:
		groove.add(_pending_groove * stats.groove * (stats.perfect_groove if perfect else 1.0))
		if perfect and stats.perfect_heal > 0.0:
			health.heal(stats.perfect_heal)
	_pending_groove = 0.0
	Feedback.hit_stop(tuning.hit_stop_perfect if perfect else tuning.hit_stop_hit)
	Feedback.vibrate(tuning.vibration_strong if perfect or hit.critical or hit.answer else tuning.vibration_hit)
	Feedback.shake(tuning.shake_trauma_hit, hit.direction)
	_hit_sound.pitch_scale = 1.0 + rng.randf_range(-tuning.hit_pitch_variation, tuning.hit_pitch_variation)
	_hit_sound.play()
	var fx: Effects = Effects.of(self)
	if fx:
		fx.spark(hit.point, tuning.fx_spark_size_crit if hit.critical else tuning.fx_spark_size, fx.gold if hit.critical else fx.white)
	hit_landed.emit(hit)


## Coup reçu : le combo est perdu, le héros est repoussé, clignote et devient intouchable un
## moment. À zéro point de vie, retour au point de départ.
func _on_hurt(hit: HitData) -> void:
	combo.reset()
	_hurt_invuln_left = tuning.hero_hurt_invuln
	Feedback.hit_stop(tuning.hit_stop_hero)
	Feedback.vibrate(tuning.vibration_hurt)
	Feedback.shake(tuning.shake_trauma_hurt, hit.direction)
	_hurt_sound.play()
	if health.is_depleted():
		_faint()
		return
	var recoil: float = tuning.hero_recoil_big_speed if hit.big else tuning.hero_recoil_speed
	set_horizontal_velocity(hit.direction * recoil)
	state_machine.transition_to(&"Hurt")


## Coup arrivé pendant une invulnérabilité : pendant une esquive, c'est une esquive parfaite
## (ralenti, prochain coup critique, groove). Après un coup reçu, rien de spécial.
func _on_dodged(_hit: HitData) -> void:
	if not invulnerable:
		return
	Feedback.slow_motion(tuning.perfect_dodge_slow_time, tuning.perfect_dodge_time_scale)
	var fx: Effects = Effects.of(self)
	if fx:
		fx.ring(global_position, tuning.fx_dodge_ring, fx.cyan, tuning.fx_dodge_ring_time)
		fx.word(GameTexts.WORD_PERFECT_DODGE, global_position + Vector3.UP * tuning.hero_height, fx.cyan, true)
	_next_hit_critical = true
	groove.add(tuning.groove_perfect_dodge * stats.groove)
	if stats.shadow:
		quake(tuning.shadow_quake_radius, tuning.shadow_quake_damage, &"shadow")
	beat_ring.flash(RhythmMath.Judgement.PERFECT)
	_dodge_sound.play()


## Retour immédiat d'un appui jugé : carillon (qui monte avec le combo) et éclat de l'anneau.
func _on_judged(judgement: RhythmMath.Judgement) -> void:
	judged.emit(judgement)
	beat_ring.flash(judgement)
	if judgement == RhythmMath.Judgement.MISS:
		return
	var notes: PackedFloat32Array = tuning.chime_scale_semitones
	var semitones: float = notes[mini(combo.hits, notes.size() - 1)]
	_chime.pitch_scale = pow(2.0, semitones / SEMITONES_PER_OCTAVE)
	_chime.volume_db = 0.0 if judgement == RhythmMath.Judgement.PERFECT else tuning.good_chime_volume_db
	_chime.play()


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


## Onde qui touche tous les Muets autour du héros (Final fracassant, Pas de l'Ombre) : rayon (m),
## dégâts en multiples de l'attaque.
func quake(radius: float, damage: float, move: StringName) -> void:
	var make_hit: Callable = _make_hit.bind(damage, move, RhythmMath.Judgement.MISS, 0.0)
	hitbox.activate(radius, CombatMath.FULL_CIRCLE_DEG, facing_direction(), tuning.attack_active_time, make_hit)
	var fx: Effects = Effects.of(self)
	if fx:
		fx.ring(global_position, radius, fx.violet, tuning.fx_quake_ring_time)
		fx.burst(global_position + Vector3.UP * tuning.fx_double_height, tuning.fx_quake_cubes, tuning.fx_quake_speed, tuning.fx_quake_hue)


func _judge_now() -> RhythmMath.Judgement:
	return Rhythm.judge_now(stats.perfect_window if stats else 1.0)


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
	stats = HeroStats.compute(Game.profile, tuning)
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
