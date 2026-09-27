class_name WaveComposer
## Vagues composées (version 2.4) : des rôles qui se complètent plutôt qu'un tirage au hasard. Chaque
## modèle donne ses Muets (ceux de devant d'abord) et la clairière à partir de laquelle il peut
## venir ; des sautillants et des volants s'y ajoutent à mesure qu'on avance.
##  - meute : des sautillants ; essaim : sautillants et volants ;
##  - mur : un porte-bouclier devant, deux cracheurs derrière ;
##  - cavalerie : un cornu et des sautillants ; ronces : un tisserand, un sautillant, un cracheur ;
##  - bal : deux danseurs et un volant ; chœur : un totem chanteur qui protège un porte-bouclier ;
##  - brutes : une brute avec un sautillant et un cracheur ; fanfare : totem, brute, danseur, tisserand.

const TEMPLATES: Array[Dictionary] = [
	{&"id": &"pack", &"from": 0, &"foes": [&"hopper", &"hopper", &"hopper"]},
	{&"id": &"swarm", &"from": 1, &"foes": [&"hopper", &"flyer", &"flyer"]},
	{&"id": &"wall", &"from": 1, &"foes": [&"shielder", &"spitter", &"spitter"]},
	{&"id": &"cavalry", &"from": 2, &"foes": [&"charger", &"hopper", &"hopper"]},
	{&"id": &"brambles", &"from": 2, &"foes": [&"weaver", &"hopper", &"spitter"]},
	{&"id": &"ball", &"from": 2, &"foes": [&"dancer", &"dancer", &"flyer"]},
	{&"id": &"choir", &"from": 3, &"foes": [&"totem", &"shielder", &"hopper", &"hopper"]},
	{&"id": &"brutes", &"from": 3, &"foes": [&"brute", &"hopper", &"spitter"]},
	{&"id": &"fanfare", &"from": 4, &"foes": [&"totem", &"brute", &"dancer", &"weaver"]},
]
## Muets ajoutés à mesure qu'on avance, en alternance.
const FILLERS: Array[StringName] = [&"hopper", &"flyer"]
## Espèces qui se tiennent en retrait (elles apparaissent plus loin du héros).
const BACK_ROW: Array[StringName] = [&"spitter", &"weaver", &"totem"]


## Modèles possibles dans la clairière `room` (0 : la première).
static func available(room: int) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for template: Dictionary in TEMPLATES:
		if int(template[&"from"]) <= room:
			list.append(template)
	return list


## Compose une vague de la clairière `room` : un modèle possible tiré par `rng` (pas `avoid`, le
## modèle de la vague précédente, s'il y a le choix), complété jusqu'à `count` Muets. Renvoie
## { id, foes }.
static func compose(room: int, count: int, rng: RandomNumberGenerator, avoid: StringName = &"") -> Dictionary:
	var pool: Array[Dictionary] = available(room)
	if pool.size() > 1:
		pool = pool.filter(func(template: Dictionary) -> bool: return template[&"id"] != avoid)
	var template: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var foes: Array[StringName] = []
	for species: StringName in template[&"foes"]:
		foes.append(species)
	var k: int = 0
	while foes.size() < count:
		foes.append(FILLERS[k % FILLERS.size()])
		k += 1
	return {&"id": template[&"id"], &"foes": foes}


## Vrai si l'espèce se tient en retrait.
static func back_row(species: StringName) -> bool:
	return BACK_ROW.has(species)
