class_name ProtoRandom
extends RefCounted
## Générateur pseudo-aléatoire du prototype (mulberry32) : pour une même graine, il donne exactement
## les mêmes tirages que le prototype, donc le même monde. Calculs en entiers non signés de 32 bits.

const MASK := 0xFFFFFFFF
const INCREMENT := 0x6D2B79F5
const RANGE := 4294967296.0

var _state: int = 0


func _init(seed_value: int) -> void:
	_state = seed_value & MASK


## Tirage suivant, de 0 (compris) à 1 (exclu).
func next() -> float:
	_state = (_state + INCREMENT) & MASK
	var t: int = _imul(_state ^ (_state >> 15), 1 | _state)
	t = ((t + _imul(t ^ (t >> 7), 61 | t)) & MASK) ^ t
	return float((t ^ (t >> 14)) & MASK) / RANGE


## Produit sur 32 bits (Math.imul), sans dépasser les entiers de 64 bits.
static func _imul(a: int, b: int) -> int:
	var low: int = (a & 0xFFFF) * b
	var high: int = (((a >> 16) & 0xFFFF) * b) & 0xFFFF
	return (low + (high << 16)) & MASK
