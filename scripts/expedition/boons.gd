class_name Boons
## Dons des esprits de la jungle (expédition) : chacun change un coup ou une force du héros, et
## monte de rang si on le reprend. Les valeurs vivent dans Tuning (boon_values : don → valeur par
## rang). Version 2.8 : 25 dons en quatre familles (feu, eau, sève, vent depuis la 3.1), une rareté
## tirée pour chaque carte (commun : un rang, rare : deux, épique : trois, sans dépasser le rang
## maximal) et des dons doubles, qui demandent un don de chacune de leurs deux familles.

const FEU := &"feu"
const EAU := &"eau"
const SEVE := &"seve"
const VENT := &"vent"
const FAMILIES: Array[StringName] = [FEU, EAU, SEVE, VENT]

## Dons simples, dans l'ordre du carnet de l'expédition, et leur famille (version 3.1 : les quatre
## esprits, chacun sa couleur — Feu rouge : dégâts ; Eau bleue : protection ; Sève verte : soin ;
## Vent jaune : vitesse et groove).
const IDS: Array[StringName] = [
	&"ember", &"meteor", &"fury", &"blaze", &"cinders", &"forge", &"prism",
	&"bark", &"counterpoint", &"dazzle", &"mist", &"tide", &"frost",
	&"heart", &"thorns", &"sap", &"regrowth", &"anchor",
	&"swift", &"tempo", &"halo", &"splash", &"rainbow", &"echo", &"hawk",
]
const FAMILY: Dictionary[StringName, StringName] = {
	&"ember": FEU, &"meteor": FEU, &"fury": FEU, &"blaze": FEU, &"cinders": FEU, &"forge": FEU, &"prism": FEU,
	&"bark": EAU, &"counterpoint": EAU, &"dazzle": EAU, &"mist": EAU, &"tide": EAU, &"frost": EAU,
	&"heart": SEVE, &"thorns": SEVE, &"sap": SEVE, &"regrowth": SEVE, &"anchor": SEVE,
	&"swift": VENT, &"tempo": VENT, &"halo": VENT, &"splash": VENT, &"rainbow": VENT, &"echo": VENT, &"hawk": VENT,
}
## Dons doubles (un seul rang) et les deux familles qu'ils demandent.
const DUOS: Dictionary[StringName, Array] = {
	&"wildfire": [FEU, VENT], &"geyser": [EAU, FEU],
	&"sacred_grove": [SEVE, EAU], &"bloom": [SEVE, VENT],
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


## Famille qui a reçu le plus de rangs parmi `boons` (id → rang ; les dons doubles ne comptent pas) ;
## vide si aucun don (version 3.7 : le Chef en parle).
static func dominant_family(boons: Dictionary) -> StringName:
	var best: StringName = &""
	var best_ranks: int = 0
	for fam: StringName in [FEU, EAU, SEVE, VENT]:
		var ranks: int = 0
		for id: StringName in boons:
			if not DUOS.has(id) and family(id) == fam:
				ranks += int(boons[id])
		if ranks > best_ranks:
			best = fam
			best_ranks = ranks
	return best


## Vrai si `boons` contient un don double.
static func has_duo(boons: Dictionary) -> bool:
	for id: StringName in boons:
		if DUOS.has(id) and int(boons[id]) > 0:
			return true
	return false


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
