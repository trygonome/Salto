class_name Expedition
extends Level
## Une expédition, façon action-RPG : une suite de clairières générées (graine de l'expédition),
## chacune promet une récompense (don des esprits, soin, plumes d'or) et lâche ses Muets par
## vagues ; nettoyée, elle donne sa récompense et ouvre ses passages, chacun annonçant la sienne.
## La dernière clairière est gardée par un Grand Muet : le libérer termine l'expédition. Tomber
## (ou rentrer depuis la pause) aussi ; on garde l'expérience et les plumes d'or rapportées.
## Avant de partir, l'écran titre s'affiche sur une clairière de camp.
## Version 2.6 : trois régions (couleurs, formes de clairière, gardien), pièges au tempo, tambours de
## guerre, jarres, rocher fêlé qui ouvre un passage secret, salles de repos et de trésor ; l'eau
## ralentit.
## Version 2.7 : le camp est le village. On y marche au retour d'une expédition (ou depuis l'écran
## titre) : le Chef commente la partie, les danseurs font la fête, les plumes d'or rebâtissent les
## cases (s'en approcher), et le passage du nord part en expédition.

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
@export var ruins_guardian_scene: PackedScene
@export var canopy_guardian_scene: PackedScene
@export var gate_scene: PackedScene
## Décor de jeu (version 2.6) : annonce au sol (pièges), modèle et son du tambour de guerre, coffre.
@export var telegraph_scene: PackedScene
@export var war_drum_model: PackedScene
@export var war_drum_sound: AudioStream
@export var chest_scene: PackedScene
## Son discret des pièges (version 3.0).
@export var trap_sound: AudioStream
## Plume arc-en-ciel des perchoirs ; personnages des rencontres (matériaux des villageois et des
## Muets, de leurs ombres, des petits assemblages) ; pages du carnet (le vieux tambourinaire).
@export var plume_scene: PackedScene
@export var character_material: ShaderMaterial
@export var character_shadow_material: Material
@export var prop_material: Material
@export var notebook: NotebookData

## Gardiens du gardien, par région.
const BOSS_GUARDS: Array[StringName] = [&"hopper", &"flyer"]
const REGION_GUARDS: Dictionary[StringName, Array] = {
	&"undergrowth": [&"hopper", &"flyer"], &"sunken": [&"shielder", &"spitter"], &"canopy": [&"flyer", &"dancer"],
}
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
## Le feu de camp (salle de repos) : pierres autour (rayon, en voxels), bûches, flammes.
const CAMPFIRE_STONES := 8
const CAMPFIRE_RADIUS := 2.2
const CAMPFIRE_WOOD := Vector3(0.07, 0.5, 0.25)
const CAMPFIRE_FLAMES := 14
const CAMPFIRE_FLAME_TIME := 0.8
const CAMPFIRE_FLAME_SPREAD := 12.0
const CAMPFIRE_FLAME_SPEED := 3.0
const CAMPFIRE_FLAME_BASE := 0.6
const CAMPFIRE_FLAME_CUBE := 0.5
const CAMPFIRE_FLAME_HOT := Color(1.0, 0.85, 0.3)
const CAMPFIRE_FLAME_COOL := Color(0.95, 0.25, 0.1, 0.0)
## L'Arbre muet : hauteur du tronc (cases), écorce grise, feuilles qui ont gardé leur couleur.
const MUTE_TREE_HEIGHT := 9
const MUTE_TREE_BARK := Vector3(4.6, 0.05, 0.45)
const MUTE_TREE_LEAF := Vector3(2.3, 0.8, 0.5)
## Village : cercle des danseurs autour du feu (u, au-delà du feu).
const VILLAGE_DANCE_RING := 3.0
## Le râtelier des instruments, parmi les endroits du village qui parlent.
const RACK := &"rack"
const PACT_STONE := &"pacts"

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
## Passage secret ouvert par le rocher fêlé (Vector2.INF : aucun) ; coffre de la salle (trésor, secret).
var _secret_at := Vector2.INF
var _chest: Node3D
## Au village (on y marche) : le Chef et ses répliques à dire, la case dont on s'est approché (vide :
## aucune ; elle ne reparle qu'une fois qu'on s'en est éloigné), repères au-dessus des cases.
var in_village: bool = false
var _chief: Villager
var _chief_lines := PackedStringArray()
var _line_left: float = 0.0
var _plot_near: StringName = &""
var _plot_marks: Dictionary[StringName, Node3D] = {}
## Conseils près des boutons (version 2.9).
var _coach: ExpeditionCoach
## Musique qui suit le combat (version 3.1) : couches de la clairière, et si l'on se bat.
var _music_layers: int = 1
var _fighting: bool = false
## Sentiers (version 3.4) : les vagues attendent que le héros entre dans l'arène ; une stèle des
## esprits offre son don (sans ouvrir les passages) ; le Muet doré caché d'un recoin.
var _arena_waiting: bool = false
var _stele_pending: bool = false
var _hidden_spawner: EnemySpawner
## Recoin où dort le Muet doré (u) : il s'éveille quand le héros y entre (Vector2.INF : aucun).
var _hidden_at := Vector2.INF

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
	hero.hurtbox.hurt.connect(_on_hero_hurt)
	_coach = ExpeditionCoach.new(hud, hero)
	Rhythm.play(Village.music_layers(Game.profile))
	Rhythm.set_band(0.0)
	_build_camp()
	if Game.start_on_load:
		Game.start_on_load = false
		start_sortie()
	elif Game.village_on_load:
		Game.village_on_load = false
		enter_village()
	else:
		_show_title()


func _exit_tree() -> void:
	Rhythm.stop()
	Rhythm.set_region(&"")


func _process(delta: float) -> void:
	if in_village:
		_process_village(delta)
		return
	# La troupe du village chante quand le combo tient (toujours un peu, avec la scène rebâtie).
	if in_sortie:
		var tuning: TuningData = Tuning.data
		_coach.update(delta)
		var at := Vector2(hero.global_position.x, hero.global_position.z)
		if _arena_waiting and not _ending and at.length() < _radius * _unit * tuning.arena_trigger:
			_arena_waiting = false
			get_tree().create_timer(tuning.room_wave_delay, false).timeout.connect(_start_wave)
		if _hidden_at != Vector2.INF and at.distance_to(_hidden_at * _unit) < WorldGen.NICHE_R * _unit:
			_wake_hidden()
		# Pendant un combat, la musique s'étoffe ; nettoyée, la clairière retrouve son calme.
		var fighting: bool = _remaining > 0 and not _cleared
		if fighting != _fighting:
			_fighting = fighting
			Rhythm.set_layers(mini(_music_layers + (tuning.music_fight_layers if fighting else 0), Rhythm.NIGHT_LAYERS.size()))
		Rhythm.set_band(maxf(minf(float(hero.combo.hits) / tuning.combo_band_full, 1.0) * tuning.combo_band_max, Village.band_floor(Game.profile, tuning)))
	# Une rencontre s'ouvre quand le héros s'approche du personnage.
	if _encounter == &"" or _encounter_open or not in_sortie or _cleared:
		return
	if Vector2(hero.global_position.x, hero.global_position.z).length() < Tuning.data.encounter_radius:
		_encounter_open = true
		var tuning: TuningData = Tuning.data
		var choices: PackedStringArray = []
		var enabled: Array[bool] = []
		var sharpenable: bool = Boons.sharpen_pick(RandomNumberGenerator.new(), Game.run.boons, tuning) != &""
		var duo_ready: bool = not Boons.eligible_duos(Game.run.boons).is_empty()
		for i: int in 2:
			choices.append(GameTexts.encounter_choice(_encounter, i, _encounter_value(i)))
			enabled.append(Encounters.can_choose(_encounter, i, Game.run.feathers, tuning, sharpenable, duo_ready))
		boon_screen.open_choices(GameTexts.ENCOUNTER_NAMES[_encounter], GameTexts.ENCOUNTER_TEXTS[_encounter], choices, enabled)


func is_expedition() -> bool:
	return true


func shows_drums() -> bool:
	return false


## Objectif du moment : se battre (et ce que la clairière promet), choisir un passage, le Grand
## Muet.
func current_goal() -> Dictionary:
	if in_village:
		var gate: Vector2 = WorldGen.gap_point(0.0, _radius) * _unit
		var sub: String = GameTexts.VILLAGE_SUB % GameTexts.feathers(Game.profile.feathers)
		var bonus: int = roundi((Pacts.feather_multiplier(Game.profile.pacts, Tuning.data) - 1.0) * 100.0)
		if bonus > 0:
			sub += GameTexts.PACTS_SUB % bonus
		return {&"title": GameTexts.VILLAGE_TITLE, &"sub": sub, &"icon": &"home", &"point": Vector3(gate.x, 0.0, gate.y)}
	var run: RunState = Game.run
	if run == null or not in_sortie:
		return {}
	var tuning: TuningData = Tuning.data
	var title: String = GameTexts.ROOM_COUNT % [room_name(), run.room + 1, run.room_count]
	if _cleared:
		var goal: Dictionary = {&"title": title, &"sub": GameTexts.ROOM_CHOOSE, &"icon": &"won"}
		if not _exit_angles.is_empty():
			# Le repère montre le milieu des passages (le bout des sentiers de sortie).
			var p: Vector2 = WorldGen.gap_point(0.0, _radius) * _unit
			if not gen.exit_paths.is_empty():
				p = Vector2.ZERO
				for path: PackedVector2Array in gen.exit_paths:
					p += path[path.size() - 1] * _unit / gen.exit_paths.size()
			goal[&"point"] = Vector3(p.x, 0.0, p.y)
		return goal
	if run.is_boss_room():
		return {&"title": GameTexts.GUARDIAN_NAMES.get(run.region, GameTexts.ROOM_BOSS_TITLE), &"sub": GameTexts.ROOM_BOSS_SUB, &"icon": &"crown"}
	if _encounter != &"":
		var icon: StringName = RunState.REST if _encounter == &"rest" else RunState.ENCOUNTER
		return {&"title": GameTexts.ENCOUNTER_NAMES[_encounter], &"sub": GameTexts.ROOM_ENCOUNTER, &"icon": icon, &"point": Vector3.ZERO}
	var fight_goal: Dictionary = {&"title": title, &"sub": GameTexts.ROOM_FIGHT % GameTexts.REWARD_NAMES[run.reward], &"icon": run.reward}
	if _arena_waiting:
		# Sur le sentier : le repère montre l'arène.
		fight_goal[&"point"] = Vector3.ZERO
	return fight_goal


## Nom de la clairière en cours (selon sa forme, tiré de sa graine).
func room_name() -> String:
	var names: PackedStringArray = GameTexts.room_names(_kind)
	return names[Game.run.name_index(names.size())] if Game.run else names[0]


## Part en expédition depuis l'écran titre (ou Repartir).
func start_sortie() -> void:
	var tuning: TuningData = Tuning.data
	Game.start_run(next_seed, tuning.run_rooms, Game.profile.region)
	in_village = false
	_chief = null
	_plot_marks.clear()
	in_sortie = true
	_ending = false
	hero.begin_sortie()
	hero.reads_player_input = true
	hud.visible = true
	touch_controls.visible = true
	get_tree().call_group(&"title_screen", &"close")
	_enter_room()


## Reprend l'expédition interrompue, au début de la clairière où elle s'est arrêtée (version 2.9).
func resume_sortie() -> void:
	var health: float = Game.resume_run()
	if health < 0.0:
		start_sortie()
		return
	in_village = false
	_chief = null
	_plot_marks.clear()
	in_sortie = true
	_ending = false
	hero.begin_sortie()
	hero.health.current = clampf(health, 1.0, hero.health.maximum)
	hero.reads_player_input = true
	hud.visible = true
	touch_controls.visible = true
	get_tree().call_group(&"title_screen", &"close")
	_enter_room()


## Termine l'expédition (&"won", &"faint" ou &"quit") et ouvre le résumé.
func end_sortie(kind: StringName) -> void:
	if in_village:
		# Depuis le village, « rentrer » ramène à l'écran titre.
		Game.village_on_load = false
		restart(false)
		return
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
	# Retour d'une expédition : on arrive au village, où le Chef la commente.
	Game.village_on_load = not play and not in_village and Game.last_summary.size() > 0
	get_tree().paused = false
	get_tree().reload_current_scene()


## Résumé affiché pour l'expédition terminée `s` (voir Game.end_run).
static func summary_of(s: Dictionary) -> Dictionary:
	var kind: StringName = s[&"kind"]
	var brought: String = GameTexts.feathers(s[&"feathers"])
	var sub: String = GameTexts.RUN_WON_SUB % brought if kind == &"won" else (GameTexts.RUN_LOST_SUB if kind == &"faint" else GameTexts.RUN_QUIT_SUB) % [s[&"room"], brought]
	var rows: Array = [
		[GameTexts.RUN_REGION, GameTexts.REGION_NAMES.get(s.get(&"region", Regions.UNDERGROWTH), "")],
		[GameTexts.RUN_ROOMS, "%d / %d" % [s[&"room"], s[&"rooms"]]],
		[GameTexts.SUMMARY_MUETS, str(s[&"muets"])],
		[GameTexts.RUN_BOONS, str(s[&"boons"])],
		[GameTexts.SUMMARY_LEVEL, str(s[&"level"])],
		[GameTexts.SUMMARY_TIME, GameTexts.duration(s[&"time"])],
	]
	if int(s.get(&"pacts", 0)) > 0:
		rows.append([GameTexts.RUN_PACTS, str(s[&"pacts"])])
	var unlocked: StringName = s.get(&"unlocked", &"")
	if unlocked != &"":
		rows.append([GameTexts.RUN_UNLOCKED, GameTexts.REGION_NAMES.get(unlocked, "")])
	return {
		&"title": GameTexts.RUN_WON if kind == &"won" else (GameTexts.RUN_LOST if kind == &"faint" else GameTexts.RUN_QUIT),
		&"sub": sub,
		&"rows": rows,
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
	var guards: Array = REGION_GUARDS.get(Game.run.region, BOSS_GUARDS) if Game.run else BOSS_GUARDS
	for k: int in tuning.boss_summon_count:
		var angle: float = _rng.randf() * TAU
		_spawn(_scene_of(guards[k % guards.size()]), center + Vector2(cos(angle), sin(angle)) * tuning.boss_summon_distance / _unit)


## Écran titre : le camp prend les couleurs de la région montrée.
func preview_region(region: StringName) -> void:
	if in_sortie:
		return
	# Au village, on ne reconstruit pas la clairière (le Chef et les danseurs y sont) : ses couleurs suffisent.
	if in_village:
		_apply_region(region)
		return
	_build_camp(region)


func _show_title() -> void:
	in_sortie = false
	hero.reads_player_input = false
	hud.visible = false
	touch_controls.visible = false
	get_tree().call_group(&"title_screen", &"open")


## Clairière du camp (écran titre) : une clairière calme, sans Muets.
func _build_camp(region: StringName = &"") -> void:
	_radius = Tuning.data.room_radius
	_kind = &"clearing"
	if region == &"":
		region = Game.profile.region if Game.profile else Regions.UNDERGROWTH
	_apply_region(region)
	_kind = &"village"
	gen.village_built.clear()
	if Game.profile:
		gen.village_built = Game.profile.village.duplicate()
	gen.generate_room(next_seed, _radius, PackedFloat32Array([0.0]), _kind)
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
	_secret_at = Vector2.INF
	_chest = null
	_arena_waiting = false
	_stele_pending = false
	_hidden_spawner = null
	_hidden_at = Vector2.INF
	_kind = run.room_kind()
	_radius = run.room_radius(tuning.room_radius_min, tuning.room_radius_max)
	_apply_region(run.region)
	# Sauvegarde pour reprendre ici si l'application se ferme (version 2.9).
	Game.snapshot_run(hero.health.current)
	for node: Node in foes.get_children() + pickups.get_children():
		node.queue_free()
	var exits: int = run.exit_count(tuning.room_exits)
	_exit_angles = PackedFloat32Array()
	for i: int in exits:
		_exit_angles.append((i - (exits - 1) / 2.0) * EXIT_SPREAD)
	var fight: bool = run.reward != RunState.ENCOUNTER and run.reward != RunState.REST and run.reward != RunState.SECRET
	# (Pas de Muet caché pendant la première expédition : elle apprend une espèce à la fois.)
	gen.generate_room(run.room_seed(), _radius, _exit_angles, _kind, fight and not run.tutorial)
	world.build(gen)
	_ambient.setup(_radius * _unit)
	for p: Vector3 in gen.pickups:
		var plume: Node3D = plume_scene.instantiate() as Node3D
		plume.position = p * _unit
		pickups.add_child(plume)
	if not run.is_boss_room() and fight:
		_place_room_props()
	_place_niches()
	mood.set_progress(float(run.room) / maxf(1.0, run.room_count - 1), false)
	_music_layers = mini(maxi(Village.music_layers(Game.profile), 1 + floori(float(run.room) * Rhythm.NIGHT_LAYERS.size() / run.room_count)), Rhythm.NIGHT_LAYERS.size())
	_fighting = false
	Rhythm.set_layers(_music_layers)
	_place_hero()
	if run.is_boss_room():
		hud.show_banner(GameTexts.ROOM_TITLE % [run.room + 1, run.room_count], GameTexts.GUARDIAN_NAMES.get(run.region, GameTexts.ROOM_BOSS_TITLE), "")
	if run.reward == RunState.ENCOUNTER:
		_encounter = run.pick_encounter(Encounters.IDS)
		_place_npc()
		return
	if run.reward == RunState.REST:
		_encounter = &"rest"
		_place_npc()
		return
	if run.reward == RunState.SECRET:
		# Le secret : un trésor, sans combat.
		_cleared = true
		_place_chest()
		return
	# Version 3.4 : les Muets attendent que le héros arrive dans l'arène par le sentier.
	_arena_waiting = true


## Couleurs de la région : feuillage, sol, brume ; sa couche de musique.
func _apply_region(region: StringName) -> void:
	gen.foliage_shift = Regions.FOLIAGE_SHIFT.get(region, 0.0)
	var ground: ShaderMaterial = world.ground_material
	if ground:
		ground.set_shader_parameter(&"grass_hsl", Regions.GRASS.get(region, Regions.GRASS[Regions.UNDERGROWTH]))
		ground.set_shader_parameter(&"dirt_color", Regions.DIRT.get(region, Regions.DIRT[Regions.UNDERGROWTH]))
	mood.set_fog_hue(Regions.FOG_HUE.get(region, -1.0))
	Rhythm.set_region(region)


## Décor de jeu d'une clairière de combat : pièges au tempo, tambours de guerre, jarres, rocher fêlé.
func _place_room_props() -> void:
	for trap_data: Dictionary in gen.traps:
		var trap := BeatTrap.new()
		trap.kind = trap_data[&"kind"]
		trap.phase = trap_data[&"phase"]
		trap.angle = trap_data[&"angle"]
		trap.telegraph_scene = telegraph_scene
		trap.sound = trap_sound
		trap.material = prop_material
		trap.position = Vector3(trap_data[&"x"], 0.0, trap_data[&"z"]) * _unit
		pickups.add_child(trap)
	for p: Vector2 in gen.drums:
		var drum := WarDrum.new()
		drum.model_scene = war_drum_model
		drum.sound = war_drum_sound
		drum.position = Vector3(p.x, 0.0, p.y) * _unit
		pickups.add_child(drum)
	for p: Vector2 in gen.jars:
		pickups.add_child(_breakable(Breakable.JAR, p))
	if gen.secret != Vector2.INF:
		var boulder: Breakable = _breakable(Breakable.BOULDER, gen.secret)
		pickups.add_child(boulder)
		boulder.revealed.connect(_on_secret_revealed.bind(gen.secret))


func _breakable(kind: StringName, p: Vector2) -> Breakable:
	var item := Breakable.new()
	item.kind = kind
	item.material = prop_material
	item.rng.seed = hash([Game.run.room_seed(), p]) if Game.run else 0
	item.position = Vector3(p.x, 0.0, p.y) * _unit
	return item


## Les recoins (version 3.4) : un fourré à trancher à l'entrée des recoins cachés ; au fond, des
## jarres, un nid de plumes d'or, une stèle des esprits ou un Muet doré endormi.
func _place_niches() -> void:
	var tuning: TuningData = Tuning.data
	for niche: Dictionary in gen.niches:
		var center: Vector2 = niche[&"center"]
		var dir: Vector2 = niche[&"dir"]
		if niche[&"hidden"]:
			pickups.add_child(_breakable(Breakable.THICKET, niche[&"mouth"]))
		match niche[&"reward"]:
			Niches.JARS:
				for k: int in tuning.niche_jars:
					var angle: float = TAU * k / tuning.niche_jars
					pickups.add_child(_breakable(Breakable.JAR, center + Vector2(cos(angle), sin(angle)) * WorldGen.NICHE_R * 0.4))
			Niches.FEATHERS:
				pickups.add_child(_breakable(Breakable.NEST, center))
			Niches.STELE:
				var stele := SpiritStele.new()
				stele.material = prop_material
				stele.position = Vector3(center.x, 0.0, center.y) * _unit
				# La dalle regarde l'entrée du recoin.
				stele.rotation.y = atan2(dir.x, dir.y)
				pickups.add_child(stele)
				stele.awakened.connect(_on_stele_awakened)
			Niches.MUET:
				_hidden_at = center


## Une stèle s'éveille : un don au choix (il ne termine pas la clairière).
func _on_stele_awakened() -> void:
	if not in_sortie or Game.run == null or boon_screen.is_open():
		return
	_stele_pending = true
	hero.input_move = Vector2.ZERO
	boon_screen.open(Boons.deal(Game.run.rng, Game.run.boons, Tuning.data.stele_offer, Tuning.data), GameTexts.STELE_TITLE)


## Le héros entre dans le recoin du Muet doré : il s'éveille (hors des vagues, il garde son creux).
func _wake_hidden() -> void:
	var tuning: TuningData = Tuning.data
	var spawner := EnemySpawner.new()
	spawner.scene = hopper_scene
	spawner.elite = Muet.ELITE_GOLDEN
	spawner.position = Vector3(_hidden_at.x, 0.0, _hidden_at.y) * _unit
	spawner.tier = floori(Game.run.room * tuning.room_tier_per_room) if Game.run else 0
	_hidden_at = Vector2.INF
	foes.add_child(spawner)
	spawner.muet_freed.connect(_on_hidden_freed)
	_hidden_spawner = spawner
	var fx: Effects = Effects.of(self)
	if fx:
		fx.ring(spawner.position, tuning.fx_spawn_ring, fx.gold, tuning.fx_spawn_ring_time)


## Le Muet doré d'un recoin est libéré (hors des vagues).
func _on_hidden_freed(_muet: Muet) -> void:
	if Game.run:
		Game.run.muets_freed += 1


## Le rocher fêlé cède : un passage secret s'ouvrira là (tout de suite si les passages sont ouverts).
func _on_secret_revealed(_at: Vector3, p: Vector2) -> void:
	_secret_at = p
	if _cleared and not pickups.get_children().filter(func(n: Node) -> bool: return n is ExitGate).is_empty():
		_add_gate(RunState.SECRET, p)


## Coffre au centre de la clairière (trésor après le combat, ou secret) : plumes d'or et un don.
func _place_chest() -> void:
	if chest_scene == null:
		_after_reward()
		return
	_chest = chest_scene.instantiate() as Node3D
	_chest.position = Vector3.ZERO
	pickups.add_child(_chest)
	_chest.connect(&"opened", _on_chest_opened)


func _on_chest_opened() -> void:
	var tuning: TuningData = Tuning.data
	var run: RunState = Game.run
	if run == null:
		return
	var gained: int = tuning.secret_feathers if run.reward == RunState.SECRET else tuning.treasure_feathers
	run.feathers += gained
	hud.show_toast(GameTexts.FEATHERS_FOUND % gained)
	boon_screen.open(Boons.deal(run.rng, run.boons, _boon_offer(), tuning))


## Vitesse de marche : l'eau (rivière, mare) ralentit, sauf sur les ponts.
func terrain_speed(position_m: Vector3) -> float:
	if gen == null or not in_sortie:
		return 1.0
	return Tuning.data.water_speed if gen.water_at(Vector2(position_m.x, position_m.z) / _unit) else 1.0


## Le héros arrive par l'entrée (au sud), face à la clairière.
func _place_hero() -> void:
	var tuning: TuningData = Tuning.data
	var start: Vector2 = WorldGen.gap_point(ENTRANCE, _radius - tuning.room_entry_inset / _unit)
	var facing := Vector3.FORWARD
	# Version 3.4 : au bout du sentier d'entrée, tourné vers le chemin.
	if gen.entry_path.size() > 1 and not in_village:
		start = gen.entry_path[gen.entry_path.size() - 1]
		var toward: Vector2 = (gen.entry_path[gen.entry_path.size() - 2] - start).normalized()
		facing = Vector3(toward.x, 0.0, toward.y)
	hero.global_position = Vector3(start.x, 0.0, start.y) * _unit
	hero.velocity = Vector3.ZERO
	hero.face_now(facing)
	hero.reset_physics_interpolation()
	camera_rig.call(&"snap")


func _start_wave() -> void:
	if not in_sortie or _ending:
		return
	var tuning: TuningData = Tuning.data
	var run: RunState = Game.run
	if run.is_boss_room() and _wave == 0:
		var spawner: EnemySpawner = _spawn(_guardian_scene(run.region), Vector2(0.0, -_radius * tuning.room_boss_depth))
		spawner.display_name = GameTexts.GUARDIAN_NAMES.get(run.region, GameTexts.ROOM_BOSS_TITLE)
		spawner.muet_freed.connect(func(muet: Muet) -> void: _on_boss_freed(muet), CONNECT_ONE_SHOT)
		var guards: Array = REGION_GUARDS.get(run.region, BOSS_GUARDS)
		for i: int in tuning.boss_room_guards:
			_spawn(_scene_of(guards[i % guards.size()]), _spawn_point())
		_wave += 1
		return
	var count: int = tuning.room_wave_base + roundi(tuning.room_wave_per_room * run.room)
	var wave: Dictionary = WaveComposer.compose(run.room, count, _rng, _last_template, Regions.FAVORITE_WAVES.get(run.region, []))
	_last_template = wave[&"id"]
	# Première expédition : des vagues qui apprennent, une espèce à la fois, sans élite.
	var lesson: Array[StringName] = []
	if run.tutorial:
		lesson = WaveComposer.tutorial(run.room, _wave)
	if not lesson.is_empty():
		wave[&"foes"] = lesson
	var elite: StringName = &""
	if lesson.is_empty() and not (run.tutorial and run.room < WaveComposer.TUTORIAL.size()) and not run.elite_done and run.room >= run.elite_room(tuning.elite_first_room):
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


## Gardien de la région (le Grand Muet, le Gardien des Ruines, la Reine des Cimes).
func _guardian_scene(region: StringName) -> PackedScene:
	match Regions.GUARDIANS.get(region, &"ground"):
		&"ruins":
			return ruins_guardian_scene if ruins_guardian_scene else boss_scene
		&"canopy":
			return canopy_guardian_scene if canopy_guardian_scene else boss_scene
	return boss_scene


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
	# Le Muet doré caché d'un recoin donne son or, pas de don.
	if _hidden_spawner == null or muet != _hidden_spawner.muet:
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
	# Repousse (don) : chaque clairière nettoyée soigne un peu.
	if hero.stats.regrowth > 0.0:
		hero.health.heal(hero.stats.regrowth)
	match run.reward:
		RunState.BOON:
			boon_screen.open(Boons.deal(run.rng, run.boons, _boon_offer(), tuning))
			return
		RunState.HEAL:
			var amount: float = hero.health.maximum * tuning.room_heal
			hero.health.heal(amount)
			hud.show_toast(GameTexts.HEALED % roundi(amount))
			if fx:
				fx.burst(hero.global_position + Vector3.UP * tuning.hero_height, tuning.fx_plume_cubes, tuning.fx_plume_speed, tuning.fx_heal_hue)
		RunState.TREASURE:
			_place_chest()
			return
		RunState.FEATHERS:
			var gained: int = tuning.room_feathers_base + tuning.room_feathers_per_room * run.room
			run.feathers += gained
			hud.show_toast(GameTexts.FEATHERS_FOUND % gained)
			if fx:
				fx.burst(hero.global_position + Vector3.UP * tuning.hero_height, tuning.fx_plume_cubes, tuning.fx_plume_speed, tuning.fx_gold_hue)
	_after_reward()


func _on_boon_chosen(id: StringName, ranks: int) -> void:
	Game.take_boon(id, ranks)
	var fx: Effects = Effects.of(self)
	if fx:
		fx.burst(hero.global_position + Vector3.UP * Tuning.data.hero_height, Tuning.data.fx_plume_cubes, Tuning.data.fx_plume_speed)
	# Le don d'une stèle ne termine pas la clairière.
	if _stele_pending:
		_stele_pending = false
		return
	_after_reward()


## Après la récompense de la clairière : le don de l'élite s'il a été libéré ici, puis les passages.
func _after_reward() -> void:
	var tuning: TuningData = Tuning.data
	if _elite_boon and Game.run:
		_elite_boon = false
		boon_screen.open(Boons.deal(Game.run.rng, Game.run.boons, _boon_offer(), tuning, Boons.RARE), GameTexts.ELITE_BOON_TITLE)
		return
	_open_exits()


## Les passages surgissent au nord, chacun avec la récompense qu'il promet.
func _open_exits() -> void:
	var tuning: TuningData = Tuning.data
	var rewards: Array[StringName] = Game.run.exit_rewards(_exit_angles.size())
	for i: int in mini(rewards.size(), _exit_angles.size()):
		# Version 3.4 : au bout du sentier de chaque sortie.
		if i < gen.exit_paths.size():
			var path: PackedVector2Array = gen.exit_paths[i]
			_add_gate(rewards[i], path[path.size() - 1], path[path.size() - 2])
		else:
			_add_gate(rewards[i], WorldGen.gap_point(_exit_angles[i], _radius - tuning.room_exit_inset / _unit))
	if _secret_at != Vector2.INF:
		_add_gate(RunState.SECRET, _secret_at)


## Un passage qui promet `reward`, en `p` (u), tourné vers `facing` (u ; le centre par défaut).
func _add_gate(reward: StringName, p: Vector2, facing: Vector2 = Vector2.ZERO) -> void:
	var gate: ExitGate = gate_scene.instantiate() as ExitGate
	gate.reward = reward
	gate.position = Vector3(p.x, 0.0, p.y) * _unit
	var inward: Vector2 = (facing - p).normalized()
	gate.rotation.y = atan2(inward.x, inward.y)
	pickups.add_child(gate)
	gate.chosen.connect(_on_gate_chosen)


func _on_gate_chosen(reward: StringName) -> void:
	if in_village:
		_open_depart()
		return
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
		&"rest":
			npc = _campfire()
		&"mute_tree":
			npc = _mute_tree()
		&"echo_spirit":
			var echo := MuetBody.new()
			echo.kind = &"dance"
			echo.material = character_material
			echo.shadow_material = character_shadow_material
			pickups.add_child(echo)
			echo.setup(tuning.dancer_scale * tuning.voxel_unit, tuning.dancer_radius)
			echo.show_healed()
			echo.target_yaw = yaw
			echo.rotation.y = yaw
			return
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


## Le feu de camp : un cercle de pierres, des bûches croisées, des flammes qui dansent.
func _campfire() -> Node3D:
	var cells := PackedFloat32Array()
	for i: int in CAMPFIRE_STONES:
		var a: float = TAU * i / CAMPFIRE_STONES
		VoxelMesh.add(cells, cos(a) * CAMPFIRE_RADIUS, 0.4, sin(a) * CAMPFIRE_RADIUS, SPRING_STONE, 0.8)
	for k: int in range(-1, 2):
		VoxelMesh.add(cells, k * 0.8, 0.5, 0.0, CAMPFIRE_WOOD, 0.7)
		VoxelMesh.add(cells, 0.0, 0.9, k * 0.8, CAMPFIRE_WOOD, 0.7)
	var mesh: MultiMeshInstance3D = VoxelMesh.create(cells, prop_material)
	mesh.scale = Vector3.ONE * Tuning.data.voxel_unit
	var flames := CPUParticles3D.new()
	flames.name = "Flames"
	flames.amount = CAMPFIRE_FLAMES
	flames.lifetime = CAMPFIRE_FLAME_TIME
	flames.direction = Vector3.UP
	flames.spread = CAMPFIRE_FLAME_SPREAD
	flames.initial_velocity_min = CAMPFIRE_FLAME_SPEED * 0.5
	flames.initial_velocity_max = CAMPFIRE_FLAME_SPEED
	flames.gravity = Vector3.ZERO
	flames.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	flames.emission_sphere_radius = CAMPFIRE_FLAME_BASE
	flames.scale_amount_min = 0.5
	flames.scale_amount_max = 1.0
	var fade := Gradient.new()
	fade.set_color(0, CAMPFIRE_FLAME_HOT)
	fade.set_color(1, CAMPFIRE_FLAME_COOL)
	flames.color_ramp = fade
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * CAMPFIRE_FLAME_CUBE
	var flame_material := StandardMaterial3D.new()
	flame_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_material.vertex_color_use_as_albedo = true
	flame_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cube.material = flame_material
	flames.mesh = cube
	flames.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flames.position = Vector3.UP * 1.2
	mesh.add_child(flames)
	return mesh


## L'Arbre muet : un fromager gris, ses racines, quelques feuilles qui ont gardé leur couleur.
func _mute_tree() -> Node3D:
	var cells := PackedFloat32Array()
	for y: int in MUTE_TREE_HEIGHT:
		var r: int = 2 if y < 3 else 1
		for x: int in range(-r, r + 1):
			for z: int in range(-r, r + 1):
				if Vector2(x, z).length() <= r + 0.3:
					VoxelMesh.add(cells, x, y + 0.5, z, MUTE_TREE_BARK)
	for i: int in 6:
		var a: float = TAU * i / 6.0
		for k: int in 3:
			VoxelMesh.add(cells, cos(a) * (2.5 + k), 0.4, sin(a) * (2.5 + k), MUTE_TREE_BARK, 0.8)
	for x: int in range(-4, 5):
		for z: int in range(-4, 5):
			if Vector2(x, z).length() <= 4.2:
				var colored: bool = posmod(x * 7 + z * 3, 11) == 0
				VoxelMesh.add(cells, x, MUTE_TREE_HEIGHT + 0.5 + posmod(x + z, 2), z, MUTE_TREE_LEAF if colored else MUTE_TREE_BARK)
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
		[&"rest", 0]:
			return roundi(tuning.rest_heal * 100.0)
		[&"weaver_lady", 0]:
			return tuning.encounter_weaver_price
		[&"mute_tree", 1]:
			return roundi(tuning.encounter_tree_heal * 100.0)
	return 0


## Le choix `index` de la rencontre : son effet, puis les passages s'ouvrent (un don se choisit
## d'abord).
func _on_choice_made(index: int) -> void:
	if in_village:
		_on_build_choice(index)
		return
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
			Game.take_boon(&"tempo")
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
		[&"rest", 0]:
			var amount: float = hero.health.maximum * tuning.rest_heal
			hero.health.heal(amount)
			hud.show_toast(GameTexts.HEALED % roundi(amount))
		[&"rest", 1]:
			var sharpened: StringName = Boons.sharpen_pick(run.rng, run.boons, tuning)
			if sharpened != &"":
				Game.take_boon(sharpened)
				hud.show_toast(GameTexts.BOON_SHARPENED % GameTexts.boon_name(sharpened))
		[&"weaver_lady", 0]:
			run.feathers -= tuning.encounter_weaver_price
			boon_screen.open(Boons.deal(run.rng, run.boons, _boon_offer(), tuning, Boons.RARE), GameTexts.ENCOUNTER_NAMES[_encounter])
			return
		[&"weaver_lady", 1]:
			hero.groove.add(hero.groove.maximum)
		[&"echo_spirit", 0]:
			boon_screen.open(Boons.deal(run.rng, run.boons, _boon_offer(), tuning, Boons.COMMON, &"", true), GameTexts.ENCOUNTER_NAMES[_encounter])
			return
		[&"echo_spirit", 1]:
			Game.take_boon(&"echo")
		[&"mute_tree", 0]:
			boon_screen.open(Boons.deal(run.rng, run.boons, _boon_offer(), tuning, Boons.RARE, Boons.SEVE), GameTexts.ENCOUNTER_NAMES[_encounter])
			return
		[&"mute_tree", 1]:
			hero.health.heal(hero.health.maximum * tuning.encounter_tree_heal)
	if boon:
		boon_screen.open(Boons.deal(run.rng, run.boons, _boon_offer(), tuning))
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
	hud.show_banner(GameTexts.GUARDIAN_NAMES.get(Game.run.region, GameTexts.ROOM_BOSS_TITLE) if Game.run else GameTexts.ROOM_BOSS_TITLE, GameTexts.RUN_WON, "")
	get_tree().create_timer(tuning.night_summary_delay, false).timeout.connect(end_sortie.bind(&"won"))


func _on_hero_fainted() -> void:
	if not in_sortie or _ending:
		return
	_ending = true
	if Game.run and Game.run.is_boss_room():
		for node: Node in get_tree().get_nodes_in_group(&"muets"):
			var muet: Muet = node as Muet
			if muet.is_boss() and not muet.is_freed():
				Game.run.boss_left = muet.health.current / muet.health.maximum
	hud.show_toast(GameTexts.TOAST_FAINT)
	get_tree().create_timer(Tuning.data.faint_summary_delay, false).timeout.connect(end_sortie.bind(&"faint"))


## Dons proposés à chaque offre (l'autel des esprits en ajoute un).
func _boon_offer() -> int:
	return Tuning.data.boon_offer + Village.extra_boons(Game.profile)


## Ce qui a touché le héros en dernier (le Chef en parle s'il est tombé).
func _on_hero_hurt(hit: HitData) -> void:
	if not in_sortie or Game.run == null:
		return
	var source: Node = hit.attacker
	while source and not source is Muet and not source is BeatTrap:
		source = source.get_parent()
	if source is Muet:
		Game.run.fallen_to = (source as Muet).species
	elif source is BeatTrap:
		Game.run.fallen_to = &"trap"


## On entre au village à pied : le Chef, les danseurs, les chantiers, le passage du nord.
func enter_village() -> void:
	var tuning: TuningData = Tuning.data
	in_village = true
	in_sortie = false
	get_tree().call_group(&"title_screen", &"close")
	hero.reads_player_input = true
	hud.visible = true
	touch_controls.visible = true
	_place_hero()
	_populate_village()
	_add_gate(&"depart", WorldGen.gap_point(0.0, _radius - tuning.room_exit_inset / _unit))
	Rhythm.set_layers(mini(1 + Village.built_count(Game.profile), Rhythm.NIGHT_LAYERS.size()))
	Rhythm.set_band(Village.band_floor(Game.profile, tuning))
	_chief_lines = Village.chief_lines(Game.last_summary, Game.profile, tuning)
	_line_left = 0.0
	_plot_near = &""
	if Game.last_summary.get(&"kind", &"") == &"won":
		mood.burst()
	Game.last_summary = {}


## Le Chef devant le feu, les danseurs autour (un de plus par case rebâtie), un repère par case.
func _populate_village() -> void:
	var tuning: TuningData = Tuning.data
	for node: Node in pickups.get_children():
		node.queue_free()
	_plot_marks.clear()
	var fire: Node3D = _campfire()
	pickups.add_child(fire)
	var south: float = EnemyMath.yaw_of(Vector3.BACK)
	_chief = Villager.new()
	_chief.is_chief = true
	_chief.position = Vector3(WorldGen.VILLAGE_CHIEF.x, 0.0, WorldGen.VILLAGE_CHIEF.y) * _unit
	pickups.add_child(_chief)
	_chief.setup(VoxelStyles.chief(), "village_chief", tuning.chief_scale, south, 0.0, INF, character_material, character_shadow_material, tuning.chief_shadow_radius)
	var won: bool = Game.last_summary.get(&"kind", &"") == &"won"
	var count: int = tuning.village_dancers + Village.built_count(Game.profile)
	for i: int in count:
		var a: float = PI * 0.25 + TAU * i / count
		var p := Vector2(cos(a), sin(a)) * (WorldGen.VILLAGE_FIRE_CLEAR + VILLAGE_DANCE_RING)
		var dancer := Villager.new()
		dancer.position = Vector3(p.x, 0.0, p.y) * _unit
		pickups.add_child(dancer)
		dancer.setup(VoxelStyles.dancer(i), "village_dancer_%d" % i, 1.0, EnemyMath.yaw_of(Vector3(-p.x, 0.0, -p.y)), float(i) / count, tuning.village_party_flip * (1 + i) if won else INF, character_material, character_shadow_material, tuning.villager_shadow_radius)
	var places: Dictionary[StringName, Vector2] = WorldGen.VILLAGE_PLOTS.duplicate()
	places[RACK] = WorldGen.VILLAGE_RACK
	places[PACT_STONE] = WorldGen.VILLAGE_PACTS
	for id: StringName in places:
		var p: Vector2 = places[id]
		var mark := Node3D.new()
		mark.name = "Plot_%s" % id
		mark.position = Vector3(p.x, 0.0, p.y) * _unit
		pickups.add_child(mark)
		_plot_marks[id] = mark


## Au village : le Chef dit ses répliques l'une après l'autre ; une case parle quand on s'en approche.
func _process_village(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_line_left -= delta
	if _line_left <= 0.0 and not _chief_lines.is_empty() and is_instance_valid(_chief):
		hud.show_bubble(_chief_lines[0], _chief, tuning.chief_height + tuning.reply_gap, tuning.village_line_time)
		_chief.greet()
		_chief_lines.remove_at(0)
		_line_left = tuning.village_line_time + tuning.message_fade_time
	if boon_screen.is_open():
		return
	var at := Vector2(hero.global_position.x, hero.global_position.z)
	if _plot_near != &"":
		var mark: Node3D = _plot_marks.get(_plot_near)
		if mark == null or at.distance_to(Vector2(mark.global_position.x, mark.global_position.z)) > tuning.village_plot_radius + tuning.village_plot_leave:
			_plot_near = &""
		return
	for id: StringName in _plot_marks:
		var mark: Node3D = _plot_marks[id]
		if at.distance_to(Vector2(mark.global_position.x, mark.global_position.z)) < tuning.village_plot_radius:
			_plot_near = id
			_talk_to_plot(id)
			return


## Une case : rebâtie et au rang maximal, elle dit ce qu'elle fait ; sinon, on peut la rebâtir.
func _talk_to_plot(id: StringName) -> void:
	var tuning: TuningData = Tuning.data
	if id == PACT_STONE or id == RACK:
		# Version 3.3 : le râtelier et la pierre des pactes ouvrent la page de départ.
		_open_depart()
		return
	var profile: Profile = Game.profile
	var price: int = Village.cost(profile, id, tuning)
	var level: int = Village.rank(profile, id)
	var spring: int = roundi(tuning.village_spring_health)
	if price < 0:
		hud.show_bubble(GameTexts.BUILDING_LINES[id].replace("%d", str(spring * level)), _plot_marks[id], tuning.villager_bubble_height)
		return
	var text: String = GameTexts.BUILDING_TEXTS[id].replace("%d", str(spring))
	if level > 0:
		text = GameTexts.BUILDING_LINES[id].replace("%d", str(spring * level))
	var build: String = GameTexts.BUILD_CHOICE % price if level == 0 else GameTexts.BUILD_MORE % [level + 1, price]
	if not Village.can_build(profile, id, tuning):
		build += " · " + GameTexts.BUILD_MISSING % (price - profile.feathers)
	boon_screen.open_choices(GameTexts.BUILDING_NAMES[id], text, PackedStringArray([build, GameTexts.BUILD_LATER]), [Village.can_build(profile, id, tuning), true] as Array[bool])


## Rebâtir (choix 0) : les plumes partent, la case surgit en couleurs, le village s'anime.
func _on_build_choice(index: int) -> void:
	var tuning: TuningData = Tuning.data
	var id: StringName = _plot_near
	if index != 0 or id == &"" or not Village.build(Game.profile, id, tuning):
		return
	Game.refresh_stats()
	Game.stats_changed.emit()
	hero.health.restore()
	Game.save()
	var mark: Node3D = _plot_marks.get(id)
	var at: Vector3 = mark.global_position if mark else Vector3.ZERO
	# Le héros recule un peu : la case rebâtie est plus large que le chantier.
	var away: Vector3 = (hero.global_position - at) * Vector3(1.0, 0.0, 1.0)
	hero.global_position = at + (away.normalized() if not away.is_zero_approx() else Vector3.BACK) * (tuning.village_plot_radius + tuning.village_plot_leave * 0.5)
	hero.reset_physics_interpolation()
	gen.village_built = Game.profile.village.duplicate()
	gen.generate_room(next_seed, _radius, PackedFloat32Array([0.0]), &"village")
	world.build(gen)
	_populate_village()
	_add_gate(&"depart", WorldGen.gap_point(0.0, _radius - tuning.room_exit_inset / _unit))
	Rhythm.set_layers(mini(1 + Village.built_count(Game.profile), Rhythm.NIGHT_LAYERS.size()))
	Rhythm.set_band(Village.band_floor(Game.profile, tuning))
	var fx: Effects = Effects.of(self)
	if fx:
		fx.burst(at + Vector3.UP * tuning.hero_height, tuning.fx_rainbow_cubes, tuning.fx_rainbow_speed)
		fx.ring(at, tuning.fx_level_ring, fx.gold, tuning.fx_level_ring_time, true)
	mood.pulse(tuning.rainbow_world_pulse)
	hud.show_toast(GameTexts.BUILD_DONE % GameTexts.BUILDING_NAMES[id])


## La page « Préparer l'expédition » (région, instrument, pactes ; version 3.3).
func _open_depart() -> void:
	var screen: Node = get_tree().get_first_node_in_group(&"depart_screen")
	if screen == null:
		_depart()
		return
	get_tree().paused = true
	hero.input_move = Vector2.ZERO
	screen.call(&"open", func() -> void:
		get_tree().paused = false
		_reopen_gate())


## « Partir » depuis la page de départ : du village (fondu), ou de l'écran titre.
func depart_from_screen() -> void:
	get_tree().paused = false
	if in_village:
		_depart()
	else:
		start_sortie()


## Revenu au village sans partir : le passage du nord peut reservir.
func _reopen_gate() -> void:
	for node: Node in pickups.get_children():
		if node is ExitGate:
			node.queue_free()
	_add_gate(&"depart", WorldGen.gap_point(0.0, _radius - Tuning.data.room_exit_inset / _unit))


## Le passage du nord : on part en expédition (fondu au noir).
func _depart() -> void:
	var tuning: TuningData = Tuning.data
	hero.reads_player_input = false
	hero.input_move = Vector2.ZERO
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", 1.0, tuning.room_fade_time)
	tween.tween_callback(start_sortie)
	tween.tween_property(_fade, "color:a", 0.0, tuning.room_fade_time)


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
