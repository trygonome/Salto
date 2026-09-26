class_name VoxelNight
extends Node3D
## Une nuit dans le monde voxel du prototype. Génère le monde de la nuit (graine gardée d'une
## sortie à l'autre), pose le village, les trois sanctuaires et leurs tambours, les plumes
## arc-en-ciel des perchoirs. À l'écran titre, le village danse et le héros attend ; une sortie
## peuple la jungle (gardiens et Grand Muet de chaque sanctuaire dont le tambour n'est pas rentré,
## errants qui reviennent après leur libération), suit l'objectif (bannière, repère, flèche,
## colonne de lumière, chemin doré), fait parler les villageois, donne les conseils près des
## boutons et se termine par le résumé : nuit accomplie, héros évanoui ou rentré au village depuis
## la pause.

## Muets à faire apparaître, par espèce.
@export var hopper_scene: PackedScene
@export var flyer_scene: PackedScene
@export var shielder_scene: PackedScene
@export var charger_scene: PackedScene
@export var spitter_scene: PackedScene
@export var boss_scene: PackedScene
## Tambour d'un sanctuaire (dans sa bulle jusqu'à la libération du gardien).
@export var drum_scene: PackedScene
## Plume d'un perchoir, fruit.
@export var plume_scene: PackedScene
@export var fruit_scene: PackedScene
## Matériau des personnages voxel et de leurs ombres rondes.
@export var character_material: Material
@export var character_shadow_material: Material

## Espèces tirées au hasard pour garder les sanctuaires et errer, selon la nuit (comme dans le
## prototype) : de nouvelles espèces arrivent nuit après nuit.
const NIGHT_FOES: Array[Array] = [
	[&"hopper", &"hopper", &"hopper", &"flyer"],
	[&"hopper", &"hopper", &"flyer", &"shielder"],
	[&"hopper", &"hopper", &"flyer", &"shielder", &"charger"],
	[&"hopper", &"flyer", &"shielder", &"charger", &"spitter"],
]
## Le Roi Muet garde ce sanctuaire lors de la dernière nuit de la saga.
const KING_SANCTUARY := 2
## Conseils près des boutons, dans l'ordre où on les propose : identifiant et bouton.
const HINT_BUTTONS: Array[Array] = [
	[&"move", TouchControls.MOVE], [&"attack", &"attack"], [&"jump", &"jump"], [&"salto", &"jump"],
	[&"combo", &"attack"], [&"dodge", &"dodge"], [&"dive", &"attack"], [&"beat", &"attack"], [&"special", &"attack"],
]

var gen := WorldGen.new()
## Tambour de chaque sanctuaire, point d'apparition de son Grand Muet, de ses gardiens.
var drums: Array[Node3D] = []
var bosses: Array[EnemySpawner] = []
var guards: Array[Array] = []
## Sortie en cours (sinon : écran titre ou résumé).
var in_sortie: bool = false

var _rng := RandomNumberGenerator.new()
## Objectif gardé d'une image à l'autre ; à recalculer quand la nuit avance.
var _goal: Dictionary = {}
var _goal_dirty: bool = true
var _unit: float = 0.0
var _bark_left: float = 0.0
var _ending: bool = false
## Conseils : en cours, depuis quand (s), attente avant de revenir (s), temps de course, coups.
var _hint: StringName = &""
var _hint_time: float = 0.0
var _hint_cooldowns: Dictionary[StringName, float] = {}
var _moved_time: float = 0.0
var _attacks: int = 0

@onready var world: WorldBuilder = $World
@onready var mood: WorldMood = $Mood
@onready var hero: Hero = $Hero
@onready var foes: Node3D = $Foes
@onready var village: Node3D = $Village
@onready var pickups: Node3D = $Pickups
@onready var guide: ObjectiveGuide = $Guide
@onready var hud: Hud = $HUD
@onready var touch_controls: TouchControls = $TouchControls


func _enter_tree() -> void:
	# Avant les éléments du niveau : l'état de la nuit est prêt quand ils le lisent.
	Game.start_night(Game.profile.night)


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	add_to_group(&"night_level")
	_unit = tuning.voxel_unit
	_rng.randomize()
	gen.generate(Game.world_seed(), Game.profile.nights_done)
	world.build(gen)
	mood.set_sanctuaries(gen.sanctuaries, Game.progress.freed)
	_place_villagers()
	_add_shadow(hero, tuning.hero_shadow_radius)
	for i: int in gen.sanctuaries.size():
		_place_drum(i)
		guards.append([])
	_place_perches()
	Game.night_completed.connect(_on_night_completed)
	Game.drum_returned.connect(_on_drum_returned)
	Game.sanctuary_freed.connect(_on_sanctuary_freed)
	Game.level_up.connect(_on_level_up)
	# L'objectif change quand la nuit avance.
	Game.night_started.connect(func(_night: int) -> void: _goal_dirty = true)
	Game.sortie_started.connect(func() -> void: _goal_dirty = true)
	Game.drum_picked.connect(func() -> void: _goal_dirty = true)
	Game.drum_dropped.connect(func() -> void: _goal_dirty = true)
	Game.drum_returned.connect(func(_count: int) -> void: _goal_dirty = true)
	Game.sanctuary_freed.connect(func() -> void: _goal_dirty = true)
	Game.night_completed.connect(func() -> void: _goal_dirty = true)
	hero.fainted.connect(_on_hero_fainted)
	hero.action_pressed.connect(_on_action_pressed)
	Rhythm.play(Game.music_layers())
	if Game.start_on_load:
		Game.start_on_load = false
		start_sortie()
	else:
		_show_title()


func _exit_tree() -> void:
	Rhythm.stop()


func _process(delta: float) -> void:
	var goal: Dictionary = current_goal() if in_sortie else {}
	if goal.is_empty():
		mood.clear_target()
	else:
		mood.set_target(gen.sanctuaries[goal[&"index"]], goal[&"kind"] != &"return")
	guide.follow(hero, goal)
	if not in_sortie or _ending:
		return
	_update_barks(delta)
	_update_hints(delta)


## Lance une sortie : la jungle se peuple, le héros prend les commandes.
func start_sortie() -> void:
	Game.start_sortie()
	in_sortie = true
	_ending = false
	hero.begin_sortie()
	hero.reads_player_input = true
	hud.visible = true
	touch_controls.visible = true
	get_tree().call_group(&"title_screen", &"close")
	_spawn_foes()
	var info: Dictionary = GameTexts.night_info(Game.night)
	var goal: Dictionary = objective()
	# Grand titre du début de nuit ; à la première sortie de la nuit, ce que le Chef en dit.
	hud.show_banner(GameTexts.NIGHT_LABEL % Game.night, info[&"title"], info[&"line"] if Game.profile.sortie == 1 else "")
	(village.get_node(^"Chief") as Villager).greet()


## Hauteur des bulles du Chef (m au-dessus de ses pieds).
func tuning_chief_height() -> float:
	var tuning: TuningData = Tuning.data
	return tuning.chief_height + tuning.reply_gap


## Termine la sortie (&"night", &"faint" ou &"quit") et ouvre le résumé.
func end_sortie(kind: StringName) -> void:
	if not in_sortie:
		return
	in_sortie = false
	_ending = false
	_clear_hint()
	hero.reads_player_input = false
	hero.input_move = Vector2.ZERO
	var summary: Dictionary = Game.end_sortie(kind)
	hud.visible = false
	touch_controls.visible = false
	get_tree().paused = true
	get_tree().call_group(&"summary_screen", &"open", summary)


## Relance la scène : une nouvelle sortie tout de suite (`play`), ou l'écran titre.
func restart(play: bool) -> void:
	Game.start_on_load = play
	get_tree().paused = false
	get_tree().reload_current_scene()


## Objectif du moment, recalculé seulement quand la nuit avance (voir objective()).
func current_goal() -> Dictionary:
	if _goal_dirty:
		_goal_dirty = false
		_goal = objective()
	return _goal


## Objectif du moment, comme dans le prototype : rapporter les tambours portés, sinon aller
## prendre un tambour libéré, sinon libérer le prochain sanctuaire. Dictionnaire vide quand la nuit
## est accomplie ; sinon : kind (&"return", &"pick", &"free"), index (sanctuaire du chemin doré),
## point (m), title, sub, icon (&"home", &"drum", &"crown").
func objective() -> Dictionary:
	var progress: NightProgress = Game.progress
	if progress.is_complete():
		return {}
	if progress.carrying_drum:
		return {
			&"kind": &"return", &"index": progress.carrying[0], &"point": to_world(WorldGen.CHIEF),
			&"title": GameTexts.QUEST_RETURN, &"sub": GameTexts.QUEST_RETURN_SUB, &"icon": &"home",
		}
	for i: int in gen.sanctuaries.size():
		if progress.freed[i] and not progress.picked[i]:
			return {
				&"kind": &"pick", &"index": i, &"point": to_world(gen.sanctuaries[i]),
				&"title": GameTexts.QUEST_PICK % gen.sanctuary_names[i], &"sub": GameTexts.QUEST_PICK_SUB, &"icon": &"drum",
			}
	for i: int in gen.sanctuaries.size():
		if not progress.freed[i]:
			return {
				&"kind": &"free", &"index": i, &"point": to_world(gen.sanctuaries[i]),
				&"title": GameTexts.QUEST_FREE % gen.sanctuary_names[i],
				&"sub": GameTexts.QUEST_FREE_KING_SUB if is_king(i) else GameTexts.QUEST_FREE_SUB, &"icon": &"crown",
			}
	return {}


## Vrai si le Roi Muet garde le sanctuaire `index` cette nuit.
func is_king(index: int) -> bool:
	return Game.night == Tuning.data.saga_nights and index == KING_SANCTUARY


## Point du monde en mètres pour un point du prototype (u).
func to_world(p: Vector2) -> Vector3:
	return Vector3(p.x * _unit, 0.0, p.y * _unit)


## Renforts d'un Grand Muet (à partir de la nuit boss_summon_night, et toujours pour le Roi) :
## s'il lui reste trop peu de gardiens, d'autres Muets arrivent à ses côtés.
func summon_guards(boss: Muet) -> void:
	var tuning: TuningData = Tuning.data
	var index: int = -1
	for i: int in bosses.size():
		if is_instance_valid(bosses[i]) and bosses[i].muet == boss:
			index = i
	if index < 0 or not in_sortie:
		return
	var alive: int = 0
	for spawner: EnemySpawner in guards[index]:
		if is_instance_valid(spawner.muet) and not spawner.muet.is_freed():
			alive += 1
	if alive >= tuning.boss_summon_min_guards:
		return
	var center := Vector2(boss.global_position.x, boss.global_position.z) / _unit
	for k: int in tuning.boss_summon_count:
		var angle: float = _rng.randf() * TAU
		var p: Vector2 = center + Vector2(cos(angle), sin(angle)) * tuning.boss_summon_distance / _unit
		guards[index].append(_spawner(_foe_scene(), p, false, index))
	var fx: Effects = Effects.of(self)
	if fx:
		fx.ring(boss.global_position, tuning.boss_summon_distance, fx.violet, tuning.fx_quake_ring_time)


func _show_title() -> void:
	in_sortie = false
	hero.reads_player_input = false
	hud.visible = false
	touch_controls.visible = false
	get_tree().call_group(&"title_screen", &"open")


## Les six danseurs autour de la place, tournés vers le centre, et le Chef Taroum devant les tambours.
func _place_villagers() -> void:
	var tuning: TuningData = Tuning.data
	for i: int in WorldGen.DANCERS.size():
		var p: Vector2 = WorldGen.DANCERS[i]
		var dancer := Villager.new()
		dancer.name = "Dancer%d" % (i + 1)
		dancer.position = to_world(p)
		village.add_child(dancer)
		dancer.setup(VoxelStyles.dancer(i), "dancer%d" % i, 1.0, atan2(-p.x, -p.y), i * tuning.villager_phase_step,
			tuning.villager_first_flip + i * tuning.villager_first_flip_step, character_material, character_shadow_material, tuning.villager_shadow_radius)
	var chief := Villager.new()
	chief.name = "Chief"
	chief.is_chief = true
	chief.position = to_world(WorldGen.CHIEF)
	village.add_child(chief)
	chief.setup(VoxelStyles.chief(), "chief", tuning.chief_scale, 0.0, tuning.chief_phase, INF, character_material, character_shadow_material, tuning.chief_shadow_radius)


func _add_shadow(target: Node3D, radius: float) -> void:
	var shadow := BlobShadow.new()
	shadow.name = "Shadow"
	shadow.radius = radius
	shadow.material = character_shadow_material
	target.add_child(shadow)


## Tambour d'un sanctuaire sur son autel (absent s'il est déjà au village).
func _place_drum(index: int) -> void:
	var drum: Node3D = drum_scene.instantiate() as Node3D
	drum.name = "Drum%d" % (index + 1)
	drum.set(&"sanctuary", index)
	drum.position = to_world(gen.sanctuaries[index]) + Vector3.UP * WorldGen.ALTAR_HEIGHT * _unit
	add_child(drum)
	drums.append(drum)


## Une plume arc-en-ciel au sommet de chaque perchoir.
func _place_perches() -> void:
	for i: int in gen.pickups.size():
		var plume: PlumePickup = plume_scene.instantiate() as PlumePickup
		var p: Vector3 = gen.pickups[i]
		plume.position = Vector3(p.x, p.y, p.z) * _unit
		pickups.add_child(plume)


## Gardiens et Grand Muet de chaque sanctuaire dont le tambour n'est pas au village, et errants.
func _spawn_foes() -> void:
	var tuning: TuningData = Tuning.data
	for i: int in gen.sanctuaries.size():
		if Game.progress.banked_at_start[i]:
			continue
		var s: Vector2 = gen.sanctuaries[i]
		var count: int = tuning.sanctuary_guards + i + (1 if Game.night >= tuning.extra_guard_night else 0)
		var placed: int = 0
		var tries: int = 0
		while placed < count and tries < tuning.spawn_tries:
			tries += 1
			var a: float = float(placed) / count * TAU + _rng.randf() * tuning.spawn_angle_jitter
			var r: float = _rng.randf_range(tuning.sanctuary_guard_min, tuning.sanctuary_guard_max) / _unit
			var p: Vector2 = s + Vector2(cos(a), sin(a)) * r
			if _blocked(p, tuning.spawn_clearance / _unit):
				continue
			guards[i].append(_spawner(_foe_scene(), p, false, i))
			placed += 1
		var boss: EnemySpawner = _spawner(boss_scene, s - s.normalized() * tuning.sanctuary_boss_distance / _unit, false, i)
		boss.king = is_king(i)
		boss.display_name = GameTexts.KING_NAME if boss.king else GameTexts.BOSS_NAME % gen.sanctuary_names[i]
		boss.muet_freed.connect(_on_boss_freed.bind(i))
		bosses.append(boss)
	var wanderers: int = tuning.muet_wanderers + mini(tuning.muet_wanderers_extra_max, (Game.night - 1) * tuning.muet_wanderers_per_night)
	for i: int in wanderers:
		_spawn_wanderer()


func _spawn_wanderer() -> void:
	var tuning: TuningData = Tuning.data
	for t: int in tuning.spawn_tries:
		var a: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(tuning.wanderer_min_distance, tuning.wanderer_max_distance) / _unit
		var p := Vector2(cos(a), sin(a)) * r
		var from := Vector2(hero.global_position.x, hero.global_position.z) / _unit
		if gen.near_sanctuary(p, tuning.wanderer_sanctuary_clearance / _unit) or p.distance_to(from) < tuning.wanderer_hero_clearance / _unit:
			continue
		if _blocked(p, tuning.spawn_clearance / _unit):
			continue
		var spawner: EnemySpawner = _spawner(_foe_scene(), p, true, mini(Game.progress.drums_returned, gen.sanctuaries.size() - 1))
		spawner.muet_freed.connect(func(_muet: Muet) -> void: _respawn_wanderer_later(), CONNECT_ONE_SHOT)
		return


## Un errant libéré est remplacé un peu plus tard, si la sortie dure encore.
func _respawn_wanderer_later() -> void:
	get_tree().create_timer(Tuning.data.wanderer_respawn_time, false).timeout.connect(func() -> void:
		if in_sortie and not _ending:
			_spawn_wanderer())


func _foe_scene() -> PackedScene:
	var list: Array = NIGHT_FOES[clampi(Game.night - 1, 0, NIGHT_FOES.size() - 1)]
	var species: StringName = list[_rng.randi_range(0, list.size() - 1)]
	match species:
		&"flyer":
			return flyer_scene
		&"shielder":
			return shielder_scene
		&"charger":
			return charger_scene
		&"spitter":
			return spitter_scene
	return hopper_scene


func _spawner(scene: PackedScene, p: Vector2, wanderer: bool, tier: int) -> EnemySpawner:
	var spawner := EnemySpawner.new()
	spawner.scene = scene
	spawner.position = to_world(p)
	spawner.wanderer = wanderer
	spawner.tier = tier
	spawner.safe_zone_radius = Tuning.data.village_radius
	foes.add_child(spawner)
	spawner.muet_freed.connect(_on_muet_freed)
	return spawner


func _blocked(p: Vector2, margin: float) -> bool:
	for s: WorldGen.Solid in gen.solids:
		if Vector2(p.x - s.x, p.y - s.z).length() < s.r + margin:
			return true
	return false


## Un Muet libéré laisse parfois un fruit (le Grand Muet : toujours).
func _on_muet_freed(muet: Muet) -> void:
	if muet.is_boss():
		return
	if _rng.randf() < Tuning.data.fruit_chance:
		_drop(fruit_scene, muet.global_position)


## Un Grand Muet libéré laisse un fruit, et son cadeau part avec le tambour qu'il libère.
func _on_boss_freed(muet: Muet, index: int) -> void:
	_drop(fruit_scene, muet.global_position)
	if not Game.progress.freed[index]:
		Game.give_gift(index, muet.king)
		(drums[index].call(&"release"))


func _drop(scene: PackedScene, at: Vector3) -> Node3D:
	var node: Node3D = scene.instantiate() as Node3D
	node.position = Vector3(at.x, 0.0, at.z)
	pickups.add_child(node)
	return node


func _on_sanctuary_freed() -> void:
	for i: int in Game.progress.freed.size():
		if Game.progress.freed[i]:
			mood.free_sanctuary(i)


## Tambours rapportés : le Chef s'en réjouit (la jungle reprend ses couleurs).
func _on_drum_returned(count: int) -> void:
	var chief: Villager = village.get_node(^"Chief") as Villager
	chief.greet()
	hud.show_bubble(GameTexts.RETURN_LINES[clampi(count - 1, 0, GameTexts.RETURN_LINES.size() - 1)], chief, tuning_chief_height())


## Le héros grandit (au village, ou en fin de sortie) : le Chef le salue.
func _on_level_up(level: int) -> void:
	if not in_sortie or _ending:
		return
	var chief: Villager = village.get_node(^"Chief") as Villager
	chief.greet()
	hud.show_bubble(GameTexts.LEVEL_UP_LINES[level % GameTexts.LEVEL_UP_LINES.size()], chief, tuning_chief_height())


## Nuit accomplie : le monde éclate de couleurs, une gerbe et un anneau arc-en-ciel au village,
## puis le résumé.
func _on_night_completed() -> void:
	var tuning: TuningData = Tuning.data
	mood.set_won(true)
	_ending = true
	hud.show_banner(GameTexts.BANNER_NIGHT_DONE, GameTexts.BANNER_NIGHT_DONE_TITLE, "")
	var fx: Effects = Effects.of(self)
	if fx:
		var center: Vector3 = to_world(WorldGen.CHIEF)
		fx.burst(center + Vector3.UP * tuning.fx_night_height, tuning.fx_night_cubes, tuning.fx_night_speed)
		fx.ring(center, tuning.fx_night_ring, fx.white, tuning.fx_night_ring_time, true)
	get_tree().create_timer(tuning.night_summary_delay, false).timeout.connect(end_sortie.bind(&"night"))


## Le héros s'évanouit : un instant, puis le résumé.
func _on_hero_fainted() -> void:
	if not in_sortie or _ending:
		return
	_ending = true
	_clear_hint()
	hud.show_toast(GameTexts.TOAST_FAINT)
	get_tree().create_timer(Tuning.data.faint_summary_delay, false).timeout.connect(end_sortie.bind(&"faint"))


## Les villageois parlent au héros qui passe près d'eux (un de temps en temps).
func _update_barks(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_bark_left -= delta
	if _bark_left > 0.0:
		return
	for node: Node in village.get_children():
		var villager: Villager = node as Villager
		if villager == null or villager.global_position.distance_to(hero.global_position) > tuning.bark_distance:
			continue
		var text: String
		if villager.is_chief:
			text = _pick(GameTexts.CHIEF_TIPS)
		else:
			var mood_index: int = GameTexts.BARKS.size() - 1 if Game.progress.is_complete() else mini(Game.progress.drums_returned, GameTexts.BARKS.size() - 2)
			text = _pick(GameTexts.BARKS[mood_index])
		hud.show_bubble(text, villager, (tuning_chief_height() if villager.is_chief else tuning.villager_bubble_height))
		_bark_left = tuning.bark_cooldown
		return


## Conseils du prototype : le premier qui s'applique, s'il n'est pas encore appris ; il s'en va
## une fois fait, au bout d'un moment, ou quand il ne s'applique plus.
func _update_hints(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	for id: StringName in _hint_cooldowns.keys():
		_hint_cooldowns[id] -= delta
	if hero.input_move.length() > 0.0:
		_moved_time += delta
		if _moved_time > tuning.hint_move_time:
			_learn(&"move")
	if hero.combo.hits >= tuning.hint_combo_hits:
		_learn(&"combo")
	if _hint != &"":
		_hint_time += delta
		if Game.profile.is_hint_done(_hint) or _hint_time > tuning.hint_show_time or not _hint_applies(_hint):
			_clear_hint()
		return
	for entry: Array in HINT_BUTTONS:
		var id: StringName = entry[0]
		if Game.profile.is_hint_done(id) or _hint_cooldowns.get(id, 0.0) > 0.0:
			continue
		if id != &"move" and not Game.profile.is_hint_done(&"move"):
			return
		if _hint_applies(id):
			_hint = id
			_hint_time = 0.0
			hud.show_coach(GameTexts.HINTS[id], entry[1])
			return


func _hint_applies(id: StringName) -> bool:
	var tuning: TuningData = Tuning.data
	var airborne: bool = not hero.is_on_floor()
	match id:
		&"move":
			return true
		&"attack":
			return _muet_near(tuning.hint_near_distance)
		&"jump":
			return _log_near() or Game.progress.elapsed > tuning.hint_jump_time
		&"salto":
			return airborne and hero.velocity.y > 0.0 and Game.profile.is_hint_done(&"jump")
		&"combo":
			return _attacks >= tuning.hint_combo_after and _muet_near(tuning.hint_near_distance)
		&"dodge":
			return _danger_near()
		&"dive":
			return airborne and _muet_near(tuning.hint_near_distance) and Game.profile.is_hint_done(&"jump")
		&"beat":
			return _attacks >= tuning.hint_beat_after
		&"special":
			return hero.groove.is_full()
	return false


func _on_action_pressed(action: StringName) -> void:
	if not in_sortie:
		return
	var airborne: bool = not hero.is_on_floor()
	match action:
		&"attack":
			_attacks += 1
			_learn(&"attack")
			if airborne:
				_learn(&"dive")
				if hero.groove.is_full():
					_learn(&"special")
			if Rhythm.judge_now(hero.stats.perfect_window) == RhythmMath.Judgement.PERFECT:
				_learn(&"beat")
		&"jump":
			if airborne:
				_learn(&"salto")
			_learn(&"jump")
		&"dodge":
			_learn(&"dodge")


func _learn(id: StringName) -> void:
	if Game.profile.is_hint_done(id):
		return
	Game.mark_hint_done(id)
	if _hint == id:
		_clear_hint()


func _clear_hint() -> void:
	if _hint == &"":
		return
	_hint_cooldowns[_hint] = Tuning.data.hint_cooldown
	_hint = &""
	hud.hide_coach()


func _muet_near(distance: float) -> bool:
	for node: Node in get_tree().get_nodes_in_group(&"muets"):
		var muet: Muet = node as Muet
		if not muet.is_freed() and muet.global_position.distance_to(hero.global_position) < distance:
			return true
	return false


func _danger_near() -> bool:
	var tuning: TuningData = Tuning.data
	for node: Node in get_tree().get_nodes_in_group(&"muets"):
		var muet: Muet = node as Muet
		if muet.is_threatening() and not muet.is_freed() and muet.global_position.distance_to(hero.global_position) < tuning.hint_danger_distance:
			return true
	for node: Node in get_tree().get_nodes_in_group(&"silence_orbs"):
		if (node as Node3D).global_position.distance_to(hero.global_position) < tuning.hint_orb_distance:
			return true
	return false


## Un tronc couché tout près : de quoi sauter.
func _log_near() -> bool:
	var from := Vector2(hero.global_position.x, hero.global_position.z) / _unit
	var reach: float = Tuning.data.hint_log_distance / _unit
	for s: WorldGen.Solid in gen.solids:
		if is_equal_approx(s.h, WorldGen.LOG_HEIGHT) and Vector2(s.x - from.x, s.z - from.y).length() < reach:
			return true
	return false


## Un texte au hasard dans `list` (tableau de textes).
func _pick(list: Variant) -> String:
	return list[_rng.randi_range(0, list.size() - 1)]
