class_name RunState
extends RefCounted
## Une expédition : suite de clairières générées, la dernière gardée par un Grand Muet. Garde la
## graine, la clairière en cours, la récompense promise par le passage choisi, les dons pris, les
## plumes gagnées et ce qui compte pour le résumé. Tirages reproductibles depuis la graine.

## Récompenses d'une clairière : don des esprits (1 parmi 3), soin, plumes, rencontre (un
## personnage et un choix, sans combat) ; le Grand Muet (dernière clairière : le libérer termine
## l'expédition).
const BOON := &"boon"
const HEAL := &"heal"
const FEATHERS := &"feathers"
const ENCOUNTER := &"encounter"
const BOSS := &"boss"
## Version 2.6 : repos (un feu de camp, pas de combat), trésor (un coffre après le combat),
## secret (derrière un rocher fêlé : un trésor sans combat).
const REST := &"rest"
const TREASURE := &"treasure"
const SECRET := &"secret"
const REWARDS: Array[StringName] = [BOON, HEAL, FEATHERS, ENCOUNTER, REST, TREASURE]

var seed_value: int = 0
## Région de l'expédition (voir Regions).
var region: StringName = Regions.UNDERGROWTH
## Clairières de l'expédition (la dernière : le Grand Muet) ; clairière en cours (0 : la première).
var room_count: int = 0
var room: int = 0
## Récompense de la clairière en cours, donnée quand elle est nettoyée.
var reward: StringName = BOON
## Dons pris (don → rang).
var boons: Dictionary[StringName, int] = {}
var feathers: int = 0
var muets_freed: int = 0
var elapsed: float = 0.0
## Rencontres déjà faites (une seule fois chacune par expédition).
var encounters_seen: Array[StringName] = []
## L'élite de l'expédition est déjà paru.
var elite_done: bool = false
## Instrument-arme de l'expédition (version 2.8).
var weapon: StringName = &"rainstick"
## Rencontres en plus dans le tirage des passages (case du tambourinaire, version 2.7).
var extra_encounters: int = 0
## Pour le Chef, au retour : ce qui a fait tomber le héros (espèce, &"trap" ; vide : rien), PV
## restants du gardien quand on tombe devant lui (part ; négatif : pas de gardien).
var fallen_to: StringName = &""
var boss_left: float = -1.0
## Pactes de difficulté de l'expédition (version 2.9 ; voir Pacts) ; première expédition (les
## vagues apprennent sans texte).
var pacts: Array[StringName] = []
var tutorial: bool = false
## Ce qui s'est passé pendant l'expédition (version 3.7 : stèle, Muet caché…), pour le village.
var events: Array[StringName] = []
var rng := RandomNumberGenerator.new()


func _init(seed_number: int, rooms: int, run_region: StringName = Regions.UNDERGROWTH) -> void:
	seed_value = seed_number
	room_count = rooms
	region = run_region
	rng.seed = seed_number


## Vrai dans la dernière clairière (le Grand Muet).
func is_boss_room() -> bool:
	return room >= room_count - 1


## Graine de la clairière en cours (même expédition, mêmes clairières).
func room_seed() -> int:
	return hash([seed_value, room])


## Forme de la clairière en cours : l'arène pour le gardien, une clairière calme pour une
## rencontre ou un repos, sinon tirée de sa graine parmi les formes de la région.
func room_kind() -> StringName:
	if is_boss_room():
		return &"arena"
	if reward == ENCOUNTER or reward == REST or reward == SECRET:
		return &"clearing"
	var kinds: Array = Regions.KINDS.get(region, WorldGen.ROOM_KINDS)
	return kinds[posmod(room_seed(), kinds.size())]


## Rayon de la clairière en cours (u), tiré de sa graine entre `smallest` et `largest`.
func room_radius(smallest: float, largest: float) -> float:
	return lerpf(smallest, largest, float(posmod(room_seed() >> 8, 1000)) / 999.0)


## Nom de la clairière en cours parmi `count` noms possibles pour sa forme.
func name_index(count: int) -> int:
	return posmod(room_seed() >> 16, maxi(count, 1))


## Clairière à partir de laquelle paraît l'élite de l'expédition (tirée de la graine, entre
## `first` et l'avant-dernière ; il paraît dans la première clairière de combat à partir de là).
func elite_room(first: int) -> int:
	var span: int = maxi(room_count - 1 - first, 1)
	return first + posmod(seed_value >> 4, span)


## Particularité de l'élite (tirée de la graine) parmi `affixes`.
func elite_affix(affixes: Array[StringName]) -> StringName:
	return affixes[posmod(seed_value >> 8, affixes.size())]


## Tire la rencontre de la clairière en cours parmi `ids`, sans répéter celles déjà faites.
func pick_encounter(ids: Array[StringName]) -> StringName:
	var pool: Array[StringName] = ids.filter(func(id: StringName) -> bool: return not encounters_seen.has(id))
	if pool.is_empty():
		pool = ids.duplicate()
	var id: StringName = pool[rng.randi_range(0, pool.size() - 1)]
	encounters_seen.append(id)
	return id


## Nombre de passages de sortie de la clairière en cours (un seul vers le Grand Muet).
func exit_count(count: int) -> int:
	return 1 if room + 1 >= room_count - 1 else count


## Récompenses proposées par les passages de sortie (`count` différentes ; vers la dernière
## clairière, le Grand Muet).
func exit_rewards(count: int) -> Array[StringName]:
	if room + 1 >= room_count - 1:
		return [BOSS] as Array[StringName]
	var pool: Array[StringName] = REWARDS.duplicate()
	# Jungle avare (pacte) : ni soin ni repos.
	if pacts.has(Pacts.STINGY):
		pool.erase(HEAL)
		pool.erase(REST)
	for i: int in extra_encounters:
		pool.append(ENCOUNTER)
	var picks: Array[StringName] = []
	while picks.size() < count and not pool.is_empty():
		var pick: StringName = pool.pop_at(rng.randi_range(0, pool.size() - 1))
		picks.append(pick)
		# Deux passages, deux récompenses différentes.
		while pool.has(pick):
			pool.erase(pick)
	return picks


## Passe à la clairière suivante, qui promet `promised`.
func enter_next(promised: StringName) -> void:
	room += 1
	reward = promised


## Prend le don `id` (ou le monte de `ranks` rangs : sa rareté).
func take_boon(id: StringName, ranks: int = 1) -> void:
	boons[id] = boons.get(id, 0) + ranks


## Nombre de rangs de dons pris.
func boon_ranks() -> int:
	var total: int = 0
	for id: StringName in boons:
		total += boons[id]
	return total


## État à sauvegarder pour reprendre l'expédition plus tard (à l'entrée d'une clairière).
func to_dict() -> Dictionary:
	var saved_boons: Dictionary = {}
	for id: StringName in boons:
		saved_boons[String(id)] = boons[id]
	return {
		"seed": seed_value, "region": String(region), "rooms": room_count, "room": room, "reward": String(reward),
		"boons": saved_boons, "feathers": feathers, "muets": muets_freed, "elapsed": elapsed,
		"encounters_seen": Array(encounters_seen).map(func(id: StringName) -> String: return String(id)),
		"elite_done": elite_done, "weapon": String(weapon), "extra_encounters": extra_encounters,
		"pacts": Array(pacts).map(func(id: StringName) -> String: return String(id)), "tutorial": tutorial,
		"events": Array(events).map(func(e: StringName) -> String: return String(e)),
		"rng_state": rng.state,
	}


## Expédition relue d'une sauvegarde (voir to_dict) ; null si elle est abîmée.
static func from_dict(data: Dictionary) -> RunState:
	if not data.has("seed") or not data.has("room"):
		return null
	var run := RunState.new(int(data["seed"]), maxi(2, int(data.get("rooms", 7))), StringName(str(data.get("region", Regions.UNDERGROWTH))))
	run.room = clampi(int(data["room"]), 0, run.room_count - 1)
	run.reward = StringName(str(data.get("reward", BOON)))
	var saved_boons: Variant = data.get("boons", {})
	if saved_boons is Dictionary:
		for id: Variant in saved_boons:
			run.boons[StringName(str(id))] = int(saved_boons[id])
	run.feathers = int(data.get("feathers", 0))
	run.muets_freed = int(data.get("muets", 0))
	run.elapsed = float(data.get("elapsed", 0.0))
	for id: Variant in data.get("encounters_seen", []):
		run.encounters_seen.append(StringName(str(id)))
	run.elite_done = bool(data.get("elite_done", false))
	run.weapon = StringName(str(data.get("weapon", "rainstick")))
	run.extra_encounters = int(data.get("extra_encounters", 0))
	for id: Variant in data.get("pacts", []):
		if Pacts.IDS.has(StringName(str(id))):
			run.pacts.append(StringName(str(id)))
	run.tutorial = bool(data.get("tutorial", false))
	for event: Variant in data.get("events", []):
		run.events.append(StringName(str(event)))
	if data.has("rng_state"):
		run.rng.state = int(data["rng_state"])
	return run
