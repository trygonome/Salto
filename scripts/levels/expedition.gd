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
@export var weaver_scene: PackedScene
@export var totem_scene: PackedScene
@export var dancer_scene: PackedScene
@export var brute_scene: PackedScene
@export var boss_scene: PackedScene
@export var gate_scene: PackedScene
## Plume arc-en-ciel des perchoirs ; personnages des rencontres (matériaux des villageois et des
## Muets, de leurs ombres, des petits assemblages) ; pages du carnet (le vieux tambourinaire).
@export var plume_scene: PackedScene
@export var character_material: ShaderMaterial
@export var character_shadow_material: Material
@export var prop_material: Material
@export var notebook: NotebookData

## Gardiens du Grand Muet.
const BOSS_GUARDS: Array[StringName] = [&"hopper", &"flyer"]
## Angle de l'entrée (sud) et écart entre deux passages de sortie (rad, autour du nord).
const ENTRANCE := PI
const EXIT_SPREAD := 0.55
## Les sanctuaires de l'ambiance sont repoussés à tant de rayons de clairière (hors de vue).
const NO_SANCTUARY := 100.0
## La source des anciens : rayon du bassin (cases d'un voxel du monde), gouttes qui jaillissent,
## couleurs codées (eau vive, pierre).
const SPRING_RADIUS := 3
const SPRING_DROPS := 4
const SPRING_WATER := Vector3(1.55, 0.8, 0.6)
const SPRING_STONE := Vector3(4.72, 0.15, 0.36)

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
## Clairière en cours : rayon (u), forme ; rencontre en cours (vide : aucune), faite ou non.
var _radius: float = 0.0
var _kind: StringName = &"clearing"
var _encounter: StringName = &""
var _encounter_open: bool = false
## Modèle de la vague précédente (pour ne pas le répéter) ; un élite a été libéré dans la clairière.
var _last_template: StringName = &""
var _elite_boon: bool = false
var _ambient: AmbientFx

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
	_ambient = AmbientFx.new()
	_ambient.name = "Ambient"
	add_child(_ambient)
	hero.fainted.connect(_on_hero_fainted)
	boon_screen.chosen.connect(_on_boon_chosen)
	boon_screen.choice_made.connect(_on_choice_made)
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


func _process(_delta: float) -> void:
	# La troupe du village chante quand le combo tient.
	if in_sortie:
		var tuning: TuningData = Tuning.data
		Rhythm.set_band(minf(float(hero.combo.hits) / tuning.combo_band_full, 1.0) * tuning.combo_band_max)
	# Une rencontre s'ouvre quand le héros s'approche du personnage.
	if _encounter == &"" or _encounter_open or not in_sortie or _cleared:
		return
	if Vector2(hero.global_position.x, hero.global_position.z).length() < Tuning.data.encounter_radius:
		_encounter_open = true
		var tuning: TuningData = Tuning.data
		var choices: PackedStringArray = []
		var enabled: Array[bool] = []
		for i: int in 2:
			choices.append(GameTexts.encounter_choice(_encounter, i, _encounter_value(i)))
			enabled.append(Encounters.can_choose(_encounter, i, Game.run.feathers, tuning))
		boon_screen.open_choices(GameTexts.ENCOUNTER_NAMES[_encounter], GameTexts.ENCOUNTER_TEXTS[_encounter], choices, enabled)


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
	var title: String = GameTexts.ROOM_COUNT % [room_name(), run.room + 1, run.room_count]
	if _cleared:
		var goal: Dictionary = {&"title": title, &"sub": GameTexts.ROOM_CHOOSE, &"icon": &"won"}
		if not _exit_angles.is_empty():
			# Le repère montre le milieu des passages.
			var p: Vector2 = WorldGen.gap_point(0.0, _radius) * _unit
			goal[&"point"] = Vector3(p.x, 0.0, p.y)
		return goal
	if run.is_boss_room():
		return {&"title": GameTexts.ROOM_BOSS_TITLE, &"sub": GameTexts.ROOM_BOSS_SUB, &"icon": &"crown"}
	if _encounter != &"":
		return {&"title": GameTexts.ENCOUNTER_NAMES[_encounter], &"sub": GameTexts.ROOM_ENCOUNTER, &"icon": RunState.ENCOUNTER, &"point": Vector3.ZERO}
	return {&"title": title, &"sub": GameTexts.ROOM_FIGHT % GameTexts.REWARD_NAMES[run.reward], &"icon": run.reward}


## Nom de la clairière en cours (selon sa forme, tiré de sa graine).
func room_name() -> String:
	var names: PackedStringArray = GameTexts.room_names(_kind)
	return names[Game.run.name_index(names.size())] if Game.run else names[0]


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
	_radius = Tuning.data.room_radius
	_kind = &"clearing"
	gen.generate_room(next_seed, _radius, PackedFloat32Array(), _kind)
	world.build(gen)
	_ambient.setup(_radius * _unit)
	_place_hero()


func _enter_room() -> void:
	var tuning: TuningData = Tuning.data
	var run: RunState = Game.run
	_cleared = false
	_wave = 0
	_remaining = 0
	_boss = null
	_encounter = &""
	_encounter_open = false
	_elite_boon = false
	_kind = run.room_kind()
	_radius = run.room_radius(tuning.room_radius_min, tuning.room_radius_max)
	for node: Node in foes.get_children() + pickups.get_children():
		node.queue_free()
	var exits: int = run.exit_count(tuning.room_exits)
	_exit_angles = PackedFloat32Array()
	for i: int in exits:
		_exit_angles.append((i - (exits - 1) / 2.0) * EXIT_SPREAD)
	gen.generate_room(run.room_seed(), _radius, _exit_angles, _kind)
	world.build(gen)
	_ambient.setup(_radius * _unit)
	for p: Vector3 in gen.pickups:
		var plume: Node3D = plume_scene.instantiate() as Node3D
		plume.position = p * _unit
		pickups.add_child(plume)
	mood.set_progress(float(run.room) / maxf(1.0, run.room_count - 1), false)
	Rhythm.set_layers(mini(1 + floori(float(run.room) * Rhythm.NIGHT_LAYERS.size() / run.room_count), Rhythm.NIGHT_LAYERS.size()))
	_place_hero()
	if run.is_boss_room():
		hud.show_banner(GameTexts.ROOM_TITLE % [run.room + 1, run.room_count], GameTexts.ROOM_BOSS_TITLE, "")
	if run.reward == RunState.ENCOUNTER:
		_encounter = run.pick_encounter(Encounters.IDS)
		_place_npc()
		return
	get_tree().create_timer(tuning.room_wave_delay, false).timeout.connect(_start_wave)


## Le héros arrive par l'entrée (au sud), face à la clairière.
func _place_hero() -> void:
	var tuning: TuningData = Tuning.data
	var start: Vector2 = WorldGen.gap_point(ENTRANCE, _radius - tuning.room_entry_inset / _unit)
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
		var spawner: EnemySpawner = _spawn(boss_scene, Vector2(0.0, -_radius * tuning.room_boss_depth))
		spawner.display_name = GameTexts.ROOM_BOSS_TITLE
		spawner.muet_freed.connect(func(muet: Muet) -> void: _on_boss_freed(muet), CONNECT_ONE_SHOT)
		for i: int in tuning.boss_room_guards:
			_spawn(_scene_of(BOSS_GUARDS[i % BOSS_GUARDS.size()]), _spawn_point())
		_wave += 1
		return
	var count: int = tuning.room_wave_base + roundi(tuning.room_wave_per_room * run.room)
	var wave: Dictionary = WaveComposer.compose(run.room, count, _rng, _last_template)
	_last_template = wave[&"id"]
	var elite: StringName = &""
	if not run.elite_done and run.room >= run.elite_room(tuning.elite_first_room):
		elite = run.elite_affix(Muet.ELITES)
		run.elite_done = true
	for species: StringName in wave[&"foes"]:
		_spawn(_scene_of(species), _spawn_point(WaveComposer.back_row(species)), elite)
		elite = &""
	_wave += 1


## Point d'apparition d'un Muet (u) : dans la clairière, loin du héros et du décor ; `back` : une
## espèce qui se tient en retrait apparaît deux fois plus loin du héros.
func _spawn_point(back: bool = false) -> Vector2:
	var tuning: TuningData = Tuning.data
	var from := Vector2(hero.global_position.x, hero.global_position.z) / _unit
	var clearance: float = tuning.room_spawn_hero_clearance / _unit * (2.0 if back else 1.0)
	var best := Vector2.ZERO
	for t: int in tuning.spawn_tries:
		var a: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(tuning.room_spawn_min, tuning.room_spawn_max) * _radius
		var p := Vector2(sin(a), -cos(a)) * r
		if _blocked(p, tuning.spawn_clearance / _unit):
			continue
		if p.distance_to(from) < clearance:
			if p.distance_to(from) > best.distance_to(from):
				best = p
			continue
		return p
	return best


func _spawn(scene: PackedScene, p: Vector2, elite: StringName = &"") -> EnemySpawner:
	var tuning: TuningData = Tuning.data
	var spawner := EnemySpawner.new()
	spawner.scene = scene
	spawner.elite = elite
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
		&"weaver":
			return weaver_scene
		&"totem":
			return totem_scene
		&"dancer":
			return dancer_scene
		&"brute":
			return brute_scene
	return hopper_scene


## Un élite appelant demande `count` renforts : des sautillants surgissent autour de lui.
func call_help(muet: Muet, count: int) -> void:
	var tuning: TuningData = Tuning.data
	if not in_sortie or _ending:
		return
	var center := Vector2(muet.global_position.x, muet.global_position.z) / _unit
	for k: int in count:
		var angle: float = TAU * k / count + _rng.randf()
		_spawn(hopper_scene, center + Vector2(cos(angle), sin(angle)) * tuning.boss_summon_distance / _unit)


## Un élite libéré : plumes d'or s'il était doré ; un don de l'élite attend la fin de la clairière.
func on_elite_freed(muet: Muet) -> void:
	var tuning: TuningData = Tuning.data
	if not in_sortie or Game.run == null:
		return
	_elite_boon = true
	if muet.elite == Muet.ELITE_GOLDEN:
		Game.run.feathers += tuning.elite_golden_feathers
		hud.show_toast(GameTexts.FEATHERS_FOUND % tuning.elite_golden_feathers)
		var fx: Effects = Effects.of(self)
		if fx:
			fx.burst(muet.global_position + Vector3.UP * tuning.hero_height, tuning.fx_plume_cubes, tuning.fx_plume_speed, tuning.fx_gold_hue)


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
	_after_reward()


func _on_boon_chosen(id: StringName) -> void:
	Game.take_boon(id)
	var fx: Effects = Effects.of(self)
	if fx:
		fx.burst(hero.global_position + Vector3.UP * Tuning.data.hero_height, Tuning.data.fx_plume_cubes, Tuning.data.fx_plume_speed)
	_after_reward()


## Après la récompense de la clairière : le don de l'élite s'il a été libéré ici, puis les passages.
func _after_reward() -> void:
	var tuning: TuningData = Tuning.data
	if _elite_boon and Game.run:
		_elite_boon = false
		boon_screen.open(Boons.offer(Game.run.rng, Game.run.boons, tuning.boon_offer, tuning), GameTexts.ELITE_BOON_TITLE)
		return
	_open_exits()


## Les passages surgissent au nord, chacun avec la récompense qu'il promet.
func _open_exits() -> void:
	var tuning: TuningData = Tuning.data
	var rewards: Array[StringName] = Game.run.exit_rewards(_exit_angles.size())
	for i: int in mini(rewards.size(), _exit_angles.size()):
		var gate: ExitGate = gate_scene.instantiate() as ExitGate
		gate.reward = rewards[i]
		var p: Vector2 = WorldGen.gap_point(_exit_angles[i], _radius - tuning.room_exit_inset / _unit)
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


## Personnage de la rencontre, au centre de la clairière, tourné vers l'entrée.
func _place_npc() -> void:
	var tuning: TuningData = Tuning.data
	var entry: Vector2 = WorldGen.gap_point(ENTRANCE, 1.0)
	var yaw: float = EnemyMath.yaw_of(Vector3(entry.x, 0.0, entry.y))
	var npc: Node3D
	match _encounter:
		&"spring":
			npc = _spring()
		&"merchant":
			var body := MuetBody.new()
			body.kind = &"hop"
			body.material = character_material
			body.shadow_material = character_shadow_material
			pickups.add_child(body)
			body.setup(tuning.hopper_scale * tuning.voxel_unit, tuning.hopper_radius)
			body.show_healed()
			body.target_yaw = yaw
			body.rotation.y = yaw
			return
		_:
			var villager := Villager.new()
			pickups.add_child(villager)
			if _encounter == &"drummer":
				villager.setup(VoxelStyles.chief(), "npc_drummer", tuning.chief_scale, yaw, 0.0, INF, character_material, character_shadow_material, tuning.chief_shadow_radius)
			else:
				villager.setup(VoxelStyles.dancer(Game.run.room), "npc_%s" % _encounter, 1.0, yaw, 0.0, INF, character_material, character_shadow_material, tuning.villager_shadow_radius)
			return
	pickups.add_child(npc)


## La source des anciens : un bassin de cubes d'eau entouré de pierres.
func _spring() -> Node3D:
	var cells := PackedFloat32Array()
	for x: int in range(-SPRING_RADIUS - 1, SPRING_RADIUS + 2):
		for z: int in range(-SPRING_RADIUS - 1, SPRING_RADIUS + 2):
			var d: float = Vector2(x, z).length()
			if d <= SPRING_RADIUS:
				VoxelMesh.add(cells, x, 0.2, z, SPRING_WATER)
			elif d <= SPRING_RADIUS + 1.2:
				VoxelMesh.add(cells, x, 0.5, z, SPRING_STONE)
	for i: int in SPRING_DROPS:
		VoxelMesh.add(cells, 0.0, 1.2 + i * 0.9, 0.0, SPRING_WATER, 0.6 - i * 0.12)
	var mesh: MultiMeshInstance3D = VoxelMesh.create(cells, prop_material)
	mesh.scale = Vector3.ONE * Tuning.data.voxel_unit
	return mesh


## Valeur affichée du choix `choice` de la rencontre en cours.
func _encounter_value(choice: int) -> int:
	var tuning: TuningData = Tuning.data
	match [_encounter, choice]:
		[&"spring", 1]:
			return roundi(tuning.encounter_spring_cost * 100.0)
		[&"merchant", 0]:
			return tuning.encounter_merchant_price
		[&"wounded", 0]:
			return roundi(tuning.encounter_wounded_cost)
		[&"wounded", 1]:
			return tuning.encounter_wounded_feathers
	return 0


## Le choix `index` de la rencontre : son effet, puis les passages s'ouvrent (un don se choisit
## d'abord).
func _on_choice_made(index: int) -> void:
	var tuning: TuningData = Tuning.data
	var run: RunState = Game.run
	_cleared = true
	var boon: bool = false
	match [_encounter, index]:
		[&"spring", 0]:
			hero.health.restore()
			hud.show_toast(GameTexts.HEALED % roundi(hero.health.maximum))
		[&"spring", 1]:
			hero.health.current = maxf(1.0, hero.health.current - hero.health.maximum * tuning.encounter_spring_cost)
			boon = true
		[&"merchant", 0]:
			run.feathers -= tuning.encounter_merchant_price
			boon = true
		[&"merchant", 1]:
			hero.health.heal(hero.health.maximum * tuning.encounter_merchant_heal)
		[&"drummer", 0]:
			Game.take_boon(&"metronome")
		[&"drummer", 1]:
			var page: int = _next_page()
			if page > 0:
				Game.add_page(page)
			hero.health.heal(hero.health.maximum * tuning.encounter_drummer_heal)
		[&"wounded", 0]:
			hero.health.current = maxf(1.0, hero.health.current - tuning.encounter_wounded_cost)
			Game.add_item(Game.roll_gift(false))
		[&"wounded", 1]:
			run.feathers += tuning.encounter_wounded_feathers
			hud.show_toast(GameTexts.FEATHERS_FOUND % tuning.encounter_wounded_feathers)
	if boon:
		boon_screen.open(Boons.offer(run.rng, run.boons, tuning.boon_offer, tuning))
	else:
		_open_exits()


## Première page du carnet pas encore trouvée (0 : toutes le sont).
func _next_page() -> int:
	for page: int in range(1, notebook.pages.size() + 1):
		if not Game.profile.has_page(page):
			return page
	return 0


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
