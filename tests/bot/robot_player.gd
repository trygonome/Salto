extends Node
## Robot joueur : enchaîne des expéditions en accéléré, comme un joueur moyen. Il marche sur les
## sentiers, frappe la pierre du silence, combat (poursuit, frappe, esquive parfois, danse, tente
## le Salto arc-en-ciel), ouvre le coffre, parle aux rencontres, choisit ses dons et ses passages,
## va au-delà ou rentre. Entre deux expéditions, il dépense ses points de talent, rebâtit le village
## et change d'instrument. Il note les blocages (plus rien n'avance) et les soucis de marche ; le
## journal de jeu note tout le reste. À la fin, un rapport en Markdown (RobotReport).
##
## Lancement : tools/robot.sh (voir ce script pour les options).

const LevelScene: PackedScene = preload("res://scenes/levels/expedition.tscn")
const ReportScript := preload("res://tests/bot/robot_report.gd")

## Adresse du robot : chance d'esquiver une attaque annoncée, délai de réaction (s), cadence des
## coups (s), écart entre deux danses (s), chance de tenter l'arc-en-ciel quand la jauge est pleine.
const SKILLS := {
	"faible": {"dodge": 0.25, "reaction": 0.3, "attack": 0.4, "dance": 6.0, "rainbow": 0.3},
	"moyen": {"dodge": 0.55, "reaction": 0.15, "attack": 0.28, "dance": 4.0, "rainbow": 0.6},
	"fort": {"dodge": 0.85, "reaction": 0.08, "attack": 0.22, "dance": 2.5, "rainbow": 0.9},
}
## Portée où il frappe (m), distance où il guette les attaques (m), où il danse (m).
const STRIKE_RANGE := 1.5
const THREAT_RANGE := 3.5
const DANCE_RANGE := 12.0
## Porte-bouclier : il saute par-dessus à moins de tant (m), et plonge tant (s) après le saut.
const SHIELD_DIVE_RANGE := 2.5
const DIVE_DELAY := 0.25
## Marche : un point de passage est atteint à tant (m) ; coincé s'il avance de moins de tant (m)
## en une seconde ; au bout de tant (s) coincé, il est replacé (et c'est noté).
const WAYPOINT_REACHED := 1.2
## Il vise tant de mètres plus loin sur son chemin.
const LOOKAHEAD := 2.0
const STUCK_MOVE := 0.4
const STUCK_TELEPORT := 8.0
## Blocage : rien n'a changé depuis tant (s) de jeu ; une expédition dure au plus tant (s) de jeu.
const SOFTLOCK_TIME := 45.0
const RUN_TIME_LIMIT := 45.0 * 60.0
## Talents, dans l'ordre où il les prend (il mélange les voies, comme un joueur curieux).
const TALENT_ORDER: Array[StringName] = [
	&"palm", &"feet", &"breath", &"metro", &"spiral", &"drum", &"sap", &"triple", &"rain", &"roll",
	&"bark", &"dash2", &"thread", &"finale", &"second", &"comet",
]
## Passages préférés (dans l'ordre) ; le soin d'abord s'il lui reste peu de PV.
const GATE_ORDER: Array[StringName] = [&"boon", &"treasure", &"encounter", &"feathers", &"rest", &"heal", &"secret", &"boss"]
const LOW_HEALTH := 0.45

var runs: int = 10
var skill: Dictionary = SKILLS["moyen"]
var skill_name: String = "moyen"
## Gardiens au-delà desquels il ne va plus (0 : il rentre toujours).
var beyond_max: int = 1
var out_dir: String = ""

var rng := RandomNumberGenerator.new()
var results: Array[Dictionary] = []

var _level: Expedition
var _hero: Hero
var _clock: float = 0.0
var _next_attack: float = 0.0
var _next_dance: float = 0.0
var _dodge_at: float = -1.0
var _rainbow_step: float = -1.0
var _thread_until: float = -1.0
var _path := PackedVector3Array()
var _path_index: int = 0
var _path_key: String = ""
var _last_pos := Vector3.ZERO
var _last_pos_time: float = 0.0
var _stuck_time: float = 0.0
var _unstick_until: float = -1.0
var _unstick_dir := Vector2.ZERO
var _signature: String = ""
var _signature_time: float = 0.0
var _issues: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Joue toutes les expéditions demandées (`args` : options de la ligne de commande), écrit le
## rapport et quitte.
func run_all(args: PackedStringArray) -> void:
	_parse(args)
	var started: int = Time.get_ticks_msec()
	Rhythm.game_clock = true
	Feedback.game_clock = true
	Save.path = "user://robot_save.json"
	Save.erase()
	Game.profile = Profile.create()
	Game.refresh_stats()
	Journal.enabled = true
	Journal.restart(out_dir.path_join("journal"))
	for i: int in runs:
		_between_runs(i)
		var result: Dictionary = await _play_run(i)
		results.append(result)
		print("robot : expédition %d/%d → %s, clairière %d, %s de jeu" % [i + 1, runs, result.get("kind", "?"), int(result.get("room", 0)), JournalDigest.clock(float(result.get("game_time", 0.0)))])
	Journal.flush()
	var report: String = ReportScript.build(results, _journal_events(), {
		"runs": runs, "skill": skill_name, "beyond_max": beyond_max, "seed": rng.seed,
		"real_minutes": snappedf(float(Time.get_ticks_msec() - started) / 60000.0, 0.1),
		"version": ProjectSettings.get_setting("application/config/version", ""),
	})
	var path: String = out_dir.path_join("rapport.md")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(report)
	file.close()
	print("robot : rapport écrit dans ", path)
	get_tree().quit()


func _parse(args: PackedStringArray) -> void:
	out_dir = ProjectSettings.globalize_path("res://build/robot")
	rng.randomize()
	var i: int = 0
	while i < args.size():
		var value: String = args[i + 1] if i + 1 < args.size() else ""
		match args[i]:
			"--runs":
				runs = maxi(1, int(value))
			"--skill":
				if SKILLS.has(value):
					skill = SKILLS[value]
					skill_name = value
			"--beyond":
				beyond_max = maxi(0, int(value))
			"--seed":
				rng.seed = int(value)
			"--out":
				out_dir = value
		i += 2
	DirAccess.make_dir_recursive_absolute(out_dir)


## Entre deux expéditions : talents, cases du village, région la plus lointaine ouverte, instrument
## suivant.
func _between_runs(index: int) -> void:
	var profile: Profile = Game.profile
	var tuning: TuningData = Tuning.data
	var bought: bool = true
	while profile.talent_points > 0 and bought:
		bought = false
		for id: StringName in TALENT_ORDER:
			if profile.buy_talent(id):
				Journal.event(&"talent", {"id": String(id), "rank": profile.talent_rank(id)})
				bought = true
				break
	for id: StringName in Village.IDS:
		if Village.build(profile, id, tuning):
			Journal.event(&"build", {"plot": String(id), "choice": 0})
	var open: Array[StringName] = Regions.unlocked(profile.regions_won)
	profile.region = open[open.size() - 1]
	profile.weapon = tuning.weapons[index % tuning.weapons.size()].id
	Game.refresh_stats()


## Une expédition, du départ au résumé.
func _play_run(index: int) -> Dictionary:
	var level_before: int = Game.profile.level
	_issues.clear()
	_clock = 0.0
	_next_attack = 0.0
	_next_dance = 0.0
	_dodge_at = -1.0
	_rainbow_step = -1.0
	_thread_until = -1.0
	_unstick_until = -1.0
	_level = LevelScene.instantiate() as Expedition
	add_child(_level)
	for i: int in 3:
		await get_tree().process_frame
	_level.start_sortie()
	_hero = _level.hero
	_hero.reads_player_input = false
	_reset_path()
	_signature_time = 0.0
	var kind: String = ""
	while true:
		await get_tree().process_frame
		# Temps de jeu : rien ne passe pendant un arrêt sur image, moins pendant un ralenti.
		var delta: float = Engine.time_scale / float(Engine.physics_ticks_per_second)
		_clock += delta
		if Game.run == null:
			kind = str(Game.last_summary.get("kind", "?"))
			break
		if _clock > RUN_TIME_LIMIT:
			_note("temps", "expédition trop longue, arrêtée")
			_level.end_sortie(&"quit")
			kind = "temps"
			break
		if _level.boon_screen.visible:
			_choose_card()
			continue
		if get_tree().paused:
			get_tree().paused = false
		_drive(delta)
		if _watch_softlock():
			kind = "blocage"
			_level.end_sortie(&"quit")
			break
	var summary: Dictionary = Game.last_summary.duplicate()
	summary["kind"] = kind if kind in ["blocage", "temps"] else summary.get("kind", kind)
	summary["game_time"] = _clock
	summary["issues"] = _issues.duplicate()
	summary["index"] = index
	summary["weapon"] = String(Game.profile.weapon)
	summary["level_after"] = Game.profile.level
	summary["level"] = level_before
	get_tree().paused = false
	_level.queue_free()
	_level = null
	_hero = null
	for i: int in 3:
		await get_tree().process_frame
	return summary


## Ce que le robot fait à cette image.
func _drive(delta: float) -> void:
	# (Le jeu rend la main aux vraies commandes après chaque passage : le robot la reprend.)
	_hero.reads_player_input = false
	_hero.input_move = Vector2.ZERO
	var stone: Node3D = _level.get(&"_stone") as Node3D
	var foes: Array[Muet] = _foes()
	if is_instance_valid(stone) and not stone.call(&"is_struck"):
		if _go_to(stone.global_position, 1.3, "pierre"):
			_attack()
		return
	if bool(_level.get(&"_arena_waiting")):
		_follow("entrée", _entry_route())
		return
	if not foes.is_empty():
		_fight(foes, delta)
		return
	var chest: Node3D = _level.get(&"_chest") as Node3D
	if is_instance_valid(chest) and not bool(chest.get(&"_opened")):
		_go_to(chest.global_position, 0.3, "coffre")
		return
	var encounter: StringName = _level.get(&"_encounter")
	if encounter != &"" and not bool(_level.get(&"_encounter_open")) and not bool(_level.get(&"_cleared")):
		_follow("rencontre", _entry_route())
		return
	var gates: Array[ExitGate] = _gates()
	if bool(_level.get(&"_cleared")) and not gates.is_empty():
		var gate: ExitGate = _pick_gate(gates)
		_follow("porte " + String(gate.reward), _gate_route(gate))
		return
	# Entre deux vagues : vers le milieu de l'arène.
	_go_to(Vector3.ZERO, 3.0, "attente")


## Combat : poursuivre la Sourdine la plus proche, frapper, esquiver, danser, arc-en-ciel.
func _fight(foes: Array[Muet], _delta: float) -> void:
	var target: Muet = foes[0]
	var best: float = INF
	for muet: Muet in foes:
		var d: float = muet.flat_distance_to(_hero.global_position)
		if d < best:
			best = d
			target = muet
	# Esquive : une attaque annoncée tout près, avec un temps de réaction.
	var threat: Muet = null
	for muet: Muet in foes:
		if muet.is_threatening() and muet.flat_distance_to(_hero.global_position) < THREAT_RANGE:
			threat = muet
			break
	if threat and _dodge_at < 0.0 and rng.randf() < float(skill["dodge"]) * 0.2:
		_dodge_at = _clock + float(skill["reaction"])
	if _dodge_at >= 0.0 and _clock >= _dodge_at:
		_dodge_at = -1.0
		if threat:
			var away: Vector3 = _hero.global_position - threat.global_position
			_hero.input_move = Vector2(away.x, away.z).normalized()
		_hero.press(&"dodge")
		return
	# Fil d'écho tenu.
	if _thread_until >= 0.0:
		_hero.dance_stick = _stick_to(target.global_position)
		_hero.dance_manual = true
		if _clock >= _thread_until:
			_hero.thread_held = false
			_thread_until = -1.0
		return
	# Arc-en-ciel : sauter puis plonger quand la jauge est pleine.
	if _rainbow_step >= 0.0:
		if _clock >= _rainbow_step:
			_hero.press(&"attack")
			_rainbow_step = -1.0
		return
	if _hero.groove.is_full() and best < 4.0 and rng.randf() < float(skill["rainbow"]) * 0.05:
		_hero.press(&"jump")
		_rainbow_step = _clock + 0.3
		return
	# Danse : de loin, quand le groove le permet.
	if _hero.can_dance() and _clock >= _next_dance and best < DANCE_RANGE:
		var figure: StringName = _hero.next_dance_figure()
		if _hero.groove.value >= DanceMath.cost(figure, Tuning.data) + 1.0:
			_next_dance = _clock + float(skill["dance"]) * rng.randf_range(0.7, 1.3)
			if _hero.stats.dance.has(DanceMath.THREAD) and rng.randf() < 0.25:
				_hero.thread_held = true
				_thread_until = _clock + 1.5
				return
			_hero.request_dance(_stick_to(target.global_position), true)
			return
	# Porte-bouclier : sauter par-dessus son bouclier et plonger (la réponse que le jeu attend).
	if target.species == &"shielder" and best < SHIELD_DIVE_RANGE and _hero.is_on_floor() and _clock >= _next_attack:
		_hero.face_now(Vector3(target.global_position.x - _hero.global_position.x, 0.0, target.global_position.z - _hero.global_position.z).normalized())
		_hero.input_move = _toward(target.global_position)
		_hero.press(&"jump")
		_rainbow_step = _clock + DIVE_DELAY
		_next_attack = _clock + float(skill["attack"]) * 3.0
		return
	if best > STRIKE_RANGE:
		_hero.input_move = _toward(target.global_position)
		_check_stuck("combat")
		return
	_hero.face_now(Vector3(target.global_position.x - _hero.global_position.x, 0.0, target.global_position.z - _hero.global_position.z).normalized())
	_attack()


func _attack() -> void:
	if _clock >= _next_attack:
		_hero.press(&"attack")
		_next_attack = _clock + float(skill["attack"]) * rng.randf_range(0.8, 1.2)


## Marche vers `point` ; vrai une fois à moins de `reach` mètres.
func _go_to(point: Vector3, reach: float, what: String) -> bool:
	var flat := Vector2(point.x - _hero.global_position.x, point.z - _hero.global_position.z)
	if flat.length() <= reach:
		return true
	_hero.input_move = flat.normalized()
	_check_stuck(what)
	return false


## Suit le chemin `route` (points dans le monde) comme un joueur : il vise un point un peu plus loin
## sur le tracé que l'endroit du tracé le plus proche de lui (jamais en arrière).
func _follow(what: String, route: PackedVector3Array) -> void:
	if route.is_empty():
		return
	if what != _path_key:
		_path_key = what
		_path = route
		_path_index = 0
	var here := Vector2(_hero.global_position.x, _hero.global_position.z)
	# Avancée sur le tracé : le point le plus proche, sans revenir sur ce qui est fait.
	var best: float = INF
	var along: float = 0.0
	var walked: float = 0.0
	for i: int in _path.size() - 1:
		var a := Vector2(_path[i].x, _path[i].z)
		var b := Vector2(_path[i + 1].x, _path[i + 1].z)
		var ab: Vector2 = b - a
		var t: float = 0.0 if ab.is_zero_approx() else clampf((here - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var d: float = here.distance_to(a + ab * t)
		if i >= _path_index and d < best:
			best = d
			along = walked + ab.length() * t
			_path_index = i
		walked += ab.length()
	var target: Vector3 = _point_along(along + LOOKAHEAD)
	_go_to(target, 0.2, what)


## Le point du tracé à `distance` mètres de son début.
func _point_along(distance: float) -> Vector3:
	var left: float = distance
	for i: int in _path.size() - 1:
		var length: float = _path[i].distance_to(_path[i + 1])
		if left <= length:
			return _path[i].lerp(_path[i + 1], left / maxf(length, 0.001))
		left -= length
	return _path[_path.size() - 1]


func _reset_path() -> void:
	_path = PackedVector3Array()
	_path_key = ""
	_stuck_time = 0.0
	_last_pos = _hero.global_position if _hero else Vector3.ZERO
	_last_pos_time = _clock


## Coincé ? Il saute et fait un pas de côté ; au-delà de STUCK_TELEPORT s, il est replacé plus
## loin sur son chemin (et c'est noté : un obstacle bloque la marche).
func _check_stuck(what: String) -> void:
	if _clock < _unstick_until:
		_hero.input_move = (_hero.input_move + _unstick_dir).normalized()
		return
	if _clock - _last_pos_time < 1.0:
		return
	var moved: float = Vector2(_hero.global_position.x - _last_pos.x, _hero.global_position.z - _last_pos.z).length()
	_last_pos = _hero.global_position
	_last_pos_time = _clock
	if moved >= STUCK_MOVE:
		_stuck_time = 0.0
		return
	_stuck_time += 1.0
	_hero.press(&"jump")
	_unstick_dir = Vector2(-_hero.input_move.y, _hero.input_move.x) * (1.0 if rng.randf() < 0.5 else -1.0)
	_unstick_until = _clock + 0.6
	if _stuck_time >= STUCK_TELEPORT:
		_stuck_time = 0.0
		var goal: Vector3 = _path[mini(_path_index + 1, _path.size() - 1)] if not _path.is_empty() else Vector3.ZERO
		_note("marche", "coincé %s près de (%.1f, %.1f) ; replacé" % [what, _hero.global_position.x, _hero.global_position.z])
		_hero.global_position = goal + Vector3.UP * 0.5
		_hero.velocity = Vector3.ZERO


## Blocage : si rien ne change pendant SOFTLOCK_TIME, il le note et tente de débloquer ; au second
## blocage de suite, l'expédition s'arrête.
func _watch_softlock() -> bool:
	var run: RunState = Game.run
	var health: float = 0.0
	for muet: Muet in _foes():
		health += muet.health.current
	var signature: String = "%d|%d|%d|%s|%d|%s|%d" % [run.room, _foes().size(), roundi(health), str(_level.get(&"_cleared")), _gates().size(), str(_level.get(&"_arena_waiting")), roundi(_hero.health.current)]
	if signature != _signature:
		_signature = signature
		_signature_time = _clock
		return false
	if _clock - _signature_time < SOFTLOCK_TIME:
		return false
	var context: String = "clairière %d (%s, %s), %d Sourdines, nettoyée %s, %d portes, héros en (%.1f, %.1f), état %s, but %s" % [
		run.room + 1, _level.get(&"_kind"), run.reward, _foes().size(), str(_level.get(&"_cleared")), _gates().size(),
		_hero.global_position.x, _hero.global_position.z, _hero.state_machine.current.name, str(_level.current_goal().get(&"title", "")),
	]
	for muet: Muet in _foes().slice(0, 3):
		context += " ; %s en (%.1f, %.1f, h %.1f) à %.1f m, état %s, PV %d/%d" % [muet.species, muet.global_position.x, muet.global_position.z, muet.global_position.y - _hero.global_position.y, muet.flat_distance_to(_hero.global_position), muet.state_machine.current.name if muet.state_machine.current else "?", roundi(muet.health.current), roundi(muet.health.maximum)]
	var repeated: bool = not _issues.is_empty() and _issues[_issues.size() - 1]["kind"] == "blocage" and _issues[_issues.size() - 1]["room"] == run.room
	_note("blocage", context)
	_signature_time = _clock
	if repeated:
		return true
	# Déblocage : droit au but.
	var gates: Array[ExitGate] = _gates()
	if bool(_level.get(&"_cleared")) and not gates.is_empty():
		var gate: ExitGate = _pick_gate(gates)
		gate.chosen.emit(gate.reward)
	elif not _foes().is_empty():
		_hero.global_position = _foes()[0].global_position + Vector3(1.0, 0.5, 0.0)
	else:
		_hero.global_position = Vector3(0.0, 0.5, 0.0)
	return false


func _note(kind: String, text: String) -> void:
	var room: int = Game.run.room if Game.run else -1
	_issues.append({"kind": kind, "room": room, "text": text, "time": snappedf(_clock, 0.1)})
	Journal.event(&"robot", {"issue": kind, "text": text})


## Un don ou un choix de rencontre : une carte au hasard parmi celles qu'on peut prendre.
func _choose_card() -> void:
	var cards: Array = _level.boon_screen.get_node("%Cards").get_children().filter(func(n: Node) -> bool: return n is BaseButton and not (n as BaseButton).disabled)
	if cards.is_empty():
		return
	(cards[rng.randi_range(0, cards.size() - 1)] as BaseButton).pressed.emit()


## Le passage choisi : chez le gardien, au-delà tant qu'il n'a pas libéré beyond_max gardiens et
## qu'il a assez de PV, sinon le village ; ailleurs, selon GATE_ORDER (le soin d'abord si besoin).
func _pick_gate(gates: Array[ExitGate]) -> ExitGate:
	var by_reward: Dictionary = {}
	for gate: ExitGate in gates:
		by_reward[gate.reward] = gate
	var healthy: bool = _hero.health.current / _hero.health.maximum >= LOW_HEALTH
	if by_reward.has(RunState.BEYOND):
		var go_on: bool = Game.run.guardians.size() < beyond_max and healthy
		return by_reward[RunState.BEYOND if go_on else RunState.HOME]
	if not healthy:
		for reward: StringName in [&"heal", &"rest"]:
			if by_reward.has(reward):
				return by_reward[reward]
	for reward: StringName in GATE_ORDER:
		if by_reward.has(reward):
			return by_reward[reward]
	return gates[0]


func _foes() -> Array[Muet]:
	var list: Array[Muet] = []
	for node: Node in get_tree().get_nodes_in_group(&"muets"):
		var muet: Muet = node as Muet
		if muet and not muet.is_freed():
			list.append(muet)
	return list


func _gates() -> Array[ExitGate]:
	var list: Array[ExitGate] = []
	for node: Node in _level.pickups.get_children():
		if node is ExitGate and not node.is_queued_for_deletion():
			list.append(node as ExitGate)
	return list


## Le sentier d'entrée, du bout où l'on arrive jusqu'au centre de l'arène.
func _entry_route() -> PackedVector3Array:
	var unit: float = float(_level.get(&"_unit"))
	var route := PackedVector3Array()
	var path: PackedVector2Array = _level.gen.entry_path
	for i: int in range(path.size() - 1, -1, -1):
		route.append(Vector3(path[i].x, 0.0, path[i].y) * unit)
	route.append(Vector3.ZERO)
	return route


## Du centre de l'arène au passage `gate`, par son sentier de sortie.
func _gate_route(gate: ExitGate) -> PackedVector3Array:
	var unit: float = float(_level.get(&"_unit"))
	var route := PackedVector3Array([Vector3.ZERO])
	var best: float = INF
	var chosen := PackedVector2Array()
	for path: PackedVector2Array in _level.gen.exit_paths:
		var end := Vector3(path[path.size() - 1].x, 0.0, path[path.size() - 1].y) * unit
		var d: float = Vector2(end.x - gate.global_position.x, end.z - gate.global_position.z).length()
		if d < best:
			best = d
			chosen = path
	for p: Vector2 in chosen:
		route.append(Vector3(p.x, 0.0, p.y) * unit)
	route.append(gate.global_position)
	return route


func _toward(point: Vector3) -> Vector2:
	return Vector2(point.x - _hero.global_position.x, point.z - _hero.global_position.z).normalized()


## Le pouce qui vise `point` (la visée d'une danse).
func _stick_to(point: Vector3) -> Vector2:
	var flat := Vector2(point.x - _hero.global_position.x, point.z - _hero.global_position.z)
	return flat.normalized() * clampf(flat.length() / DanceMath.rain_distance(Vector2.ONE.normalized(), Tuning.data), 0.3, 1.0)


func _journal_events() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for file: String in Journal.session_files():
		events.append_array(Journal.read_session(Journal.directory.path_join(file)))
	return events
