class_name Profile
extends RefCounted
## Ce qui se garde d'une sortie à l'autre et d'une partie à l'autre, comme la saga du prototype :
## la nuit en cours (graine du monde, tambours déjà rapportés, Muets libérés venus au village,
## sorties), les nuits accomplies, le
## niveau, l'expérience et les talents, le sac et l'équipement, les aides déjà suivies, les
## réglages. S'écrit et se relit en dictionnaire.

## Version du format de sauvegarde (les versions précédentes se relisent : leurs champs sont
## repris, ceux qui n'existent plus sont ignorés).
const VERSION := 3
## Tambours par nuit (un par sanctuaire).
const DRUMS := 3

## Une partie a commencé (l'écran titre propose de continuer).
var started: bool = false
## Nuit en cours (1 à 5, puis les nuits sans fin).
var night: int = 1
## Graine du monde de la nuit en cours (0 : pas encore tirée) : le monde reste le même d'une
## sortie à l'autre, et change à la nuit suivante.
var night_seed: int = 0
## Nuits accomplies (le totem du village grandit) ; la cinquième achève la saga.
var nights_done: int = 0
var finished: bool = false
## Tambours déjà rapportés au village cette nuit, par sanctuaire : ils y restent.
var banked: Array[bool] = [false, false, false]
## Muets libérés cette nuit qui dansent au village (espèce ; &"boss", &"king" : Grands Muets).
var band: Array[StringName] = []
## Sorties cette nuit, et en tout.
var sortie: int = 0
var total_sorties: int = 0
## Niveau, expérience vers le niveau suivant, points de talent à dépenser, rangs des talents.
var level: int = 1
var xp: float = 0.0
var talent_points: int = 0
var talents: Dictionary[StringName, int] = {}
## Sac (objets portés compris) et objet porté à chaque emplacement (numéro, 0 : aucun).
var items: Array[ItemData] = []
var equipped: Dictionary[int, int] = {}
var next_item_id: int = 1
## Pages du carnet trouvées (numéros à partir de 1), dans l'ordre où on les a trouvées.
var pages: Array[int] = []
## Aides contextuelles déjà suivies : elles ne reviennent plus.
var hints_done: Array[StringName] = []
## Réglages : chiffres de dégâts, infos de mise au point (versions de test), son coupé.
var damage_numbers: bool = true
var debug_info: bool = false
var muted: bool = false


## Profil d'une nouvelle partie : les objets de départ sont dans le sac, et portés.
static func create() -> Profile:
	var profile := Profile.new()
	profile.give_starter_items()
	return profile


## Ajoute une page ; renvoie faux si elle était déjà dans le carnet.
func add_page(page: int) -> bool:
	if pages.has(page):
		return false
	pages.append(page)
	return true


func has_page(page: int) -> bool:
	return pages.has(page)


## Range un objet dans le sac ; s'il est plein, le plus faible des objets non portés lui laisse
## sa place.
func add_item(item: ItemData) -> void:
	if items.size() >= Tuning.data.item_inventory_max:
		var weakest: ItemData = null
		for other: ItemData in items:
			if not is_equipped(other) and (weakest == null or ItemMath.weaker(other, weakest)):
				weakest = other
		if weakest:
			items.erase(weakest)
	item.id = next_item_id
	next_item_id += 1
	items.append(item)


func item_by_id(id: int) -> ItemData:
	for item: ItemData in items:
		if item.id == id:
			return item
	return null


## Objet porté à l'emplacement `slot` (ou null).
func equipped_item(slot: ItemData.Slot) -> ItemData:
	return item_by_id(equipped.get(slot, 0))


func equipped_items() -> Array[ItemData]:
	var list: Array[ItemData] = []
	for slot: int in ItemData.Slot.values():
		var item: ItemData = equipped_item(slot as ItemData.Slot)
		if item:
			list.append(item)
	return list


func is_equipped(item: ItemData) -> bool:
	return equipped.get(item.slot, 0) == item.id


func equip(item: ItemData) -> void:
	equipped[item.slot] = item.id
	item.is_new = false


## Donne les objets de départ (sac vide) et les porte.
func give_starter_items() -> void:
	for item: ItemData in ItemMath.starter_items():
		add_item(item)
		equip(item)


func talent_rank(id: StringName) -> int:
	return talents.get(id, 0)


## Prend un rang du talent `id` si c'est possible ; renvoie vrai si c'est fait.
func buy_talent(id: StringName) -> bool:
	if not TalentTree.can_buy(id, talents, talent_points):
		return false
	talents[id] = talent_rank(id) + 1
	talent_points -= 1
	return true


## Rend tous les points dépensés.
func reset_talents() -> void:
	talent_points += TalentTree.spent(talents)
	talents.clear()


## Ajoute de l'expérience ; renvoie le nombre de niveaux gagnés (un point de talent chacun).
func add_xp(amount: float) -> int:
	var result: Dictionary = ProgressionMath.add_xp(level, xp, amount, Tuning.data)
	level = result[&"level"]
	xp = result[&"xp"]
	talent_points += result[&"gained"]
	return result[&"gained"]


## Nombre de tambours déjà rapportés cette nuit.
func banked_count() -> int:
	return banked.count(true)


## Une nouvelle sortie commence dans la nuit en cours.
func begin_sortie() -> void:
	started = true
	sortie += 1
	total_sorties += 1


## La nuit en cours est accomplie : la suivante a un nouveau monde, ses tambours sont à reprendre.
## Renvoie vrai si la saga vient de s'achever (cinquième nuit).
func complete_current_night() -> bool:
	var tuning: TuningData = Tuning.data
	nights_done = maxi(nights_done, night)
	var finale: bool = night == tuning.saga_nights and not finished
	if finale:
		finished = true
	night += 1
	night_seed = 0
	banked = [false, false, false]
	band.clear()
	sortie = 0
	return finale


## Note une aide comme suivie ; renvoie faux si elle l'était déjà.
func mark_hint_done(hint: StringName) -> bool:
	if hints_done.has(hint):
		return false
	hints_done.append(hint)
	return true


func is_hint_done(hint: StringName) -> bool:
	return hints_done.has(hint)


func to_dict() -> Dictionary:
	var saved_items: Array = []
	for item: ItemData in items:
		saved_items.append(item.to_dict())
	var saved_hints: Array = []
	for hint: StringName in hints_done:
		saved_hints.append(String(hint))
	var saved_band: Array = []
	for species: StringName in band:
		saved_band.append(String(species))
	var saved_talents: Dictionary = {}
	for id: StringName in talents:
		saved_talents[String(id)] = talents[id]
	var saved_equipped: Dictionary = {}
	for slot: int in equipped:
		saved_equipped[str(slot)] = equipped[slot]
	return {
		"version": VERSION,
		"started": started, "night": night, "night_seed": night_seed, "nights_done": nights_done,
		"finished": finished, "banked": banked.duplicate(), "band": saved_band,
		"sortie": sortie, "total_sorties": total_sorties,
		"level": level, "xp": xp, "talent_points": talent_points, "talents": saved_talents,
		"items": saved_items, "equipped": saved_equipped, "next_item_id": next_item_id,
		"pages": pages.duplicate(), "hints_done": saved_hints,
		"settings": {"damage_numbers": damage_numbers, "debug_info": debug_info, "muted": muted},
	}


## Profil relu depuis une sauvegarde (JSON : les nombres y sont des flottants). Les champs
## absents ou abîmés gardent leur valeur par défaut ; les objets sans numéro en reçoivent un, et
## un sac vide reçoit les objets de départ.
static func from_dict(data: Dictionary) -> Profile:
	var profile := Profile.new()
	profile.started = bool(data.get("started", int(data.get("nights_done", 0)) > 0))
	profile.night = maxi(1, int(data.get("night", int(data.get("nights_done", 0)) + 1)))
	profile.night_seed = int(data.get("night_seed", 0))
	profile.nights_done = int(data.get("nights_done", 0))
	profile.finished = bool(data.get("finished", false))
	var saved_banked: Variant = data.get("banked", [])
	if saved_banked is Array:
		for i: int in mini((saved_banked as Array).size(), DRUMS):
			profile.banked[i] = bool(saved_banked[i])
	var saved_band: Variant = data.get("band", [])
	if saved_band is Array:
		for species: Variant in saved_band:
			profile.band.append(StringName(str(species)))
	profile.sortie = int(data.get("sortie", 0))
	profile.total_sorties = int(data.get("total_sorties", 0))
	profile.level = maxi(1, int(data.get("level", 1)))
	profile.xp = float(data.get("xp", 0.0))
	profile.talent_points = int(data.get("talent_points", 0))
	var saved_talents: Variant = data.get("talents", {})
	if saved_talents is Dictionary:
		for id: Variant in saved_talents:
			if not TalentTree.talent(StringName(str(id))).is_empty():
				profile.talents[StringName(str(id))] = int(saved_talents[id])
	for item: Variant in data.get("items", []):
		if item is Dictionary:
			profile.items.append(ItemData.from_dict(item))
	profile.next_item_id = int(data.get("next_item_id", 1))
	for item: ItemData in profile.items:
		if item.id == 0 or profile.items.filter(func(other: ItemData) -> bool: return other.id == item.id).size() > 1:
			item.id = profile.next_item_id
			profile.next_item_id += 1
		profile.next_item_id = maxi(profile.next_item_id, item.id + 1)
	var saved_equipped: Variant = data.get("equipped", {})
	if saved_equipped is Dictionary:
		for slot: Variant in saved_equipped:
			var item: ItemData = profile.item_by_id(int(saved_equipped[slot]))
			if item and item.slot == int(slot):
				profile.equipped[int(slot)] = item.id
	if profile.items.is_empty():
		profile.give_starter_items()
	for page: Variant in data.get("pages", []):
		profile.add_page(int(page))
	for hint: Variant in data.get("hints_done", []):
		profile.mark_hint_done(StringName(str(hint)))
	var settings: Variant = data.get("settings", {})
	if settings is Dictionary:
		profile.damage_numbers = bool(settings.get("damage_numbers", profile.damage_numbers))
		profile.debug_info = bool(settings.get("debug_info", profile.debug_info))
		profile.muted = bool(settings.get("muted", profile.muted))
	return profile
