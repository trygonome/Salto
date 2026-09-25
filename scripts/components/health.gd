class_name Health
extends Node
## Points de vie. Émet `damaged` à chaque perte et `depleted` quand ils tombent à zéro.

signal damaged(amount: float, current: float)
signal depleted

var maximum: float = 0.0
var current: float = 0.0


func setup(max_health: float) -> void:
	maximum = max_health
	current = max_health


## Retire `amount` points de vie (sans descendre sous zéro).
func take(amount: float) -> void:
	if is_depleted():
		return
	current = maxf(current - amount, 0.0)
	damaged.emit(amount, current)
	if is_depleted():
		depleted.emit()


## Rend tous les points de vie.
func restore() -> void:
	current = maximum


func is_depleted() -> bool:
	return current <= 0.0
