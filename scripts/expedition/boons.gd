class_name Boons
## Dons des esprits de la jungle (expédition) : chacun change un coup ou une force du héros, et
## monte de rang si on le reprend. Les valeurs vivent dans Tuning (boon_values : don → valeur par
## rang). Version 2.8 : 25 dons en quatre familles (braise, rythme, racines, couleur), une rareté
## tirée pour chaque carte (commun : un rang, rare : deux, épique : trois, sans dépasser le rang
## maximal) et des dons doubles, qui demandent un don de chacune de leurs deux familles.

const BRAISE := &"braise"
const RYTHME := &"rythme"
const RACINES := &"racines"
const COULEUR := &"couleur"
const FAMILIES: Array[StringName] = [BRAISE, RYTHME, RACINES, COULEUR]

## Dons simples, dans l'ordre du carnet de l'expédition, et leur famille.
const IDS: Array[StringName] = [
	&"ember", &"meteor", &"fury", &"blaze", &"cinders", &"forge",
	&"metronome", &"echo", &"swift", &"syncopation", &"tempo", &"accent", &"counterpoint",
	&"heart", &"thorns", &"sap", &"bark", &"anchor", &"regrowth",
	&"hawk", &"prism", &"rainbow", &"splash", &"halo", &"dazzle",
]
const FAMILY: Dictionary[StringName, StringName] = {
	&"ember": BRAISE, &"meteor": BRAISE, &"fury": BRAISE, &"blaze": BRAISE, &"cinders": BRAISE, &"forge": BRAISE,
	&"metronome": RYTHME, &"echo": RYTHME, &"swift": RYTHME, &"syncopation": RYTHME, &"tempo": RYTHME,
	&"accent": RYTHME, &"counterpoint": RYTHME,
	&"heart": RACINES, &"thorns": RACINES, &"sap": RACINES, &"bark": RACINES, &"anchor": RACINES, &"regrowth": RACINES,
	&"hawk": COULEUR, &"prism": COULEUR, &"rainbow": COULEUR, &"splash": COULEUR, &"halo": COULEUR, &"dazzle": COULEUR,
}
## Dons doubles (un seul rang) et les deux familles qu'ils demandent.
const DUOS: Dictionary[StringName, Array] = {
	&"wildfire": [BRAISE, COULEUR], &"drumroll": [RYTHME, BRAISE],
	&"sacred_grove": [RACINES, RYTHME], &"bloom": [RACINES, COULEUR],
}

## Raretés d'une carte : rangs gagnés en la prenant.
const COMMON := &"common"
const RARE := &"rare"
const EPIC := &"epic"
const DUO := &"duo"
const RARITY_RANKS: Dictionary[StringName, int] = {COMMON: 1, RARE: 2, EPIC: 3, DUO: 1}


## Rang du don `id` parmi `owned` (don → rang), 0 s'il n'est pas pris.
static func rank(owned: Dictionary[StringName, int], id: StringName) -> int:
	return owned.get(id, 0)


## Valeur du don `id` au rang `level` (valeur par rang × rang).
static func value(id: StringName, level: int, tuning: TuningData) -> float:
	return tuning.boon_values.get(id, 0.0) * level


## Rang maximal du don `id` (un seul pour un don double).
static func max_rank(id: StringName, tuning: TuningData) -> int:
	return 1 if DUOS.has(id) else tuning.boon_max_rank


## Famille d'un don simple (vide pour un don double).
static func family(id: StringName) -> StringName:
	return FAMILY.get(id, &"")


## Familles dont au moins un don est pris.
static func owned_families(owned: Dictionary[StringName, int]) -> Array[StringName]:
	var families: Array[StringName] = []
	for id: StringName in owned:
		var f: StringName = family(id)
		if f != &"" and owned[id] > 0 and not families.has(f):
			families.append(f)
	return families


## Dons doubles possibles : leurs deux familles sont prises, et eux pas encore.
static func eligible_duos(owned: Dictionary[StringName, int]) -> Array[StringName]:
	var families: Array[StringName] = owned_families(owned)
	var duos: Array[StringName] = []
	for id: StringName in DUOS:
		var needs: Array = DUOS[id]
		if rank(owned, id) == 0 and families.has(needs[0]) and families.has(needs[1]):
			duos.append(id)
	return duos


## Offre de `count` dons simples différents, tirés parmi ceux qui ne sont pas au rang maximal
## (et de la famille `only`, si elle est donnée).
static func offer(rng: RandomNumberGenerator, owned: Dictionary[StringName, int], count: int, tuning: TuningData, only: StringName = &"") -> Array[StringName]:
	var pool: Array[StringName] = []
	for id: StringName in IDS:
		if rank(owned, id) < tuning.boon_max_rank and (only == &"" or family(id) == only):
			pool.append(id)
	var picks: Array[StringName] = []
	while picks.size() < count and not pool.is_empty():
		picks.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return picks


## Rareté tirée pour une carte (au moins `at_least`).
static func roll_rarity(rng: RandomNumberGenerator, tuning: TuningData, at_least: StringName = COMMON) -> StringName:
	var roll: float = rng.randf()
	var rarity: StringName = EPIC if roll < tuning.boon_epic_chance else (RARE if roll < tuning.boon_epic_chance + tuning.boon_rare_chance else COMMON)
	if at_least == EPIC or (at_least == RARE and rarity == COMMON):
		return at_least
	return rarity


## Cartes d'une offre : `count` dons (id, rareté) ; au moins `at_least` de rareté ; un don double
## possible prend parfois la dernière place (`duo_only` : seulement des dons doubles).
static func deal(rng: RandomNumberGenerator, owned: Dictionary[StringName, int], count: int, tuning: TuningData, at_least: StringName = COMMON, only: StringName = &"", duo_only: bool = false) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	var duos: Array[StringName] = eligible_duos(owned)
	if duo_only:
		while cards.size() < count and not duos.is_empty():
			cards.append({&"id": duos.pop_at(rng.randi_range(0, duos.size() - 1)), &"rarity": DUO})
		return cards
	for id: StringName in offer(rng, owned, count, tuning, only):
		cards.append({&"id": id, &"rarity": roll_rarity(rng, tuning, at_least)})
	if only == &"" and not duos.is_empty() and not cards.is_empty() and rng.randf() < tuning.boon_duo_chance:
		cards[cards.size() - 1] = {&"id": duos[rng.randi_range(0, duos.size() - 1)], &"rarity": DUO}
	return cards


## Rangs gagnés en prenant le don `id` de rareté `rarity` (sans dépasser le rang maximal).
static func ranks_gained(owned: Dictionary[StringName, int], id: StringName, rarity: StringName, tuning: TuningData) -> int:
	return clampi(RARITY_RANKS.get(rarity, 1), 0, max_rank(id, tuning) - rank(owned, id))


## Un don déjà pris et pas encore au rang maximal, tiré au hasard (vide : aucun) : le feu de camp
## l'affûte d'un rang.
static func sharpen_pick(rng: RandomNumberGenerator, owned: Dictionary[StringName, int], tuning: TuningData) -> StringName:
	var pool: Array[StringName] = []
	for id: StringName in IDS:
		var level: int = rank(owned, id)
		if level > 0 and level < tuning.boon_max_rank:
			pool.append(id)
	return pool[rng.randi_range(0, pool.size() - 1)] if not pool.is_empty() else &""
