class_name JournalDigest
## Résumé lisible d'une séance du journal de jeu (version 4.2.1), à coller dans la conversation :
## l'appareil, puis chaque expédition clairière par clairière (durée, issue, PV, coups portés et
## reçus, danses, groove, appuis, images par seconde, génération), les choix et les erreurs. Pur :
## prend les évènements, rend du texte.

const HEADER := "Journal de jeu Salto (résumé à coller dans la conversation)"
## Appuis : lettre de chaque bouton.
const PRESS_LETTERS := {"attack": "F", "jump": "S", "dodge": "E", "dance": "D"}
## Issue d'une clairière.
const OUTCOMES := {
	"cleared": "nettoyée", "guardian": "gardien libéré", "passed": "traversée", "left": "quittée",
	"faint": "CHUTE", "quit": "abandon", "won": "rentré",
}
## Coups à citer au plus, pour garder une ligne lisible.
const TOP_MOVES := 4


## Texte de la séance faite des évènements `events` (dans l'ordre du fichier).
static func format(events: Array[Dictionary]) -> String:
	var lines: PackedStringArray = []
	var pauses: int = 0
	var errors: Dictionary = {}
	for e: Dictionary in events:
		var t: String = "[%s]" % clock(float(e.get("t", 0.0)))
		match str(e.get("k", "")):
			"session":
				lines.append(_session_line(e))
			"screen":
				lines.append("%s %s" % [t, e.get("name", "")])
			"run_start":
				lines.append("▶ %s expédition : %s" % [t, _run_start(e)])
			"room":
				lines.append("  " + room_line(e))
			"gate":
				lines.append("    porte %s → %s" % [_list(e.get("offered", [])), e.get("chosen", "")])
			"boon":
				lines.append("    don %s → %s ×%d" % [_list(e.get("offered", [])), e.get("chosen", ""), int(e.get("ranks", 1))])
			"encounter":
				lines.append("    rencontre %s → choix %d" % [e.get("id", ""), int(e.get("choice", 0))])
			"build":
				lines.append("%s case %s → choix %d" % [t, e.get("plot", ""), int(e.get("choice", 0))])
			"talent":
				lines.append("%s talent %s → rang %d" % [t, e.get("id", ""), int(e.get("rank", 0))])
			"level":
				lines.append("%s niveau %d" % [t, int(e.get("level", 0))])
			"run_end":
				lines.append("■ %s fin : %s" % [t, _run_end(e)])
			"app_pause":
				pauses += 1
			"quit":
				lines.append("%s fermeture" % t)
			"error":
				lines.append("%s ⚠ %s (%s:%d)" % [t, e.get("message", ""), e.get("file", ""), int(e.get("line", 0))])
			"error_counts":
				errors = e.get("counts", {})
	if pauses > 0:
		lines.append("arrière-plan : %d fois" % pauses)
	var repeated: PackedStringArray = []
	for key: String in errors:
		if int(errors[key]) > 1:
			repeated.append("%d× %s" % [int(errors[key]), key])
	if not repeated.is_empty():
		lines.append("⚠ erreurs répétées : " + " ; ".join(repeated))
	return "\n".join(lines)


## Ligne d'une clairière.
static func room_line(e: Dictionary) -> String:
	var c: Dictionary = e.get("c", {})
	var parts: PackedStringArray = []
	parts.append("c%d %s %s · %s · %s" % [int(e.get("i", 0)) + 1, e.get("kind", ""), e.get("reward", ""), clock(float(e.get("duration", 0.0))), OUTCOMES.get(str(e.get("outcome", "")), e.get("outcome", ""))])
	if e.has("hp0"):
		parts.append("PV %d→%d/%d" % [roundi(float(e["hp0"])), roundi(float(e.get("hp1", e["hp0"]))), roundi(float(e.get("hpmax", 0)))])
	var hits: int = _sum(c, "hit:")
	if hits > 0:
		parts.append("coups %d (%s)" % [hits, _top(c, "hit:", TOP_MOVES)])
	if c.has("crit"):
		parts.append("crit %d" % int(c["crit"]))
	var hurt: int = _sum(c, "hurt:")
	if hurt > 0:
		parts.append("reçus %d, −%d PV (%s)" % [hurt, roundi(float(c.get("hurtdmg", 0.0))), _top(c, "hurt:", TOP_MOVES)])
	if c.has("perfect_dodge"):
		parts.append("esq. parf. %d" % int(c["perfect_dodge"]))
	if c.has("groove_up") or c.has("groove_down"):
		parts.append("groove +%.1f −%.1f" % [float(c.get("groove_up", 0.0)), float(c.get("groove_down", 0.0))])
	if c.has("rainbow"):
		parts.append("arc-en-ciel %d" % int(c["rainbow"]))
	var dances: int = _sum(c, "dance:", ["dance:auto", "dance:manual", "dance:fizzle"])
	if dances > 0 or c.has("dance:fizzle"):
		var dance: String = "danses %d (%s ; auto %d, visées %d, ratées %d" % [dances, _top(c, "dance:", TOP_MOVES, ["dance:auto", "dance:manual", "dance:fizzle"]), int(c.get("dance:auto", 0)), int(c.get("dance:manual", 0)), int(c.get("dance:fizzle", 0))]
		if c.has("thread_s"):
			dance += ", fil %.1f s" % float(c["thread_s"])
		parts.append(dance + ")")
	var presses: PackedStringArray = []
	for action: String in PRESS_LETTERS:
		if c.has("press:" + action):
			presses.append("%s%d" % [PRESS_LETTERS[action], int(c["press:" + action])])
	if not presses.is_empty():
		parts.append("appuis " + " ".join(presses))
	var freed: int = _sum(c, "freed:")
	if freed > 0:
		parts.append("éclatées %d" % freed)
	if c.has("pause"):
		parts.append("pause %d" % int(c["pause"]))
	var perf: Dictionary = e.get("perf", {})
	if not perf.is_empty():
		parts.append("%d i/s (pire %d ms, lentes %d %%, accrocs %d)" % [int(perf.get("fps", 0)), int(perf.get("worst_ms", 0)), roundi(float(perf.get("slow", 0.0)) * 100.0), int(perf.get("hitches", 0))])
	if str(e.get("by", "")) != "":
		parts.append("tombé par %s" % e["by"])
	if e.has("gen_ms"):
		parts.append("génération %d ms" % int(e["gen_ms"]))
	return " · ".join(parts)


## « 1:05 » pour 65 secondes.
static func clock(seconds: float) -> String:
	var s: int = maxi(0, roundi(seconds))
	return "%d:%02d" % [s / 60, s % 60]


static func _session_line(e: Dictionary) -> String:
	return "== Séance %s · Salto %s · %s · %s · %s · %s · %s · %s Go · %d cœurs · latence audio %d ms · calibrage %+d ms" % [
		str(e.get("date", "")).replace("T", " "), e.get("version", ""), e.get("os", ""), e.get("model", ""),
		e.get("gpu", ""), e.get("renderer", ""), e.get("screen", ""), str(e.get("memory_gb", "?")),
		int(e.get("cpus", 0)), int(e.get("audio_latency_ms", 0)), int(e.get("calibration_ms", 0)),
	]


static func _run_start(e: Dictionary) -> String:
	var talents: PackedStringArray = []
	var ranks: Dictionary = e.get("talents", {})
	for id: String in ranks:
		talents.append("%s%d" % [id, int(ranks[id])])
	var pacts: Array = e.get("pacts", [])
	return "%s · %s · pactes %s · niv %d · talents %s · %de expédition · %d clairières" % [
		e.get("region", ""), e.get("weapon", ""), _list(pacts) if not pacts.is_empty() else "aucun",
		int(e.get("level", 0)), " ".join(talents) if not talents.is_empty() else "aucun",
		int(e.get("expeditions", 0)) + 1, int(e.get("rooms", 0)),
	]


static func _run_end(e: Dictionary) -> String:
	var text: String = "%s c%d" % [OUTCOMES.get(str(e.get("kind", "")), e.get("kind", "")), int(e.get("room", 0))]
	if bool(e.get("beyond", false)):
		text += " (au-delà, %d gardien%s)" % [int(e.get("guardians", 0)), "s" if int(e.get("guardians", 0)) > 1 else ""]
	if str(e.get("fallen_to", "")) != "":
		text += " · par %s" % e["fallen_to"]
	if float(e.get("boss_left", -1.0)) >= 0.0:
		text += " · gardien à %d %%" % roundi(float(e["boss_left"]) * 100.0)
	return text + " · %s · %d plumes · %d Sourdines" % [clock(float(e.get("time", 0.0))), int(e.get("feathers", 0)), int(e.get("muets", 0))]


static func _list(items: Array) -> String:
	return "[%s]" % ", ".join(items.map(func(item: Variant) -> String: return str(item)))


## Somme des compteurs dont la clé commence par `prefix` (hors `skip`).
static func _sum(c: Dictionary, prefix: String, skip: Array = []) -> int:
	var total: float = 0.0
	for key: String in c:
		if key.begins_with(prefix) and not skip.has(key):
			total += float(c[key])
	return roundi(total)


## Les `count` plus grands compteurs de `prefix` : « martelo 12, palm 5 ».
static func _top(c: Dictionary, prefix: String, count: int, skip: Array = []) -> String:
	var keys: Array = c.keys().filter(func(key: String) -> bool: return key.begins_with(prefix) and not skip.has(key))
	keys.sort_custom(func(a: String, b: String) -> bool: return float(c[a]) > float(c[b]))
	var parts: PackedStringArray = []
	for key: String in keys.slice(0, count):
		parts.append("%s %d" % [key.substr(prefix.length()), int(c[key])])
	return ", ".join(parts)
