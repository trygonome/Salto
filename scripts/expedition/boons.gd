class_name Boons
## Dons des esprits de la jungle (expédition) : chacun change un coup ou une force du héros, et
## monte de rang si on le reprend. Les valeurs vivent dans Tuning (boon_values : don → valeur par
## rang). Tirage de l'offre : trois dons différents qui ne sont pas encore au rang maximal.

## Dons, dans l'ordre du carnet de l'expédition.
const IDS: Array[StringName] = [
	&"ember", &"echo", &"thorns", &"meteor", &"heart", &"metronome", &"sap", &"fury", &"swift", &"hawk",
]


## Rang du don `id` parmi `owned` (don → rang), 0 s'il n'est pas pris.
static func rank(owned: Dictionary[StringName, int], id: StringName) -> int:
	return owned.get(id, 0)


## Valeur du don `id` au rang `level` (valeur par rang × rang).
static func value(id: StringName, level: int, tuning: TuningData) -> float:
	return tuning.boon_values.get(id, 0.0) * level


## Offre de `count` dons différents, tirés parmi ceux qui ne sont pas au rang maximal.
static func offer(rng: RandomNumberGenerator, owned: Dictionary[StringName, int], count: int, tuning: TuningData) -> Array[StringName]:
	var pool: Array[StringName] = []
	for id: StringName in IDS:
		if rank(owned, id) < tuning.boon_max_rank:
			pool.append(id)
	var picks: Array[StringName] = []
	while picks.size() < count and not pool.is_empty():
		picks.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return picks


## Un don déjà pris et pas encore au rang maximal, tiré au hasard (vide : aucun) : le feu de camp
## l'affûte d'un rang.
static func sharpen_pick(rng: RandomNumberGenerator, owned: Dictionary[StringName, int], tuning: TuningData) -> StringName:
	var pool: Array[StringName] = []
	for id: StringName in IDS:
		var level: int = rank(owned, id)
		if level > 0 and level < tuning.boon_max_rank:
			pool.append(id)
	return pool[rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else &""
