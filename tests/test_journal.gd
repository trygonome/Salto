extends GutTest
## Journal de jeu (version 4.2.1) : ce qui se passe pendant les parties est noté sur l'appareil, par
## séance, et se résume en un texte lisible à coller dans la conversation.

const LevelScene: PackedScene = preload("res://scenes/levels/expedition.tscn")
const DIR := "user://journal_tests"

var tuning: TuningData = Tuning.data


func before_each() -> void:
	_clear_dir()
	Journal.enabled = true
	Journal.restart(DIR)
	Save.path = "user://test_journal.json"
	Game.profile = Profile.create()
	Game.profile.expeditions = 1
	Game.start_on_load = false
	Game.village_on_load = false
	Game.run = null


func after_each() -> void:
	Journal.restart(DIR)
	Journal.enabled = false
	_clear_dir()
	get_tree().paused = false
	Game.run = null
	Game.playing = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.path))


func after_all() -> void:
	Game.profile = Profile.new()
	Game.refresh_stats()


func _clear_dir() -> void:
	if DirAccess.dir_exists_absolute(DIR):
		for file: String in DirAccess.get_files_at(DIR):
			DirAccess.remove_absolute(DIR.path_join(file))


func _events() -> Array[Dictionary]:
	Journal.flush()
	var files: PackedStringArray = Journal.session_files()
	return Journal.read_session(DIR.path_join(files[files.size() - 1])) if not files.is_empty() else [] as Array[Dictionary]


func test_une_seance_note_l_appareil_puis_chaque_clairiere() -> void:
	Journal.begin_room({"i": 0, "kind": "grove", "reward": "boon", "hp0": 100.0, "hpmax": 112.0})
	Journal.count("hit:martelo", 3)
	Journal.count("hit:palm")
	Journal.count("hurt:spitter")
	Journal.count("hurtdmg", 12.0)
	Journal.count("press:attack", 4)
	Journal.end_room("cleared", {"hp1": 88.0})
	Journal.count("hit:martelo")
	var events: Array[Dictionary] = _events()
	assert_eq(events[0]["k"], "session", "la séance commence par l'appareil")
	assert_true(events[0].has("model") and events[0].has("gpu") and events[0].has("version"))
	var room: Dictionary = events[events.size() - 1]
	assert_eq(room["k"], "room")
	assert_eq(room["outcome"], "cleared")
	assert_eq(room["c"]["hit:martelo"], 3.0, "les compteurs de la clairière")
	assert_false(Journal.in_room(), "hors clairière, les compteurs ne notent rien")
	var line: String = JournalDigest.room_line(room)
	for part: String in ["c1 grove boon", "nettoyée", "PV 100→88/112", "coups 4 (martelo 3, palm 1)", "reçus 1, −12 PV (spitter 1)", "appuis F4"]:
		assert_string_contains(line, part)


func test_le_resume_se_lit_et_compte_les_expeditions() -> void:
	Journal.event(&"screen", {"name": "titre"})
	Journal.event(&"run_start", {"region": "sunken", "weapon": "maracas", "pacts": [], "level": 7, "talents": {"palm": 2}, "expeditions": 3, "rooms": 7})
	Journal.begin_room({"i": 0, "kind": "ruins", "reward": "boon"})
	Journal.count("dance:palm", 2)
	Journal.count("dance:auto", 2)
	Journal.end_room("cleared")
	Journal.event(&"gate", {"offered": ["boon", "heal"], "chosen": "heal"})
	Journal.event(&"boon", {"offered": ["ember/common", "tide/rare"], "chosen": "tide", "ranks": 2})
	Journal.event(&"run_end", {"kind": "faint", "room": 5, "fallen_to": "charger", "time": 300.0, "feathers": 80, "muets": 22, "beyond": false})
	assert_eq(Journal.run_count(), 1)
	var text: String = Journal.digest(tuning.journal_digest_sessions, tuning.journal_digest_max_chars)
	for part: String in [JournalDigest.HEADER, "== Séance", "titre", "expédition : sunken · maracas", "talents palm2", "danses 2 (palm 2 ; auto 2", "porte [boon, heal] → heal", "don [ember/common, tide/rare] → tide ×2", "fin : CHUTE c5 · par charger · 5:00 · 80 plumes"]:
		assert_string_contains(text, part)


func test_on_ne_garde_que_les_dernieres_seances() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for i: int in tuning.journal_sessions_kept + 5:
		var file: FileAccess = FileAccess.open(DIR.path_join("session-2000-01-01_00-00-%02d.jsonl" % i), FileAccess.WRITE)
		file.store_line("{}")
		file.close()
	Journal.event(&"screen", {"name": "titre"})
	Journal.flush()
	assert_eq(Journal.session_files().size(), tuning.journal_sessions_kept, "les plus anciennes s'effacent")


func test_les_erreurs_du_moteur_sont_captees() -> void:
	var logger := JournalLogger.new()
	logger._log_error("f", "res://scripts/x.gd", 12, "code", "quelque chose a cassé", false, Logger.ERROR_TYPE_SCRIPT, [])
	logger._log_error("f", "res://scripts/x.gd", 13, "code", "un avertissement", false, Logger.ERROR_TYPE_WARNING, [])
	logger._log_message("erreur imprimée\n", true)
	logger._log_message("simple message", false)
	var errors: Array[Dictionary] = logger.take()
	assert_eq(errors.size(), 2, "les erreurs, pas les avertissements ni les messages")
	assert_eq(errors[0]["file"], "x.gd")
	assert_eq(logger.take().size(), 0, "prises une seule fois")


func test_une_expedition_se_note_du_depart_a_la_chute() -> void:
	var level: Expedition = LevelScene.instantiate() as Expedition
	var hero: Hero = level.get_node("Hero") as Hero
	add_child_autofree(level)
	await get_tree().process_frame
	level.start_sortie()
	hero.reads_player_input = false
	assert_true(Journal.in_room(), "la première clairière est ouverte")
	hero.press(&"jump")
	hero.press(&"attack")
	level.end_sortie(&"faint")
	var kinds: Array = _events().map(func(e: Dictionary) -> String: return e["k"])
	assert_true(kinds.has("run_start"))
	var rooms: Array[Dictionary] = _events().filter(func(e: Dictionary) -> bool: return e["k"] == "room")
	assert_eq(rooms.size(), 1)
	assert_eq(rooms[0]["outcome"], "faint", "la clairière se ferme sur la chute")
	assert_eq(rooms[0]["c"].get("press:jump", 0.0), 1.0, "les appuis comptent")
	assert_true(rooms[0].has("gen_ms"), "le temps de génération")
	assert_eq(kinds[kinds.size() - 1], "run_end")
	get_tree().paused = false
