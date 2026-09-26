class_name GongCircle
extends Node3D
## Cercle des gongs : quand le héros y entre, les gongs jouent une mélodie au rythme ; la rejouer
## dans l'ordre (en les frappant) fait jaillir un coffre au centre. Une erreur fait rejouer la
## mélodie un peu plus tard. Si la page du coffre est déjà dans le carnet, le cercle est résolu
## d'avance et le coffre attend, ouvert.

enum Phase { WAITING, DEMO, LISTENING, SOLVED }

## Gongs à frapper, dans l'ordre (numéros des gongs).
@export var melody: PackedInt32Array
@export var gongs: Array[Gong]
## Coffre caché au centre, révélé quand la mélodie est rejouée.
@export var chest: Node3D
## Temps d'attente avant de jouer (ou rejouer) la mélodie.
@export var wait_beats: int

var phase: Phase = Phase.WAITING

var _melody: GongMelody
var _hero_inside: bool = false
var _demo_step: int = 0
var _beats_left: int = 0

@onready var _zone: Area3D = $Zone


## Cercle de `semitones.size()` gongs (leurs notes) à `radius` m du centre, dans une zone de
## `zone_radius` m ; le coffre caché au centre garde la page `page`.
static func create(gong_scene: PackedScene, chest_scene: PackedScene, tune: PackedInt32Array, semitones: PackedFloat32Array, radius: float, zone_radius: float, page: int, wait: int) -> GongCircle:
	var circle := GongCircle.new()
	circle.name = "GongCircle"
	var zone := Area3D.new()
	zone.name = "Zone"
	zone.collision_layer = 0
	zone.collision_mask = 2
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = zone_radius
	cylinder.height = zone_radius
	shape.shape = cylinder
	zone.add_child(shape)
	circle.add_child(zone)
	var list: Array[Gong] = []
	for i: int in semitones.size():
		var gong: Gong = gong_scene.instantiate() as Gong
		gong.name = "Gong%d" % (i + 1)
		gong.index = i
		gong.semitones = semitones[i]
		var direction: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, TAU * i / semitones.size())
		gong.position = direction * radius
		# Tourné vers le centre, le disque face au héros qui arrive au milieu.
		gong.rotation.y = atan2(direction.x, direction.z)
		circle.add_child(gong)
		list.append(gong)
	var chest: Node3D = chest_scene.instantiate() as Node3D
	chest.set(&"page", page)
	chest.set(&"hidden", not Game.profile.has_page(page))
	circle.add_child(chest)
	circle.melody = tune
	circle.gongs = list
	circle.chest = chest
	circle.wait_beats = wait
	return circle


func _ready() -> void:
	_melody = GongMelody.new(melody)
	_beats_left = wait_beats
	if chest and chest.visible and not bool(chest.get(&"hidden")) and Game.profile.has_page(int(chest.get(&"page"))):
		phase = Phase.SOLVED
	for gong: Gong in gongs:
		gong.struck.connect(_on_struck)
	_zone.body_entered.connect(func(body: Node3D) -> void: _hero_inside = _hero_inside or body is Hero)
	_zone.body_exited.connect(_on_body_exited)
	Rhythm.beat.connect(receive_beat)


## Un temps de la musique (appelé directement dans les tests).
func receive_beat(_index: int) -> void:
	match phase:
		Phase.WAITING:
			if not _hero_inside:
				return
			_beats_left -= 1
			if _beats_left <= 0:
				_demo_step = 0
				phase = Phase.DEMO
		Phase.DEMO:
			_gong(melody[_demo_step]).ring()
			_demo_step += 1
			if _demo_step >= melody.size():
				_melody.reset()
				phase = Phase.LISTENING


func _on_struck(gong: Gong) -> void:
	if phase != Phase.LISTENING:
		return
	match _melody.strike(gong.index):
		GongMelody.Result.WRONG:
			for each: Gong in gongs:
				each.flash_error()
			_beats_left = wait_beats
			phase = Phase.WAITING
		GongMelody.Result.COMPLETE:
			phase = Phase.SOLVED
			for each: Gong in gongs:
				each.ring()
			chest.call(&"reveal")


func _on_body_exited(body: Node3D) -> void:
	if body is Hero and phase != Phase.SOLVED:
		_hero_inside = false
		_beats_left = wait_beats
		phase = Phase.WAITING


func _gong(index: int) -> Gong:
	for gong: Gong in gongs:
		if gong.index == index:
			return gong
	return null
