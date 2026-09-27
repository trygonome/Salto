class_name RunState
extends RefCounted
## Une expédition : suite de clairières générées, la dernière gardée par un Grand Muet. Garde la
## graine, la clairière en cours, la récompense promise par le passage choisi, les dons pris, les
## plumes gagnées et ce qui compte pour le résumé. Tirages reproductibles depuis la graine.

## Récompenses d'une clairière : don des esprits (1 parmi 3), soin, plumes ; le Grand Muet
## (dernière clairière : le libérer termine l'expédition).
const BOON := &"boon"
const HEAL := &"heal"
const FEATHERS := &"feathers"
const BOSS := &"boss"
const REWARDS: Array[StringName] = [BOON, HEAL, FEATHERS]

var seed_value: int = 0
## Clairières de l'expédition (la dernière : le Grand Muet) ; clairière en cours (0 : la première).
var room_count: int = 0
var room: int = 0
## Récompense de la clairière en cours, donnée quand elle est nettoyée.
var reward: StringName = BOON
## Dons pris (don → rang).
var boons: Dictionary[StringName, int] = {}
var feathers: int = 0
var muets_freed: int = 0
var elapsed: float = 0.0
var rng := RandomNumberGenerator.new()


func _init(seed_number: int, rooms: int) -> void:
	seed_value = seed_number
	room_count = rooms
	rng.seed = seed_number


## Vrai dans la dernière clairière (le Grand Muet).
func is_boss_room() -> bool:
	return room >= room_count - 1


## Graine de la clairière en cours (même expédition, mêmes clairières).
func room_seed() -> int:
	return hash([seed_value, room])


## Nombre de passages de sortie de la clairière en cours (un seul vers le Grand Muet).
func exit_count(count: int) -> int:
	return 1 if room + 1 >= room_count - 1 else count


## Récompenses proposées par les passages de sortie (`count` différentes ; vers la dernière
## clairière, le Grand Muet).
func exit_rewards(count: int) -> Array[StringName]:
	if room + 1 >= room_count - 1:
		return [BOSS] as Array[StringName]
	var pool: Array[StringName] = REWARDS.duplicate()
	var picks: Array[StringName] = []
	while picks.size() < count and not pool.is_empty():
		picks.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return picks


## Passe à la clairière suivante, qui promet `promised`.
func enter_next(promised: StringName) -> void:
	room += 1
	reward = promised


## Prend le don `id` (ou le monte d'un rang).
func take_boon(id: StringName) -> void:
	boons[id] = boons.get(id, 0) + 1


## Nombre de rangs de dons pris.
func boon_ranks() -> int:
	var total: int = 0
	for id: StringName in boons:
		total += boons[id]
	return total
