class_name Niches
extends RefCounted
## Les recoins des clairières (version 3.4) : de petits creux au bout d'un passage étroit, derrière
## la végétation (un fourré à trancher, ou un rideau de fougères qu'on traverse). Facultatifs : ils
## récompensent les curieux. Ce qu'ils cachent suit des règles de voisinage : un creux gardé par un
## fourré, ou bordé de rochers, cache plus souvent quelque chose de précieux.

## Des jarres ; un nid de plumes d'or ; une stèle des esprits (un don au choix entre deux) ; un Muet
## doré endormi (de l'or quand on le libère).
const JARS := &"jars"
const FEATHERS := &"feathers"
const STELE := &"stele"
const MUET := &"muet"
const KINDS: Array[StringName] = [JARS, FEATHERS, STELE, MUET]

## Poids de départ, puis ce qu'ajoute un fourré à trancher et chaque rocher qui borde l'entrée.
const BASE: Dictionary[StringName, float] = {JARS: 4.0, FEATHERS: 2.0, STELE: 0.5, MUET: 1.5}
const HIDDEN: Dictionary[StringName, float] = {JARS: -2.5, FEATHERS: 0.5, STELE: 1.5, MUET: 1.0}
const PER_ROCK: Dictionary[StringName, float] = {JARS: 0.0, FEATHERS: 1.5, STELE: 0.5, MUET: 0.0}


## Poids de chaque trouvaille pour un recoin caché derrière un fourré (`hidden`), bordé de `rocks`
## rochers ; sans Muets dans la clairière (`fight` faux), pas de Muet caché.
static func weights(hidden: bool, rocks: int, fight: bool) -> Dictionary[StringName, float]:
	var result: Dictionary[StringName, float] = {}
	for kind: StringName in KINDS:
		var w: float = BASE[kind] + (HIDDEN[kind] if hidden else 0.0) + PER_ROCK[kind] * rocks
		if kind == MUET and not fight:
			w = 0.0
		result[kind] = maxf(w, 0.0)
	return result


## Ce que cache le recoin, pour un tirage `roll` entre 0 et 1.
static func pick(roll: float, hidden: bool, rocks: int, fight: bool) -> StringName:
	var w: Dictionary[StringName, float] = weights(hidden, rocks, fight)
	var total: float = 0.0
	for kind: StringName in KINDS:
		total += w[kind]
	var at: float = roll * total
	for kind: StringName in KINDS:
		at -= w[kind]
		if at < 0.0:
			return kind
	return JARS
