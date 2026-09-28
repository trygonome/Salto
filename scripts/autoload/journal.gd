extends Node
## Journal de jeu (version 4.2.1) : ce qui se passe pendant les parties, gardé sur l'appareil (rien
## n'est envoyé sur Internet) pour équilibrer le jeu avec de vraies données. Un fichier par séance
## (JSON, une ligne par évènement) : l'appareil, chaque expédition, chaque clairière (durée, PV,
## coups portés et reçus, danses, groove, images par seconde, temps de génération), les choix
## (passages, dons, rencontres, talents) et les erreurs du moteur. Réglages > « Copier le journal »
## met un résumé lisible dans le presse-papiers, à coller dans la conversation.
##
## Les évènements rares s'écrivent un par un ; les fréquents (coups, appuis…) s'additionnent dans
## des compteurs, rendus avec leur clairière.

## Dossier des journaux ; faux : rien n'est noté (les tests le coupent).
var directory: String = "user://journal"
var enabled: bool = true

var _path: String = ""
var _start_usec: int = 0
var _lines := PackedStringArray()
var _flush_left: float = 0.0
## Clairière en cours : ses données, ses compteurs, ses images.
var _room: Dictionary = {}
var _counters: Dictionary[String, float] = {}
var _perf := {}
var _logger: JournalLogger
var _error_counts: Dictionary[String, int] = {}
var _errors_dirty: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_perf = _new_perf()
	_logger = JournalLogger.new()
	OS.add_logger(_logger)


func _exit_tree() -> void:
	if _logger:
		OS.remove_logger(_logger)
	flush()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			event(&"app_pause")
			flush()
		NOTIFICATION_APPLICATION_RESUMED:
			event(&"app_resume")
		NOTIFICATION_WM_CLOSE_REQUEST:
			event(&"quit")
			flush()


func _process(delta: float) -> void:
	if not enabled:
		return
	var tuning: TuningData = Tuning.data
	for error: Dictionary in _logger.take():
		_on_error(error, tuning)
	if not get_tree().paused and not _room.is_empty():
		_add_frame(_perf, delta, tuning)
	_flush_left -= delta
	if _flush_left <= 0.0:
		_flush_left = tuning.journal_flush_period
		flush()


## Note l'évènement `kind` et ses données.
func event(kind: StringName, data: Dictionary = {}) -> void:
	if not enabled:
		return
	_ensure_session()
	var line: Dictionary = {"t": snappedf(_seconds(), 0.1), "k": String(kind)}
	line.merge(data)
	_lines.append(JSON.stringify(line))


## Ajoute `amount` au compteur `key` de la clairière en cours (coups, appuis, danses…).
func count(key: String, amount: float = 1.0) -> void:
	if not enabled or _room.is_empty():
		return
	_counters[key] = _counters.get(key, 0.0) + amount


## Une clairière commence (la précédente, si elle est restée ouverte, se ferme « quittée »).
func begin_room(data: Dictionary) -> void:
	if not enabled:
		return
	if not _room.is_empty():
		end_room("left")
	_room = data.duplicate()
	_room["start"] = _seconds()
	_counters.clear()
	_perf = _new_perf()


## La clairière en cours se termine par `outcome` (nettoyée, gardien, chute…) ; `data` s'ajoute.
func end_room(outcome: String, data: Dictionary = {}) -> void:
	if not enabled or _room.is_empty():
		return
	var room: Dictionary = _room.duplicate()
	room.merge(data, true)
	room["outcome"] = outcome
	room["duration"] = snappedf(_seconds() - float(room["start"]), 0.1)
	room.erase("start")
	var counters: Dictionary = {}
	for key: String in _counters:
		counters[key] = snappedf(_counters[key], 0.1)
	room["c"] = counters
	room["perf"] = perf_summary(_perf)
	_room = {}
	_counters.clear()
	event(&"room", room)
	flush()


## Vrai si une clairière est en cours.
func in_room() -> bool:
	return not _room.is_empty()


## Recommence une séance dans le dossier `dir` (pour les tests).
func restart(dir: String) -> void:
	flush()
	directory = dir
	_path = ""
	_lines.clear()
	_room = {}
	_counters.clear()
	_error_counts.clear()
	_errors_dirty = false


## Écrit ce qui attend dans le fichier de la séance.
func flush() -> void:
	if not enabled or _path == "":
		return
	if _errors_dirty:
		_errors_dirty = false
		_lines.append(JSON.stringify({"t": snappedf(_seconds(), 0.1), "k": "error_counts", "counts": _error_counts.duplicate()}))
	if _lines.is_empty():
		return
	var file: FileAccess = FileAccess.open(_path, FileAccess.READ_WRITE) if FileAccess.file_exists(_path) else FileAccess.open(_path, FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	for line: String in _lines:
		file.store_line(line)
	file.close()
	_lines.clear()


## Résumé lisible des `sessions` dernières séances (les plus récentes à la fin), coupé à
## `max_chars` caractères en gardant les plus récentes.
func digest(sessions: int, max_chars: int) -> String:
	flush()
	var files: PackedStringArray = session_files()
	var parts: PackedStringArray = []
	var total: int = 0
	for i: int in range(files.size() - 1, maxi(-1, files.size() - 1 - sessions), -1):
		var text: String = JournalDigest.format(read_session(directory.path_join(files[i])))
		if total + text.length() > max_chars and not parts.is_empty():
			break
		parts.insert(0, text)
		total += text.length()
	return JournalDigest.HEADER + "\n\n" + "\n\n".join(parts)


## Nombre d'expéditions notées dans les séances gardées.
func run_count() -> int:
	flush()
	var runs: int = 0
	for file: String in session_files():
		for e: Dictionary in read_session(directory.path_join(file)):
			if e.get("k", "") == "run_start":
				runs += 1
	return runs


## Fichiers des séances, du plus ancien au plus récent.
func session_files() -> PackedStringArray:
	var files: PackedStringArray = []
	if not DirAccess.dir_exists_absolute(directory):
		return files
	for file: String in DirAccess.get_files_at(directory):
		if file.begins_with("session-") and file.ends_with(".jsonl"):
			files.append(file)
	files.sort()
	return files


## Évènements d'un fichier de séance.
static func read_session(path: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return events
	while not file.eof_reached():
		var line: String = file.get_line()
		if line.is_empty():
			continue
		var data: Variant = JSON.parse_string(line)
		if data is Dictionary:
			events.append(data)
	return events


## Images par seconde d'une fenêtre : moyenne, pire image, part d'images lentes, accrocs.
static func perf_summary(perf: Dictionary) -> Dictionary:
	var frames: int = perf["frames"]
	if frames == 0:
		return {}
	return {
		"fps": roundi(frames / maxf(float(perf["time"]), 0.001)),
		"worst_ms": roundi(float(perf["worst"]) * 1000.0),
		"slow": snappedf(float(perf["slow"]) / frames, 0.001),
		"hitches": perf["hitches"],
	}


static func _add_frame(perf: Dictionary, delta: float, tuning: TuningData) -> void:
	perf["frames"] += 1
	perf["time"] += delta
	perf["worst"] = maxf(perf["worst"], delta)
	if delta > tuning.journal_slow_frame:
		perf["slow"] += 1
	if delta > tuning.journal_hitch:
		perf["hitches"] += 1


static func _new_perf() -> Dictionary:
	return {"frames": 0, "time": 0.0, "worst": 0.0, "slow": 0, "hitches": 0}


func _seconds() -> float:
	return float(Time.get_ticks_usec() - _start_usec) / 1000000.0


## La séance commence au premier évènement : un fichier neuf, l'appareil et ses réglages.
func _ensure_session() -> void:
	if _path != "":
		return
	DirAccess.make_dir_recursive_absolute(directory)
	_prune()
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	_path = directory.path_join("session-%s.jsonl" % stamp)
	_start_usec = Time.get_ticks_usec()
	var screen: Vector2i = DisplayServer.screen_get_size()
	var profile: Profile = Game.profile
	_lines.append(JSON.stringify({
		"t": 0.0, "k": "session", "date": Time.get_datetime_string_from_system(),
		"version": ProjectSettings.get_setting("application/config/version", ""),
		"os": "%s %s" % [OS.get_name(), OS.get_version()], "model": OS.get_model_name(),
		"gpu": RenderingServer.get_video_adapter_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"screen": "%d×%d" % [screen.x, screen.y], "cpus": OS.get_processor_count(),
		"memory_gb": snappedf(float(OS.get_memory_info().get("physical", 0)) / 1073741824.0, 0.1),
		"audio_latency_ms": roundi(AudioServer.get_output_latency() * 1000.0),
		"calibration_ms": roundi(profile.audio_offset * 1000.0) if profile else 0,
		"vibration": profile.vibration if profile else true,
	}))


## Ne garde que les journal_sessions_kept dernières séances.
func _prune() -> void:
	var files: PackedStringArray = session_files()
	var extra: int = files.size() - (Tuning.data.journal_sessions_kept - 1)
	for i: int in maxi(0, extra):
		DirAccess.remove_absolute(directory.path_join(files[i]))


func _on_error(error: Dictionary, tuning: TuningData) -> void:
	var key: String = "%s:%d %s" % [error.get("file", ""), error.get("line", 0), error.get("message", "")]
	var seen: int = _error_counts.get(key, 0)
	if seen == 0 and _error_counts.size() >= tuning.journal_error_cap:
		return
	_error_counts[key] = seen + 1
	_errors_dirty = true
	if seen == 0:
		event(&"error", error)
