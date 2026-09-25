class_name ItemMath
## Règles des objets sans état, comme dans le prototype : effets possibles par emplacement,
## légendaires, rareté tirée au sort, valeur d'un effet, objet complet, objets de départ, forge
## et recyclage.

## Effets possibles par emplacement.
const SLOT_EFFECTS := {
	ItemData.Slot.ANKLETS: [&"damage", &"speed", &"attack_speed", &"dive", &"crit"],
	ItemData.Slot.MASK: [&"health", &"resistance", &"heal_per_muet", &"xp", &"damage"],
	ItemData.Slot.TALISMAN: [&"groove", &"crit", &"heal_per_muet", &"xp", &"health", &"dive"],
}
## Effets comptés en nombre (PV) ; les autres sont des pourcentages.
const FLAT_EFFECTS: Array[StringName] = [&"health", &"heal_per_muet"]
## Objets légendaires et leur emplacement.
const LEGENDARIES := {
	&"finale": ItemData.Slot.ANKLETS, &"shadow": ItemData.Slot.ANKLETS, &"phoenix": ItemData.Slot.MASK,
	&"heart": ItemData.Slot.TALISMAN, &"storm": ItemData.Slot.TALISMAN,
}
## Objets de départ : un effet chacun, tirage moyen.
const STARTER := {
	ItemData.Slot.ANKLETS: &"damage", ItemData.Slot.MASK: &"health", ItemData.Slot.TALISMAN: &"groove",
}
## Un pourcentage s'arrondit au centième.
const PERCENT_STEP := 0.01


## Rareté pour un tirage `roll` (0 à 1) dans une table de poids (commun, rare, épique, légendaire).
static func rarity_for(roll: float, weights: PackedFloat32Array) -> ItemData.Rarity:
	var total: float = 0.0
	for weight: float in weights:
		total += weight
	var threshold: float = roll * total
	for i: int in weights.size():
		threshold -= weights[i]
		if threshold < 0.0:
			return i as ItemData.Rarity
	return (weights.size() - 1) as ItemData.Rarity


## Valeur de l'effet `effect` de `item` : base × niveau × rareté × tirage × forge, arrondie
## (au moins 1 PV ou 1 %).
static func effect_value(item: ItemData, effect: StringName, tuning: TuningData) -> float:
	var level_factor: float = 1.0 + tuning.item_level_bonus * (item.level - 1)
	var forge_factor: float = 1.0 + tuning.item_forge_bonus * item.forge
	var raw: float = tuning.item_effect_bases[effect] * level_factor * tuning.item_rarity_multipliers[item.rarity] * item.rolls.get(effect, 1.0) * forge_factor
	if FLAT_EFFECTS.has(effect):
		return maxf(1.0, roundf(raw))
	return maxf(PERCENT_STEP, snappedf(raw, PERCENT_STEP))


## Tire un objet complet de niveau `item_level` : rareté selon `weights` ; un légendaire a son
## effet unique et son emplacement ; les autres effets sont tirés parmi ceux de l'emplacement.
static func roll_item(rng: RandomNumberGenerator, item_level: int, weights: PackedFloat32Array, tuning: TuningData) -> ItemData:
	var item := ItemData.new()
	item.level = maxi(1, item_level)
	item.rarity = rarity_for(rng.randf(), weights)
	if item.rarity == ItemData.Rarity.LEGENDARY:
		var names: Array = LEGENDARIES.keys()
		item.legendary = names[rng.randi_range(0, names.size() - 1)]
		item.slot = LEGENDARIES[item.legendary]
	else:
		item.slot = rng.randi_range(0, ItemData.Slot.size() - 1) as ItemData.Slot
	var pool: Array = (SLOT_EFFECTS[item.slot] as Array).duplicate()
	var count: int = mini(tuning.item_effects_per_rarity[item.rarity], pool.size())
	for i: int in count:
		var effect: StringName = pool.pop_at(rng.randi_range(0, pool.size() - 1))
		item.rolls[effect] = snappedf(rng.randf_range(tuning.item_roll_min, tuning.item_roll_max), PERCENT_STEP)
	return item


## Les trois objets de départ, portés dès la première sortie.
static func starter_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for slot: ItemData.Slot in STARTER:
		var item := ItemData.new()
		item.slot = slot
		item.rolls[STARTER[slot]] = 1.0
		item.is_new = false
		items.append(item)
	return items


## Plumes rendues en recyclant `item`.
static func recycle_value(item: ItemData, tuning: TuningData) -> int:
	return (tuning.item_recycle_base + tuning.item_recycle_per_rarity * item.rarity) * item.level + tuning.item_recycle_per_forge * item.forge


## Plumes que coûte le prochain niveau de forge de `item`.
static func forge_cost(item: ItemData, tuning: TuningData) -> int:
	return tuning.item_forge_cost * (item.forge + 1) * (item.rarity + 1)


## Somme des effets de plusieurs objets.
static func total_effects(items: Array[ItemData]) -> Dictionary[StringName, float]:
	var total: Dictionary[StringName, float] = {}
	for item: ItemData in items:
		var values: Dictionary[StringName, float] = item.effect_values()
		for effect: StringName in values:
			total[effect] = total.get(effect, 0.0) + values[effect]
	return total
