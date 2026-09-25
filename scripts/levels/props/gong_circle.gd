extends Node3D
## Cercle des gongs : quand le héros y entre, les gongs jouent une mélodie au rythme ; la rejouer
## dans l'ordre (en les frappant) fait jaillir un coffre au centre. Une erreur fait rejouer la
## mélodie un peu plus tard.

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


func _ready() -> void:
	_melody = GongMelody.new(melody)
	_beats_left = wait_beats
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
