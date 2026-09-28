class_name CalibrationScreen
extends ScreenLayer
## Calibration du son (version 2.9) : la musique continue ; on touche le grand tambour sur chaque
## temps. Après Tuning.calibration_taps appuis, le décalage médian entre les appuis et les temps
## devient Profile.audio_offset (le rythme du jeu en tient compte : Rhythm.song_time). Le tambour
## bat sur le temps corrigé, pour vérifier à l'œil et à l'oreille.

## Taille du tambour qui bat (part en plus sur le temps).
@export var pulse_scale: float = 0.12

var _offsets := PackedFloat32Array()

@onready var _tap: Button = %Tap
@onready var _count: Label = %Count
@onready var _result: Label = %Result


func _ready() -> void:
	super()
	add_to_group(&"calibration_screen")
	%Title.text = GameTexts.CALIBRATE_TITLE
	%Help.text = GameTexts.CALIBRATE_HELP
	_tap.text = GameTexts.CALIBRATE_TAP
	%Reset.text = GameTexts.CALIBRATE_RESET
	%Back.text = GameTexts.CALIBRATE_DONE
	_tap.button_down.connect(_on_tap)
	%Reset.pressed.connect(_on_reset)
	%Back.pressed.connect(go_back)


## Ouvre la calibration ; « Terminé » appelle `back`.
func open(back: Callable = Callable()) -> void:
	back_action = back
	_offsets.clear()
	_show()
	show_screen()


func _process(_delta: float) -> void:
	if not visible or not Rhythm.is_playing():
		return
	_tap.pivot_offset = _tap.size / 2.0
	var beat: float = exp(-Rhythm.beat_phase() * Tuning.data.world_beat_decay)
	_tap.scale = Vector2.ONE * (1.0 + pulse_scale * beat)


## Un appui : son écart au temps le plus proche (sans la calibration en cours).
func _on_tap() -> void:
	if not Rhythm.is_playing():
		return
	var tuning: TuningData = Tuning.data
	_offsets.append(RhythmMath.beat_offset(Rhythm.raw_song_time(), Rhythm.beat_length()))
	if _offsets.size() >= tuning.calibration_taps:
		Game.profile.audio_offset = measured_offset(_offsets, tuning)
		Game.save()
		_offsets.clear()
	_show()


func _on_reset() -> void:
	Game.profile.audio_offset = 0.0
	Game.save()
	_offsets.clear()
	_show()


func _show() -> void:
	_count.text = GameTexts.CALIBRATE_COUNT % [_offsets.size(), Tuning.data.calibration_taps]
	_result.text = GameTexts.CALIBRATE_RESULT % roundi(Game.profile.audio_offset * 1000.0)


## Décalage mesuré : la médiane des écarts (un appui raté compte peu), bornée.
static func measured_offset(offsets: PackedFloat32Array, tuning: TuningData) -> float:
	if offsets.is_empty():
		return 0.0
	var sorted: PackedFloat32Array = offsets.duplicate()
	sorted.sort()
	var middle: int = sorted.size() / 2
	var median: float = sorted[middle] if sorted.size() % 2 == 1 else (sorted[middle - 1] + sorted[middle]) / 2.0
	return clampf(median, -tuning.calibration_max, tuning.calibration_max)
