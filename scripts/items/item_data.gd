class_name ItemData
extends RefCounted
## Un objet : son emplacement, sa rareté, son niveau et ses effets (nom d'effet → valeur).

enum Slot { ANKLETS, MASK, TALISMAN }
enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

var slot: Slot = Slot.ANKLETS
var rarity: Rarity = Rarity.COMMON
var level: int = 1
## Niveau de forge (de 0 à 5).
var forge: int = 0
var effects: Dictionary[StringName, float] = {}


## L'objet sous forme de dictionnaire (sauvegarde).
func to_dict() -> Dictionary:
	var saved_effects: Dictionary = {}
	for effect: StringName in effects:
		saved_effects[String(effect)] = effects[effect]
	return {"slot": slot, "rarity": rarity, "level": level, "forge": forge, "effects": saved_effects}


## Objet relu depuis un dictionnaire de sauvegarde (les champs absents gardent leur valeur
## par défaut).
static func from_dict(data: Dictionary) -> ItemData:
	var item := ItemData.new()
	item.slot = clampi(int(data.get("slot", 0)), 0, Slot.size() - 1) as Slot
	item.rarity = clampi(int(data.get("rarity", 0)), 0, Rarity.size() - 1) as Rarity
	item.level = int(data.get("level", 1))
	item.forge = int(data.get("forge", 0))
	var saved_effects: Dictionary = data.get("effects", {})
	for effect: String in saved_effects:
		item.effects[StringName(effect)] = float(saved_effects[effect])
	return item
