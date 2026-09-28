extends RefCounted
## Rapport du robot joueur, en Markdown : issues des expéditions, profondeur, difficulté clairière
## par clairière, causes des chutes, coups et danses, temps de génération, blocages, soucis de
## marche et erreurs du moteur. Fait à partir des résumés d'expédition et du journal de jeu.


## Le rapport des expéditions `results` (résumés de Game.end_run, plus ce que le robot a noté), du
## journal `events` et des paramètres `params`.
static func build(results: Array[Dictionary], events: Array[Dictionary], params: Dictionary) -> String:
	var md: PackedStringArray = []
	md.append("# Rapport du robot joueur — Salto %s" % params.get("version", ""))
	md.append("")
	md.append("%s · %d expéditions · adresse « %s » · au-delà jusqu'à %d gardien(s) · graine %d · %s min de calcul" % [
		Time.get_datetime_string_from_system().replace("T", " "), int(params.get("runs", 0)), params.get("skill", ""),
		int(params.get("beyond_max", 0)), int(params.get("seed", 0)), str(params.get("real_minutes", 0))])
	md.append("")
	md.append("> Le robot joue sur le serveur de test, sans écran : les images par seconde n'y veulent rien dire (voir le journal du téléphone pour ça).")
	md.append("")
	_outcomes(md, results)
	_runs(md, results)
	var rooms: Array[Dictionary] = events.filter(func(e: Dictionary) -> bool: return e.get("k", "") == "room")
	_depth(md, rooms)
	_falls(md, results)
	_combat(md, rooms)
	_generation(md, rooms)
	_issues(md, results)
	_errors(md, events)
	return "\n".join(md) + "\n"


static func _outcomes(md: PackedStringArray, results: Array[Dictionary]) -> void:
	var kinds: Dictionary = {}
	var depth_total: int = 0
	var depth_max: int = 0
	var guardians: int = 0
	var beyond: int = 0
	for r: Dictionary in results:
		var kind: String = str(r.get("kind", "?"))
		kinds[kind] = int(kinds.get(kind, 0)) + 1
		depth_total += int(r.get("room", 0))
		depth_max = maxi(depth_max, int(r.get("room", 0)))
		guardians += int(r.get("guardians", 0))
		if bool(r.get("beyond", false)):
			beyond += 1
	md.append("## Résultats")
	md.append("")
	var names := {"won": "rentrées victorieuses", "faint": "chutes", "quit": "abandons", "blocage": "blocages", "temps": "trop longues"}
	var parts: PackedStringArray = []
	for kind: String in kinds:
		parts.append("%d %s" % [kinds[kind], names.get(kind, kind)])
	md.append("- Issues : " + ", ".join(parts))
	md.append("- Profondeur atteinte : %.1f clairières en moyenne, %d au plus" % [float(depth_total) / maxf(1.0, results.size()), depth_max])
	md.append("- Gardiens libérés : %d ; expéditions allées au-delà : %d" % [guardians, beyond])
	md.append("")


static func _runs(md: PackedStringArray, results: Array[Dictionary]) -> void:
	md.append("## Expéditions une à une")
	md.append("")
	md.append("| # | Région | Instrument | Niveau | Issue | Clairière | Gardiens | Durée (jeu) | Plumes | Tombé par |")
	md.append("|---|---|---|---|---|---|---|---|---|---|")
	for r: Dictionary in results:
		md.append("| %d | %s | %s | %d → %d | %s | %d | %d | %s | %d | %s |" % [
			int(r.get("index", 0)) + 1, r.get("region", ""), r.get("weapon", ""), int(r.get("level", 0)), int(r.get("level_after", 0)),
			r.get("kind", ""), int(r.get("room", 0)), int(r.get("guardians", 0)), JournalDigest.clock(float(r.get("game_time", 0.0))),
			int(r.get("feathers", 0)), r.get("fallen_to", "") if str(r.get("fallen_to", "")) != "" else "—"])
	md.append("")


static func _depth(md: PackedStringArray, rooms: Array[Dictionary]) -> void:
	var by_index: Dictionary = {}
	for room: Dictionary in rooms:
		var i: int = int(room.get("i", 0))
		var row: Dictionary = by_index.get(i, {"n": 0, "time": 0.0, "lost": 0.0, "falls": 0, "fights": 0})
		row["n"] += 1
		row["time"] += float(room.get("duration", 0.0))
		if room.has("hp0") and float(room.get("hpmax", 0.0)) > 0.0:
			row["lost"] += (float(room["hp0"]) - float(room.get("hp1", room["hp0"]))) / float(room["hpmax"])
			row["fights"] += 1
		if str(room.get("outcome", "")) == "faint":
			row["falls"] += 1
		by_index[i] = row
	md.append("## Difficulté clairière par clairière")
	md.append("")
	md.append("| Clairière | Passages | Durée moyenne | PV perdus en moyenne | Chutes |")
	md.append("|---|---|---|---|---|")
	var indices: Array = by_index.keys()
	indices.sort()
	for i: int in indices:
		var row: Dictionary = by_index[i]
		md.append("| %d | %d | %s | %d %% | %d |" % [i + 1, row["n"], JournalDigest.clock(row["time"] / maxf(1.0, row["n"])),
			roundi(100.0 * row["lost"] / maxf(1.0, row["fights"])), row["falls"]])
	md.append("")


static func _falls(md: PackedStringArray, results: Array[Dictionary]) -> void:
	var causes: Dictionary = {}
	for r: Dictionary in results:
		if str(r.get("kind", "")) == "faint":
			var by: String = str(r.get("fallen_to", "")) if str(r.get("fallen_to", "")) != "" else "?"
			causes[by] = int(causes.get(by, 0)) + 1
	if causes.is_empty():
		return
	md.append("## Causes des chutes")
	md.append("")
	for by: String in causes:
		md.append("- %s : %d" % [by, causes[by]])
	md.append("")


static func _combat(md: PackedStringArray, rooms: Array[Dictionary]) -> void:
	var total: Dictionary = {}
	for room: Dictionary in rooms:
		var c: Dictionary = room.get("c", {})
		for key: String in c:
			total[key] = float(total.get(key, 0.0)) + float(c[key])
	md.append("## Combat (toutes clairières)")
	md.append("")
	md.append("- Coups portés : " + _group(total, "hit:"))
	md.append("- Coups reçus : %s (−%d PV en tout)" % [_group(total, "hurt:"), roundi(float(total.get("hurtdmg", 0.0)))])
	md.append("- Esquives parfaites : %d ; critiques : %d ; Salto arc-en-ciel : %d" % [int(total.get("perfect_dodge", 0)), int(total.get("crit", 0)), int(total.get("rainbow", 0))])
	md.append("- Danses : %s ; ratées faute de groove : %d ; fil d'écho %.0f s" % [_group(total, "dance:", ["dance:auto", "dance:manual", "dance:fizzle"]), int(total.get("dance:fizzle", 0)), float(total.get("thread_s", 0.0))])
	md.append("- Groove : +%.0f gagné, −%.0f perdu (dépensé ou retombé)" % [float(total.get("groove_up", 0.0)), float(total.get("groove_down", 0.0))])
	md.append("- Sourdines éclatées : " + _group(total, "freed:"))
	md.append("")


static func _generation(md: PackedStringArray, rooms: Array[Dictionary]) -> void:
	var by_kind: Dictionary = {}
	for room: Dictionary in rooms:
		if not room.has("gen_ms"):
			continue
		var kind: String = str(room.get("kind", ""))
		var row: Dictionary = by_kind.get(kind, {"n": 0, "sum": 0, "max": 0})
		row["n"] += 1
		row["sum"] += int(room["gen_ms"])
		row["max"] = maxi(row["max"], int(room["gen_ms"]))
		by_kind[kind] = row
	md.append("## Génération des clairières (serveur de test)")
	md.append("")
	for kind: String in by_kind:
		var row: Dictionary = by_kind[kind]
		md.append("- %s : %d ms en moyenne, %d ms au plus (%d fois)" % [kind, roundi(float(row["sum"]) / row["n"]), row["max"], row["n"]])
	md.append("")


static func _issues(md: PackedStringArray, results: Array[Dictionary]) -> void:
	md.append("## Blocages et soucis de marche")
	md.append("")
	var any: bool = false
	for r: Dictionary in results:
		for issue: Dictionary in r.get("issues", []):
			any = true
			md.append("- Expédition %d, clairière %d, à %s : **%s** — %s" % [int(r.get("index", 0)) + 1, int(issue.get("room", -1)) + 1, JournalDigest.clock(float(issue.get("time", 0.0))), issue.get("kind", ""), issue.get("text", "")])
	if not any:
		md.append("Aucun.")
	md.append("")


static func _errors(md: PackedStringArray, events: Array[Dictionary]) -> void:
	var counts: Dictionary = {}
	for e: Dictionary in events:
		if e.get("k", "") == "error_counts":
			counts.merge(e.get("counts", {}), true)
	md.append("## Erreurs du moteur")
	md.append("")
	if counts.is_empty():
		md.append("Aucune.")
	for key: String in counts:
		md.append("- %d× %s" % [int(counts[key]), key])
	md.append("")


## « martelo 120, meia_lua 80 » pour les compteurs de `prefix`, du plus grand au plus petit.
static func _group(total: Dictionary, prefix: String, skip: Array = []) -> String:
	var keys: Array = total.keys().filter(func(key: String) -> bool: return key.begins_with(prefix) and not skip.has(key))
	if keys.is_empty():
		return "aucun"
	keys.sort_custom(func(a: String, b: String) -> bool: return float(total[a]) > float(total[b]))
	var parts: PackedStringArray = []
	for key: String in keys:
		parts.append("%s %d" % [key.substr(prefix.length()), roundi(float(total[key]))])
	return ", ".join(parts)
