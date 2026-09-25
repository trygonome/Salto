class_name VoxelNight
extends Node3D
## Une nuit dans le monde voxel du prototype : génère le monde de la nuit (graine gardée d'une
## sortie à l'autre), pose le village et les trois sanctuaires (autel, tambour dans sa bulle,
## Grand Muet gardien), les Muets qui les gardent et les errants, suit l'objectif (chemin doré)
## et lance la musique.

## Numéro de la nuit (1 à 5).
@export var night: int
@export var hopper_scene: PackedScene
@export var flyer_scene: PackedScene
@export var boss_scene: PackedScene
## Tambour d'un sanctuaire (dans sa bulle jusqu'à la libération du gardien).
@export var drum_scene: PackedScene
## Objet laissé par chaque Grand Muet.
@export var loot_scene: PackedScene
## Matériau des personnages voxel et de leurs ombres rondes.
@export var character_material: Material
@export var character_shadow_material: Material

## Espèces qui gardent les sanctuaires la nuit 1 (tirées au hasard, comme dans le prototype).
const NIGHT_ONE_FOES: Array[StringName] = [&"hopper", &"hopper", &"hopper", &"flyer"]

var gen := WorldGen.new()
var drums: Array[Node3D] = []
## Sanctuaire d'où vient le premier tambour porté (-1 : aucun).
var carried_from: int = -1

var _rng := RandomNumberGenerator.new()
var _freed: Array[bool] = [false, false, false]
var _unit: float = 0.0

@onready var world: WorldBuilder = $World
@onready var mood: WorldMood = $Mood
@onready var hero: Hero = $Hero
@onready var foes: Node3D = $Foes
@onready var village: Node3D = $Village


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	_unit = tuning.voxel_unit
	_rng.randomize()
	Game.start_night(night)
	gen.generate(Game.world_seed(), Game.profile.nights_done)
	world.build(gen)
	mood.set_sanctuaries(gen.sanctuaries, _freed)
	_place_villagers()
	_add_shadow(hero, tuning.hero_shadow_radius)
	for i: int in gen.sanctuaries.size():
		_place_sanctuary(i)
	for i: int in tuning.muet_wanderers:
		_spawn_wanderer()
	Game.drum_picked.connect(_on_drum_picked)
	Game.drum_dropped.connect(func() -> void: carried_from = -1)
	Game.drum_returned.connect(func(_count: int) -> void: carried_from = -1)
	Game.night_completed.connect(func() -> void: mood.set_won(true))
	Rhythm.play(Game.music_layers())


func _exit_tree() -> void:
	Rhythm.stop()


func _process(_delta: float) -> void:
	_update_objective()


## Objectif du moment, comme dans le prototype : rapporter le tambour porté, sinon aller prendre
## un tambour libéré, sinon libérer le prochain sanctuaire. Renvoie l'indice du sanctuaire
## concerné et le sens (vers le sanctuaire ou vers le village), ou -1.
func objective() -> Vector2i:
	if Game.progress.is_complete():
		return Vector2i(-1, 0)
	if Game.progress.carrying_drum:
		return Vector2i(maxi(carried_from, 0), -1)
	for i: int in drums.size():
		if (drums[i].call(&"is_available") as bool):
			return Vector2i(i, 1)
	for i: int in _freed.size():
		if not _freed[i]:
			return Vector2i(i, 1)
	return Vector2i(-1, 0)


## Point du monde en mètres pour un point du prototype (u).
func to_world(p: Vector2) -> Vector3:
	return Vector3(p.x * _unit, 0.0, p.y * _unit)


func _update_objective() -> void:
	var goal: Vector2i = objective()
	if goal.x < 0:
		mood.clear_target()
	else:
		mood.set_target(gen.sanctuaries[goal.x], goal.y > 0)


## Les six danseurs autour de la place, tournés vers le centre, et le Chef Taroum devant les tambours.
func _place_villagers() -> void:
	var tuning: TuningData = Tuning.data
	for i: int in WorldGen.DANCERS.size():
		var p: Vector2 = WorldGen.DANCERS[i]
		var dancer := Villager.new()
		dancer.name = "Dancer%d" % (i + 1)
		dancer.position = to_world(p)
		village.add_child(dancer)
		dancer.setup(VoxelStyles.dancer(i), 1.0, atan2(-p.x, -p.y), i * tuning.villager_phase_step,
			tuning.villager_first_flip + i * tuning.villager_first_flip_step, character_material, character_shadow_material, tuning.villager_shadow_radius)
	var chief := Villager.new()
	chief.name = "Chief"
	chief.is_chief = true
	chief.position = to_world(WorldGen.CHIEF)
	village.add_child(chief)
	chief.setup(VoxelStyles.chief(), tuning.chief_scale, 0.0, tuning.chief_phase, INF, character_material, character_shadow_material, tuning.chief_shadow_radius)


func _add_shadow(target: Node3D, radius: float) -> void:
	var shadow := BlobShadow.new()
	shadow.name = "Shadow"
	shadow.radius = radius
	shadow.material = character_shadow_material
	target.add_child(shadow)


## Autel : tambour dans sa bulle, Grand Muet entre le village et l'autel, gardiens autour.
func _place_sanctuary(index: int) -> void:
	var s: Vector2 = gen.sanctuaries[index]
	var boss: EnemySpawner = _spawner(boss_scene, s - s.normalized() * Tuning.data.sanctuary_boss_distance / _unit, false)
	boss.loot_scene = loot_scene
	boss.muet_freed.connect(func(_muet: Muet) -> void: _on_sanctuary_freed(index))
	var drum: Node3D = drum_scene.instantiate() as Node3D
	drum.set(&"guardian", boss)
	drum.position = to_world(s) + Vector3.UP * WorldGen.ALTAR_HEIGHT * _unit
	add_child(drum)
	drums.append(drum)
	var count: int = Tuning.data.sanctuary_guards + index
	var placed: int = 0
	var tries: int = 0
	while placed < count and tries < Tuning.data.spawn_tries:
		tries += 1
		var a: float = float(placed) / count * TAU + _rng.randf() * Tuning.data.spawn_angle_jitter
		var r: float = _rng.randf_range(Tuning.data.sanctuary_guard_min, Tuning.data.sanctuary_guard_max) / _unit
		var p: Vector2 = s + Vector2(cos(a), sin(a)) * r
		if _blocked(p, Tuning.data.spawn_clearance / _unit):
			continue
		_spawner(_foe_scene(), p, false)
		placed += 1


func _spawn_wanderer() -> void:
	var tuning: TuningData = Tuning.data
	for t: int in tuning.spawn_tries:
		var a: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(tuning.wanderer_min_distance, tuning.wanderer_max_distance) / _unit
		var p := Vector2(cos(a), sin(a)) * r
		var start := Vector2(hero.global_position.x, hero.global_position.z) / _unit
		if gen.near_sanctuary(p, tuning.wanderer_sanctuary_clearance / _unit) or p.distance_to(start) < tuning.wanderer_hero_clearance / _unit:
			continue
		if _blocked(p, tuning.spawn_clearance / _unit):
			continue
		_spawner(_foe_scene(), p, true)
		return


func _foe_scene() -> PackedScene:
	return hopper_scene if NIGHT_ONE_FOES[_rng.randi_range(0, NIGHT_ONE_FOES.size() - 1)] == &"hopper" else flyer_scene


func _spawner(scene: PackedScene, p: Vector2, wanderer: bool) -> EnemySpawner:
	var spawner := EnemySpawner.new()
	spawner.scene = scene
	spawner.position = to_world(p)
	spawner.wanderer = wanderer
	spawner.safe_zone_radius = Tuning.data.village_radius
	foes.add_child(spawner)
	return spawner


func _blocked(p: Vector2, margin: float) -> bool:
	for s: WorldGen.Solid in gen.solids:
		if Vector2(p.x - s.x, p.y - s.z).length() < s.r + margin:
			return true
	return false


func _on_sanctuary_freed(index: int) -> void:
	_freed[index] = true
	mood.free_sanctuary(index)


func _on_drum_picked() -> void:
	if carried_from >= 0:
		return
	var nearest: float = INF
	for i: int in gen.sanctuaries.size():
		var d: float = to_world(gen.sanctuaries[i]).distance_to(hero.global_position)
		if d < nearest:
			nearest = d
			carried_from = i
