class_name GrooveGauge
extends RefCounted
## Jauge de groove : se remplit en jouant en rythme ; pleine, elle débloque le Salto arc-en-ciel.

## Valeur actuelle, de 0 à `maximum`.
var value: float = 0.0
var maximum: float


func _init(gauge_maximum: float) -> void:
	maximum = gauge_maximum


func add(amount: float) -> void:
	value = clampf(value + amount, 0.0, maximum)


func is_full() -> bool:
	return value >= maximum


## Vide la jauge (le Salto arc-en-ciel la consomme).
func empty() -> void:
	value = 0.0


func fraction() -> float:
	return value / maximum
