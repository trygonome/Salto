class_name Pacts
## Pactes de difficulté (version 2.9) : choisis au village avant de partir (la pierre des pactes),
## ils rendent l'expédition plus rude contre plus de plumes d'or rapportées :
##  - peaux épaisses : les Muets ont plus de PV ;
##  - coups rudes : les Muets frappent plus fort ;
##  - cœur fragile : le héros part avec moins de PV ;
##  - jungle avare : plus de soin ni de repos parmi les passages, pas de soin dans les jarres.
## Logique pure : les valeurs viennent de Tuning (pact_*).

const THICK_SKIN := &"thick_skin"
const HARD_HITS := &"hard_hits"
const FRAGILE := &"fragile"
const STINGY := &"stingy"
const IDS: Array[StringName] = [THICK_SKIN, HARD_HITS, FRAGILE, STINGY]


## Plumes d'or rapportées multipliées par ce nombre (1 : aucun pacte).
static func feather_multiplier(pacts: Array[StringName], tuning: TuningData) -> float:
	var bonus: float = 0.0
	for id: StringName in pacts:
		bonus += tuning.pact_bonus.get(id, 0.0)
	return 1.0 + bonus


## Active ou retire le pacte `id` ; renvoie la nouvelle liste.
static func toggle(pacts: Array[StringName], id: StringName) -> Array[StringName]:
	var result: Array[StringName] = pacts.duplicate()
	if result.has(id):
		result.erase(id)
	elif IDS.has(id):
		result.append(id)
	return result
