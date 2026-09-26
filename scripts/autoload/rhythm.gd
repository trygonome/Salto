extends Node
## Horloge musicale. Joue la musique en couches, toutes synchronisées : la base est toujours
## audible et chaque tambour rapporté en ajoute une ; la troupe du village (Muets libérés qui
## chantent et tapent dans leurs mains) a sa couche à elle, plus ou moins forte (set_band). Donne la position exacte dans la musique,
## corrigée de la latence audio (méthode documentée par Godot : position de lecture + temps
## depuis le dernier mixage − latence de sortie), et émet `beat` à chaque temps (sauf pendant
## une pause du jeu).

## Un nouveau temps commence (numéro depuis le début de la musique).
signal beat(index: int)

## Couches de la musique de la nuit, de la base à la dernière.
const NIGHT_LAYERS: Array[String] = [
	"res://assets/audio/music/night_0_base.wav",
	"res://assets/audio/music/night_1_drums.wav",
	"res://assets/audio/music/night_2_bass.wav",
	"res://assets/audio/music/night_3_melody.wav",
]
## Couche de la troupe du village.
const BAND_LAYER := "res://assets/audio/music/night_band.wav"

var _player := AudioStreamPlayer.new()
var _music: AudioStreamSynchronized
var _loop_length: float = 0.0
var _loops: int = 0
var _last_position: float = 0.0
var _last_beat: int = -1
var _audible_layers: int = 0
var _band: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)


## Lance la musique de la nuit avec `layers` couches audibles (au moins la base).
func play(layers: int) -> void:
	var tuning: TuningData = Tuning.data
	_music = AudioStreamSynchronized.new()
	_music.stream_count = NIGHT_LAYERS.size() + 1
	for i: int in NIGHT_LAYERS.size():
		_music.set_sync_stream(i, load(NIGHT_LAYERS[i]) as AudioStream)
		_music.set_sync_stream_volume(i, tuning.music_volume_db if i < layers else tuning.music_silent_db)
	_music.set_sync_stream(NIGHT_LAYERS.size(), load(BAND_LAYER) as AudioStream)
	_music.set_sync_stream_volume(NIGHT_LAYERS.size(), band_volume_db(_band, tuning))
	_loop_length = _music.get_sync_stream(0).get_length()
	_audible_layers = layers
	_loops = 0
	_last_position = 0.0
	_last_beat = -1
	_player.stream = _music
	_player.play()


func stop() -> void:
	_player.stop()


func _exit_tree() -> void:
	# Libère la lecture en cours : sinon le serveur audio la garde jusqu'à l'arrêt du moteur.
	_player.stop()
	_player.stream = null
	_music = null


func is_playing() -> bool:
	return _player.playing


## Nombre de couches audibles.
func audible_layers() -> int:
	return _audible_layers


## Rend `count` couches audibles (les autres se taisent), en fondu.
func set_layers(count: int) -> void:
	var tuning: TuningData = Tuning.data
	_audible_layers = count
	if _music == null:
		return
	for i: int in NIGHT_LAYERS.size():
		var target: float = tuning.music_volume_db if i < count else tuning.music_silent_db
		var set_volume: Callable = func(db: float) -> void: _music.set_sync_stream_volume(i, db)
		create_tween().tween_method(set_volume, _music.get_sync_stream_volume(i), target, tuning.music_layer_fade_time)


## Fait entendre la troupe du village à `amount` (0 : muette, 1 : pleine voix).
func set_band(amount: float) -> void:
	_band = clampf(amount, 0.0, 1.0)
	if _music:
		_music.set_sync_stream_volume(NIGHT_LAYERS.size(), band_volume_db(_band, Tuning.data))


func band_amount() -> float:
	return _band


## Volume (dB) de la troupe pour `amount` (0 à 1) : muette à 0, comme les autres couches à 1.
static func band_volume_db(amount: float, tuning: TuningData) -> float:
	if amount <= 0.0:
		return tuning.music_silent_db
	return maxf(tuning.music_silent_db, tuning.music_volume_db + linear_to_db(amount))


## Temps écoulé dans la musique depuis son début (s), tel qu'on l'entend.
func song_time() -> float:
	_follow_loops()
	var position: float = _player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	return _loops * _loop_length + position


## Durée d'un temps (s).
func beat_length() -> float:
	return RhythmMath.beat_length(Tuning.data)


## Avancée dans le temps en cours (0 = sur le temps) ; 0 si la musique ne joue pas.
func beat_phase() -> float:
	return RhythmMath.beat_phase(song_time(), beat_length()) if is_playing() else 0.0


## Jugement d'un appui fait maintenant (raté si la musique ne joue pas) ; `window` élargit la
## fenêtre du coup Parfait (Métronome).
func judge_now(window: float = 1.0) -> RhythmMath.Judgement:
	if not is_playing():
		return RhythmMath.Judgement.MISS
	return RhythmMath.judge(RhythmMath.beat_offset(song_time(), beat_length()), Tuning.data, window)


func _process(_delta: float) -> void:
	if not is_playing():
		return
	var index: int = floori(song_time() / beat_length())
	if get_tree().paused:
		# La musique continue pendant la pause, mais le monde arrêté ne reçoit pas de temps.
		_last_beat = index
		return
	while _last_beat < index:
		_last_beat += 1
		beat.emit(_last_beat)


## Compte les tours de boucle : la position de lecture revient au début à chaque tour.
func _follow_loops() -> void:
	var raw: float = _player.get_playback_position()
	if raw < _last_position - _loop_length / 2.0:
		_loops += 1
	_last_position = raw
