class_name VillageBand
extends Node3D
## Les Muets libérés cette nuit rejoignent le village : plus petits, ils ont retrouvé leurs
## couleurs et dansent autour de la place, en bondissant un temps sur deux (les volants planent) ; les Grands Muets
## aussi, avec leur couronne. Un nouveau venu apparaît dès sa libération. Leur nombre est plafonné
## (Tuning.village_band_max) ; loin du héros, ils ne bougent plus.

## Angle d'or : les places se répartissent tout autour de la place, même avec peu de Muets.
const GOLDEN_ANGLE := 2.399963
## Forme du corps de chaque espèce (MuetShapes), et les Grands Muets.
const KINDS := {
	&"hopper": &"hop", &"flyer": &"fly", &"shielder": &"shield", &"charger": &"charge",
	&"spitter": &"spit", &"boss": &"hop", &"king": &"hop",
}

## Matériau des assemblages articulés (voxel_rig.tres) et des ombres rondes.
@export var material: ShaderMaterial
@export var shadow_material: Material

var _spots := PackedVector2Array()
var _figures: Array[MuetBody] = []
var _flying: Array[bool] = []
var _hero: Node3D
var _awake: bool = true


## Places (u) des `count` premiers Muets de la troupe, sur les cercles `rings` (u) : l'angle d'or
## les répartit ; `blocked` (Callable(Vector2) -> bool) écarte les places prises par le décor.
static func spots(count: int, rings: PackedFloat32Array, blocked: Callable) -> PackedVector2Array:
	var list := PackedVector2Array()
	var i: int = 0
	var tries: int = count * rings.size() * 8
	while list.size() < count and i < tries:
		var radius: float = rings[i % rings.size()]
		var angle: float = i * GOLDEN_ANGLE
		var p := Vector2(cos(angle), sin(angle)) * radius
		i += 1
		if not blocked.call(p):
			list.append(p)
	return list


## Prépare la troupe : places (m, dans le plan du sol) et Muets déjà libérés cette nuit.
func setup(places: PackedVector2Array, species: Array[StringName]) -> void:
	_spots = places
	for kind: StringName in species:
		join(kind, false)
	Game.band_joined.connect(func(kind: StringName) -> void: join(kind, true))


## Un Muet de l'espèce `species` (&"boss", &"king" : Grand Muet, Roi Muet) rejoint la troupe ;
## `pop` : il apparaît en grandissant.
func join(species: StringName, pop: bool) -> void:
	var index: int = _figures.size()
	if index >= _spots.size() or not KINDS.has(species):
		return
	var tuning: TuningData = Tuning.data
	var stats: StringName = &"boss" if species == &"king" else species
	var body := MuetBody.new()
	body.name = "Muet%d" % (index + 1)
	body.kind = KINDS[species]
	body.boss = stats == &"boss"
	body.king = species == &"king"
	body.material = material
	body.shadow_material = shadow_material
	var p: Vector2 = _spots[index]
	body.position = Vector3(p.x, 0.0, p.y)
	add_child(body)
	var size: float = tuning.village_band_scale
	body.setup(float(tuning.get("%s_scale" % stats)) * size * tuning.voxel_unit, float(tuning.get("%s_radius" % stats)) * size)
	body.show_healed()
	# Tourné vers le centre de la place.
	body.target_yaw = atan2(-p.x, -p.y)
	body.rotation.y = body.target_yaw
	_figures.append(body)
	_flying.append(body.kind == &"fly")
	if pop:
		body.scale = Vector3.ZERO
		create_tween().tween_property(body, "scale", Vector3.ONE, tuning.village_band_pop_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Nombre de Muets dans la troupe.
func count() -> int:
	return _figures.size()


func _ready() -> void:
	Rhythm.beat.connect(_on_beat)


func _process(_delta: float) -> void:
	var tuning: TuningData = Tuning.data
	if not is_instance_valid(_hero):
		_hero = get_tree().get_first_node_in_group(&"hero") as Node3D
	var near: bool = _hero == null or _hero.global_position.distance_to(global_position) < tuning.muet_sleep_distance + tuning.village_radius
	if near != _awake:
		_awake = near
		for body: MuetBody in _figures:
			body.process_mode = Node.PROCESS_MODE_INHERIT if near else Node.PROCESS_MODE_DISABLED
	if not _awake:
		return
	var beat: int = floori(Rhythm.song_time() / Rhythm.beat_length()) if Rhythm.is_playing() else 0
	var hop: float = sin(PI * Rhythm.beat_phase()) * tuning.village_band_hop if Rhythm.is_playing() else 0.0
	for i: int in _figures.size():
		var y: float = tuning.village_band_fly_height if _flying[i] else 0.0
		if (beat + i) % 2 == 0:
			y += hop
		_figures[i].position.y = y


## Un temps sur deux, chacun retombe à son tour : rebond de gelée.
func _on_beat(index: int) -> void:
	if not _awake:
		return
	for i: int in _figures.size():
		if (index + i) % 2 == 1 and not _flying[i]:
			_figures[i].squash(-Tuning.data.village_band_squash)
