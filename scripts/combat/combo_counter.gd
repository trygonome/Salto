class_name ComboCounter
extends RefCounted
## Compte les coups qui touchent à la suite. Le combo est perdu après `timeout` secondes
## sans toucher, ou quand le héros est touché (reset).

## Coups qui ont touché à la suite.
var hits: int = 0
## Durée sans toucher au-delà de laquelle le combo est perdu (s).
var timeout: float

var _last_hit: float = 0.0


func _init(combo_timeout: float) -> void:
	timeout = combo_timeout


## Enregistre un coup qui touche au temps `now` (s).
func register_hit(now: float) -> void:
	update(now)
	hits += 1
	_last_hit = now


## Perd le combo s'il a expiré au temps `now` (s).
func update(now: float) -> void:
	if hits > 0 and now - _last_hit > timeout:
		hits = 0


func reset() -> void:
	hits = 0
