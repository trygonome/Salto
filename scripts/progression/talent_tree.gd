class_name TalentTree
## Talents du prototype : trois voies de quatre talents (Acrobate, Percussion, Chamane). Chaque
## niveau gagné donne un point ; un talent n'est ouvert qu'après avoir mis assez de points dans sa
## voie (deux par rang). Les effets chiffrés vivent dans Tuning (talent_*).

enum Branch { ACROBAT, PERCUSSION, SHAMAN }

## Talents dans l'ordre de chaque voie : identifiant, voie, rangs.
const TALENTS: Array[Dictionary] = [
	{&"id": &"feet", &"branch": Branch.ACROBAT, &"max": 3},
	{&"id": &"triple", &"branch": Branch.ACROBAT, &"max": 1},
	{&"id": &"dash2", &"branch": Branch.ACROBAT, &"max": 1},
	{&"id": &"comet", &"branch": Branch.ACROBAT, &"max": 2},
	{&"id": &"metro", &"branch": Branch.PERCUSSION, &"max": 3},
	{&"id": &"drum", &"branch": Branch.PERCUSSION, &"max": 3},
	{&"id": &"roll", &"branch": Branch.PERCUSSION, &"max": 2},
	{&"id": &"finale", &"branch": Branch.PERCUSSION, &"max": 1},
	{&"id": &"breath", &"branch": Branch.SHAMAN, &"max": 3},
	{&"id": &"sap", &"branch": Branch.SHAMAN, &"max": 2},
	{&"id": &"bark", &"branch": Branch.SHAMAN, &"max": 2},
	{&"id": &"second", &"branch": Branch.SHAMAN, &"max": 1},
]
## Points à mettre dans une voie avant d'ouvrir chaque rang suivant.
const POINTS_PER_TIER := 2


static func talent(id: StringName) -> Dictionary:
	for t: Dictionary in TALENTS:
		if t[&"id"] == id:
			return t
	return {}


static func branch_talents(branch: Branch) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for t: Dictionary in TALENTS:
		if t[&"branch"] == branch:
			list.append(t)
	return list


## Points dépensés dans la voie `branch` (rangs par talent dans `ranks`).
static func spent_in(branch: Branch, ranks: Dictionary) -> int:
	var total: int = 0
	for t: Dictionary in branch_talents(branch):
		total += int(ranks.get(t[&"id"], 0))
	return total


## Points à mettre dans sa voie pour ouvrir le talent `id`.
static func required_points(id: StringName) -> int:
	var t: Dictionary = talent(id)
	return branch_talents(t[&"branch"]).find(t) * POINTS_PER_TIER


## Vrai si le talent `id` peut prendre un rang de plus avec `points` points à dépenser.
static func can_buy(id: StringName, ranks: Dictionary, points: int) -> bool:
	var t: Dictionary = talent(id)
	if t.is_empty() or points <= 0 or int(ranks.get(id, 0)) >= int(t[&"max"]):
		return false
	return spent_in(t[&"branch"], ranks) >= required_points(id)


## Total des points dépensés.
static func spent(ranks: Dictionary) -> int:
	var total: int = 0
	for id: Variant in ranks:
		total += int(ranks[id])
	return total
