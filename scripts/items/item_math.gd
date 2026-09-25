class_name ItemMath
## Règles des objets sans état : rareté tirée au sort, valeur d'un effet, objet complet.


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


## Valeur d'un effet : base × niveau d'objet × rareté × tirage × forge (docs/REGLAGES.md).
static func effect_value(base: float, item_level: int, rarity: ItemData.Rarity, roll: float, forge: int, tuning: TuningData) -> float:
	var level_factor: float = 1.0 + tuning.item_level_bonus * (item_level - 1)
	var forge_factor: float = 1.0 + tuning.item_forge_bonus * forge
	return base * level_factor * tuning.item_rarity_multipliers[rarity] * roll * forge_factor


## Tire un objet complet : emplacement, rareté (selon `weights`), effets différents.
static func roll_item(rng: RandomNumberGenerator, item_level: int, weights: PackedFloat32Array, tuning: TuningData) -> ItemData:
	var item := ItemData.new()
	item.level = item_level
	item.slot = rng.randi_range(0, ItemData.Slot.size() - 1) as ItemData.Slot
	item.rarity = rarity_for(rng.randf(), weights)
	var names: Array = tuning.item_effect_bases.keys()
	var count: int = mini(tuning.item_effects_per_rarity[item.rarity], names.size())
	for i: int in count:
		var effect: StringName = names.pop_at(rng.randi_range(0, names.size() - 1))
		var roll: float = rng.randf_range(tuning.item_roll_min, tuning.item_roll_max)
		item.effects[effect] = effect_value(tuning.item_effect_bases[effect], item_level, item.rarity, roll, item.forge, tuning)
	return item
