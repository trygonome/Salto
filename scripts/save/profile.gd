class_name Profile
extends RefCounted
## Ce qui se garde d'une nuit à l'autre et d'une partie à l'autre : pages du carnet, objets,
## aides déjà suivies, records, réglages. S'écrit et se relit en dictionnaire (sauvegarde).

## Version du format de sauvegarde (à augmenter si le format change, avec une conversion).
const VERSION := 1

## Pages du carnet trouvées (numéros à partir de 1), dans l'ordre où on les a trouvées.
var pages: Array[int] = []
var items: Array[ItemData] = []
## Aides contextuelles déjà suivies : elles ne reviennent plus.
var hints_done: Array[StringName] = []
## Meilleur temps de chaque nuit accomplie (numéro de la nuit → secondes).
var best_times: Dictionary[int, float] = {}
## Graine du monde de la nuit en cours (0 : pas encore tirée) : le monde reste le même d'une
## sortie à l'autre, et change à la nuit suivante.
var night_seed: int = 0
## Nuits accomplies (le totem du village grandit).
var nights_done: int = 0
## Réglages : chiffres de dégâts, infos de mise au point (versions de test).
var damage_numbers: bool = true
var debug_info: bool = false


## Ajoute une page ; renvoie faux si elle était déjà dans le carnet.
func add_page(page: int) -> bool:
	if pages.has(page):
		return false
	pages.append(page)
	return true


func has_page(page: int) -> bool:
	return pages.has(page)


func add_item(item: ItemData) -> void:
	items.append(item)


## Note une aide comme suivie ; renvoie faux si elle l'était déjà.
func mark_hint_done(hint: StringName) -> bool:
	if hints_done.has(hint):
		return false
	hints_done.append(hint)
	return true


func is_hint_done(hint: StringName) -> bool:
	return hints_done.has(hint)


## Enregistre la nuit `night` accomplie en `time` secondes ; renvoie vrai si c'est un record
## (ou la première fois).
func complete_night(night: int, time: float) -> bool:
	if best_times.has(night) and best_times[night] <= time:
		return false
	best_times[night] = time
	return true


## Meilleur temps de la nuit `night` (s), ou -1 si elle n'a jamais été accomplie.
func best_time(night: int) -> float:
	return best_times.get(night, -1.0)


func to_dict() -> Dictionary:
	var saved_items: Array = []
	for item: ItemData in items:
		saved_items.append(item.to_dict())
	var saved_hints: Array = []
	for hint: StringName in hints_done:
		saved_hints.append(String(hint))
	var saved_times: Dictionary = {}
	for night: int in best_times:
		saved_times[str(night)] = best_times[night]
	return {
		"version": VERSION,
		"pages": pages.duplicate(),
		"items": saved_items,
		"hints_done": saved_hints,
		"best_times": saved_times,
		"night_seed": night_seed,
		"nights_done": nights_done,
		"settings": {"damage_numbers": damage_numbers, "debug_info": debug_info},
	}


## Profil relu depuis une sauvegarde (JSON : les nombres y sont des flottants). Les champs
## absents ou abîmés gardent leur valeur par défaut.
static func from_dict(data: Dictionary) -> Profile:
	var profile := Profile.new()
	for page: Variant in data.get("pages", []):
		profile.add_page(int(page))
	for item: Variant in data.get("items", []):
		if item is Dictionary:
			profile.items.append(ItemData.from_dict(item))
	for hint: Variant in data.get("hints_done", []):
		profile.mark_hint_done(StringName(str(hint)))
	var times: Variant = data.get("best_times", {})
	if times is Dictionary:
		for night: Variant in times:
			profile.best_times[int(night)] = float(times[night])
	profile.night_seed = int(data.get("night_seed", 0))
	profile.nights_done = int(data.get("nights_done", 0))
	var settings: Variant = data.get("settings", {})
	if settings is Dictionary:
		profile.damage_numbers = bool(settings.get("damage_numbers", profile.damage_numbers))
		profile.debug_info = bool(settings.get("debug_info", profile.debug_info))
	return profile
