class_name ItemData
extends RefCounted
## Un objet du prototype : emplacement (chevillières, masque, talisman), rareté, niveau, effets
## tirés au sort (effet → tirage, la valeur découle aussi du niveau et de la rareté) et, pour un
## objet légendaire, son effet unique.

enum Slot { ANKLETS, MASK, TALISMAN }
enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

## Numéro unique dans le sac (0 : pas encore rangé).
var id: int = 0
var slot: Slot = Slot.ANKLETS
var rarity: Rarity = Rarity.COMMON
var level: int = 1
## Tirage de chaque effet (autour de 1).
var rolls: Dictionary[StringName, float] = {}
## Effet légendaire (vide : aucun), voir ItemMath.LEGENDARIES.
var legendary: StringName = &""
## Pas encore regardé dans le sac.
var is_new: bool = true


## Valeur de chaque effet (fraction pour les pourcentages, nombre pour les PV).
func effect_values() -> Dictionary[StringName, float]:
	var values: Dictionary[StringName, float] = {}
	for effect: StringName in rolls:
		values[effect] = ItemMath.effect_value(self, effect, Tuning.data)
	return values


## L'objet sous forme de dictionnaire (sauvegarde).
func to_dict() -> Dictionary:
	var saved_rolls: Dictionary = {}
	for effect: StringName in rolls:
		saved_rolls[String(effect)] = rolls[effect]
	return {
		"id": id, "slot": slot, "rarity": rarity, "level": level, "rolls": saved_rolls,
		"legendary": String(legendary), "new": is_new,
	}


## Objet relu depuis un dictionnaire de sauvegarde (les champs absents gardent leur valeur
## par défaut ; les objets de la première version gardent leurs effets, tirage moyen).
static func from_dict(data: Dictionary) -> ItemData:
	var item := ItemData.new()
	item.id = int(data.get("id", 0))
	item.slot = clampi(int(data.get("slot", 0)), 0, Slot.size() - 1) as Slot
	item.rarity = clampi(int(data.get("rarity", 0)), 0, Rarity.size() - 1) as Rarity
	item.level = maxi(1, int(data.get("level", 1)))
	var saved_rolls: Variant = data.get("rolls", data.get("effects", {}))
	if saved_rolls is Dictionary:
		var old: bool = not data.has("rolls")
		for effect: Variant in saved_rolls:
			if Tuning.data.item_effect_bases.has(StringName(str(effect))):
				item.rolls[StringName(str(effect))] = 1.0 if old else float(saved_rolls[effect])
	var legendary: String = str(data.get("legendary", ""))
	item.legendary = StringName(legendary) if ItemMath.LEGENDARIES.has(StringName(legendary)) else &""
	item.is_new = bool(data.get("new", false))
	return item
