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
