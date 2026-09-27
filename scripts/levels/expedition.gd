class_name Expedition
extends Level
## Une expédition, façon action-RPG : une suite de clairières générées (graine de l'expédition),
## chacune promet une récompense (don des esprits, soin, plumes d'or) et lâche ses Muets par
## vagues ; nettoyée, elle donne sa récompense et ouvre ses passages, chacun annonçant la sienne.
## La dernière clairière est gardée par un Grand Muet : le libérer termine l'expédition. Tomber
## (ou rentrer depuis la pause) aussi ; on garde l'expérience et les plumes d'or rapportées.
## Avant de partir, l'écran titre s'affiche sur une clairière de camp.

## Muets à faire apparaître, par espèce, et le Grand Muet ; passage de sortie.
@export var hopper_scene: PackedScene
@export var flyer_scene: PackedScene
@export var shielder_scene: PackedScene
@export var charger_scene: PackedScene
@export var spitter_scene: PackedScene
@export var boss_scene: PackedScene
@export var gate_scene: PackedScene

## Espèces de chaque clairière, de la première à l'avant-dernière (au-delà : la dernière liste).
const ROOM_FOES: Array = [
	[&"hopper"],
	[&"hopper", &"flyer"],
	[&"hopper", &"flyer", &"charger"],
	[&"hopper", &"shielder", &"flyer"],
	[&"hopper", &"charger", &"spitter", &"flyer"],
	[&"hopper", &"flyer", &"shielder", &"charger", &"spitter"],
]
## Gardiens du Grand Muet.
const BOSS_GUARDS: Array[StringName] = [&"hopper", &"flyer"]
## Angle de l'entrée (sud) et écart entre deux passages de sortie (rad, autour du nord).
const ENTRANCE := PI
const EXIT_SPREAD := 0.55
## Les sanctuaires de l'ambiance sont repoussés à tant de rayons de clairière (hors de vue).
const NO_SANCTUARY := 100.0

var gen := WorldGen.new()
## Graine de la prochaine expédition (tirée au hasard).
var next_seed: int = 0

var _rng := RandomNumberGenerator.new()
var _unit: float = 0.0
var _wave: int = 0
var _remaining: int = 0
var _cleared: bool = false
var _ending: bool = false
var _exit_angles := PackedFloat32Array()
var _fade: ColorRect
var _boss: Muet

@onready var world: WorldBuilder = $World
@onready var mood: WorldMood = $Mood
@onready var hero: Hero = $Hero
@onready var foes: Node3D = $Foes
@onready var pickups: Node3D = $Pickups
@onready var hud: Hud = $HUD
@onready var touch_controls: TouchControls = $TouchControls
@onready var camera_rig: Node3D = $CameraRig
@onready var boon_screen: BoonScreen = $BoonScreen


func _enter_tree() -> void:
	Game.start_night(Game.profile.night)


func _ready() -> void:
	add_to_group(&"night_level")
	_unit = Tuning.data.voxel_unit
	_rng.randomize()
	next_seed = _rng.randi_range(1, 0x7FFFFFFF)
	# Pas de sanctuaire muet dans les clairières : aucune zone de silence.
	var far := Vector2.ONE * Tuning.data.room_radius * NO_SANCTUARY
	mood.set_sanctuaries(PackedVector2Array([far, far, far]), [true, true, true] as Array[bool])
	mood.set_progress(0.0, false)
	mood.clear_target()
	_add_fade()
	hero.fainted.connect(_on_hero_fainted)
	boon_screen.chosen.connect(_on_boon_chosen)
	Rhythm.play(1)
	Rhythm.set_band(0.0)
	_build_camp()
	if Game.start_on_load:
		Game.start_on_load = false
		start_sortie()
	else:
		_show_title()


func _exit_tree() -> void:
	Rhythm.stop()


func is_expedition() -> bool:
	return true


func shows_drums() -> bool:
	return false


## Objectif du moment : se battre (et ce que la clairière promet), choisir un passage, le Grand
## Muet.
func current_goal() -> Dictionary:
	var run: RunState = Game.run
	if run == null or not in_sortie:
		return {}
	var tuning: TuningData = Tuning.data
	if _cleared:
		var goal: Dictionary = {&"title": GameTexts.ROOM_TITLE % [run.room + 1, run.room_count], &"sub": GameTexts.ROOM_CHOOSE, &"icon": &"won"}
		if not _exit_angles.is_empty():
			# Le repère montre le milieu des passages.
			var p: Vector2 = WorldGen.gap_point(0.0, tuning.room_radius) * _unit
			goal[&"point"] = Vector3(p.x, 0.0, p.y)
		return goal
	if run.is_boss_room():
		return {&"title": GameTexts.ROOM_BOSS_TITLE, &"sub": GameTexts.ROOM_BOSS_SUB, &"icon": &"crown"}
	return {
		&"title": GameTexts.ROOM_TITLE % [run.room + 1, run.room_count],
		&"sub": GameTexts.ROOM_FIGHT % GameTexts.REWARD_NAMES[run.reward], &"icon": run.reward,
	}


## Part en expédition depuis l'écran titre (ou Repartir).
func start_sortie() -> void:
	var tuning: TuningData = Tuning.data
	Game.start_run(next_seed, tuning.run_rooms)
	in_sortie = true
	_ending = false
	hero.begin_sortie()
	hero.reads_player_input = true
	hud.visible = true
	touch_controls.visible = true
	get_tree().call_group(&"title_screen", &"close")
	_enter_room()


## Termine l'expédition (&"won", &"faint" ou &"quit") et ouvre le résumé.
func end_sortie(kind: StringName) -> void:
	if not in_sortie:
		return
	in_sortie = false
	_ending = false
	hero.reads_player_input = false
	hero.input_move = Vector2.ZERO
	var s: Dictionary = Game.end_run(kind)
	hud.visible = false
	touch_controls.visible = false
	get_tree().paused = true
	get_tree().call_group(&"summary_screen", &"open", summary_of(s))


## Relance la scène : une nouvelle expédition tout de suite (`play`), ou l'écran titre.
func restart(play: bool) -> void:
	Game.start_on_load = play
	get_tree().paused = false
	get_tree().reload_current_scene()


## Résumé affiché pour l'expédition terminée `s` (voir Game.end_run).
static func summary_of(s: Dictionary) -> Dictionary:
	var kind: StringName = s[&"kind"]
	var brought: String = GameTexts.feathers(s[&"feathers"])
	var sub: String = GameTexts.RUN_WON_SUB % brought if kind == &"won" else (GameTexts.RUN_LOST_SUB if kind == &"faint" else GameTexts.RUN_QUIT_SUB) % [s[&"room"], brought]
	return {
		&"title": GameTexts.RUN_WON if kind == &"won" else (GameTexts.RUN_LOST if kind == &"faint" else GameTexts.RUN_QUIT),
		&"sub": sub,
		&"rows": [
			[GameTexts.RUN_ROOMS, "%d / %d" % [s[&"room"], s[&"rooms"]]],
			[GameTexts.SUMMARY_MUETS, str(s[&"muets"])],
			[GameTexts.RUN_BOONS, str(s[&"boons"])],
			[GameTexts.SUMMARY_LEVEL, str(s[&"level"])],
			[GameTexts.SUMMARY_TIME, GameTexts.duration(s[&"time"])],
		],
		&"again": GameTexts.RUN_AGAIN,
	}


## Renforts d'un Grand Muet : s'il lui reste trop peu de gardiens, d'autres arrivent à ses côtés.
func summon_guards(boss: Muet) -> void:
	var tuning: TuningData = Tuning.data
	if not in_sortie or _ending:
		return
	var alive: int = 0
	for node: Node in get_tree().get_nodes_in_group(&"muets"):
		if node != boss and not (node as Muet).is_freed():
			alive += 1
	if alive >= tuning.boss_summon_min_guards:
		return
	var center := Vector2(boss.global_position.x, boss.global_position.z) / _unit
	for k: int in tuning.boss_summon_count:
		var angle: float = _rng.randf() * TAU
		_spawn(_scene_of(BOSS_GUARDS[k % BOSS_GUARDS.size()]), center + Vector2(cos(angle), sin(angle)) * tuning.boss_summon_distance / _unit)


func _show_title() -> void:
	in_sortie = false
	hero.reads_player_input = false
	hud.visible = false
	touch_controls.visible = false
	get_tree().call_group(&"title_screen", &"open")


## Clairière du camp (écran titre) : une clairière calme, sans Muets.
func _build_camp() -> void:
	gen.generate_room(next_seed, Tuning.data.room_radius, PackedFloat32Array([0.0]))
	world.build(gen)
	_place_hero()


func _enter_room() -> void:
	var tuning: TuningData = Tuning.data
	var run: RunState = Game.run
	_cleared = false
	_wave = 0
	_remaining = 0
	_boss = null
	for node: Node in foes.get_children() + pickups.get_children():
		node.queue_free()
	var exits: int = run.exit_count(tuning.room_exits)
	_exit_angles = PackedFloat32Array()
	for i: int in exits:
		_exit_angles.append((i - (exits - 1) / 2.0) * EXIT_SPREAD)
	var gaps: PackedFloat32Array = _exit_angles.duplicate()
	gaps.append(ENTRANCE)
	gen.generate_room(run.room_seed(), tuning.room_radius, gaps)
	world.build(gen)
	mood.set_progress(float(run.room) / maxf(1.0, run.room_count - 1), false)
	Rhythm.set_layers(mini(1 + floori(float(run.room) * Rhythm.NIGHT_LAYERS.size() / run.room_count), Rhythm.NIGHT_LAYERS.size()))
	_place_hero()
	if run.is_boss_room():
		hud.show_banner(GameTexts.ROOM_TITLE % [run.room + 1, run.room_count], GameTexts.ROOM_BOSS_TITLE, "")
	get_tree().create_timer(tuning.room_wave_delay, false).timeout.connect(_start_wave)


## Le héros arrive par l'entrée (au sud), face à la clairière.
func _place_hero() -> void:
	var tuning: TuningData = Tuning.data
	var start: Vector2 = WorldGen.gap_point(ENTRANCE, tuning.room_radius - tuning.room_entry_inset / _unit)
	hero.global_position = Vector3(start.x, 0.0, start.y) * _unit
	hero.velocity = Vector3.ZERO
	hero.face_now(Vector3.FORWARD)
	hero.reset_physics_interpolation()
	camera_rig.call(&"snap")


func _start_wave() -> void:
	if not in_sortie or _ending:
		return
	var tuning: TuningData = Tuning.data
	var run: RunState = Game.run
	if run.is_boss_room() and _wave == 0:
		var spawner: EnemySpawner = _spawn(boss_scene, Vector2(0.0, -tuning.room_radius * tuning.room_boss_depth))
		spawner.display_name = GameTexts.ROOM_BOSS_TITLE
		spawner.muet_freed.connect(func(muet: Muet) -> void: _on_boss_freed(muet), CONNECT_ONE_SHOT)
		for i: int in tuning.boss_room_guards:
			_spawn(_scene_of(BOSS_GUARDS[i % BOSS_GUARDS.size()]), _spawn_point())
		_wave += 1
		return
	var list: Array = ROOM_FOES[mini(run.room, ROOM_FOES.size() - 1)]
	var count: int = tuning.room_wave_base + roundi(tuning.room_wave_per_room * run.room)
	for i: int in count:
		_spawn(_scene_of(list[_rng.randi_range(0, list.size() - 1)]), _spawn_point())
	_wave += 1


## Point d'apparition d'un Muet (u) : dans la clairière, loin du héros et du décor.
func _spawn_point() -> Vector2:
	var tuning: TuningData = Tuning.data
	var from := Vector2(hero.global_position.x, hero.global_position.z) / _unit
	var best := Vector2.ZERO
	for t: int in tuning.spawn_tries:
		var a: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(tuning.room_spawn_min, tuning.room_spawn_max) * tuning.room_radius
		var p := Vector2(sin(a), -cos(a)) * r
		if p.distance_to(from) < tuning.room_spawn_hero_clearance / _unit or _blocked(p, tuning.spawn_clearance / _unit):
			continue
		return p
	return best


func _spawn(scene: PackedScene, p: Vector2) -> EnemySpawner:
	var tuning: TuningData = Tuning.data
	var spawner := EnemySpawner.new()
	spawner.scene = scene
	spawner.position = Vector3(p.x, 0.0, p.y) * _unit
	spawner.wanderer = true
	spawner.hunter = true
	spawner.tier = floori(Game.run.room * tuning.room_tier_per_room) if Game.run else 0
	foes.add_child(spawner)
	spawner.muet_freed.connect(_on_muet_freed)
	_remaining += 1
	var fx: Effects = Effects.of(self)
	if fx:
		fx.ring(spawner.position, tuning.fx_spawn_ring, fx.violet, tuning.fx_spawn_ring_time)
	return spawner


func _scene_of(species: StringName) -> PackedScene:
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


func _blocked(p: Vector2, margin: float) -> bool:
	for s: WorldGen.Solid in gen.solids:
		if Vector2(p.x - s.x, p.y - s.z).length() < s.r + margin:
			return true
	return false


func _on_muet_freed(muet: Muet) -> void:
	if Game.run:
		Game.run.muets_freed += 1
	_remaining -= 1
	if _remaining > 0 or _ending or not in_sortie or muet.is_boss():
		return
	var tuning: TuningData = Tuning.data
	if not Game.run.is_boss_room() and _wave < tuning.room_waves:
		get_tree().create_timer(tuning.room_wave_delay, false).timeout.connect(_start_wave)
		return
	if not Game.run.is_boss_room():
		_room_cleared()


## Clairière nettoyée : sa récompense, puis ses passages.
func _room_cleared() -> void:
	var tuning: TuningData = Tuning.data
	var run: RunState = Game.run
	_cleared = true
	var fx: Effects = Effects.of(self)
	match run.reward:
		RunState.BOON:
			boon_screen.open(Boons.offer(run.rng, run.boons, tuning.boon_offer, tuning))
			return
		RunState.HEAL:
			var amount: float = hero.health.maximum * tuning.room_heal
			hero.health.heal(amount)
			hud.show_toast(GameTexts.HEALED % roundi(amount))
			if fx:
				fx.burst(hero.global_position + Vector3.UP * tuning.hero_height, tuning.fx_plume_cubes, tuning.fx_plume_speed, tuning.fx_heal_hue)
		RunState.FEATHERS:
			var gained: int = tuning.room_feathers_base + tuning.room_feathers_per_room * run.room
			run.feathers += gained
			hud.show_toast(GameTexts.FEATHERS_FOUND % gained)
			if fx:
				fx.burst(hero.global_position + Vector3.UP * tuning.hero_height, tuning.fx_plume_cubes, tuning.fx_plume_speed, tuning.fx_gold_hue)
	_open_exits()


func _on_boon_chosen(id: StringName) -> void:
	Game.take_boon(id)
	var fx: Effects = Effects.of(self)
	if fx:
		fx.burst(hero.global_position + Vector3.UP * Tuning.data.hero_height, Tuning.data.fx_plume_cubes, Tuning.data.fx_plume_speed)
	_open_exits()


## Les passages surgissent au nord, chacun avec la récompense qu'il promet.
func _open_exits() -> void:
	var tuning: TuningData = Tuning.data
	var rewards: Array[StringName] = Game.run.exit_rewards(_exit_angles.size())
	for i: int in mini(rewards.size(), _exit_angles.size()):
		var gate: ExitGate = gate_scene.instantiate() as ExitGate
		gate.reward = rewards[i]
		var p: Vector2 = WorldGen.gap_point(_exit_angles[i], tuning.room_radius - tuning.room_exit_inset / _unit)
		gate.position = Vector3(p.x, 0.0, p.y) * _unit
		var inward: Vector2 = -p.normalized()
		gate.rotation.y = atan2(inward.x, inward.y)
		pickups.add_child(gate)
		gate.chosen.connect(_on_gate_chosen)


func _on_gate_chosen(reward: StringName) -> void:
	if not in_sortie or _ending:
		return
	var tuning: TuningData = Tuning.data
	hero.reads_player_input = false
	hero.input_move = Vector2.ZERO
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, tuning.room_fade_time)
	tween.tween_callback(func() -> void:
		Game.run.enter_next(reward)
		_enter_room()
		hero.reads_player_input = true)
	tween.tween_property(_fade, "color:a", 0.0, tuning.room_fade_time)


## Le Grand Muet libéré : la jungle éclate de couleurs, l'expédition est gagnée.
func _on_boss_freed(_muet: Muet) -> void:
	var tuning: TuningData = Tuning.data
	_ending = true
	mood.set_progress(1.0, false)
	get_tree().call_group(&"world_mood", &"burst")
	hud.show_banner(GameTexts.ROOM_BOSS_TITLE, GameTexts.RUN_WON, "")
	get_tree().create_timer(tuning.night_summary_delay, false).timeout.connect(end_sortie.bind(&"won"))


func _on_hero_fainted() -> void:
	if not in_sortie or _ending:
		return
	_ending = true
	hud.show_toast(GameTexts.TOAST_FAINT)
	get_tree().create_timer(Tuning.data.faint_summary_delay, false).timeout.connect(end_sortie.bind(&"faint"))


## Voile noir des passages d'une clairière à l'autre.
func _add_fade() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Fade"
	layer.layer = Tuning.data.room_fade_layer
	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
	add_child(layer)
