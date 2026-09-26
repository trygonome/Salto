class_name GrooveGauge
extends RefCounted
## Jauge de groove : se remplit en jouant en rythme ; pleine, elle débloque le Salto arc-en-ciel.
## Sans rien gagner un moment, elle retombe doucement (le silence revient) ; pleine, elle attend
## le Salto.

## Valeur actuelle, de 0 à `maximum`.
var value: float = 0.0
var maximum: float
## Temps depuis le dernier gain (s).
var idle: float = 0.0


func _init(gauge_maximum: float) -> void:
	maximum = gauge_maximum


func add(amount: float) -> void:
	value = clampf(value + amount, 0.0, maximum)
	if amount > 0.0:
		idle = 0.0


## Le temps passe (`delta` s) : après `idle_time` s sans gain, la jauge perd `rate` par seconde,
## sauf si elle est pleine.
func drain(delta: float, idle_time: float, rate: float) -> void:
	if is_full():
		idle = 0.0
		return
	idle += delta
	if idle > idle_time:
		value = maxf(0.0, value - rate * delta)


func is_full() -> bool:
	return value >= maximum


## Vide la jauge (le Salto arc-en-ciel la consomme).
func empty() -> void:
	value = 0.0


func fraction() -> float:
	return value / maximum
