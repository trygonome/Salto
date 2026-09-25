class_name InputBuffer
extends RefCounted
## Mémoire des appuis : un appui reste valable pendant `duration` secondes
## et s'exécute dès que l'action devient possible. Chaque appui ne sert qu'une fois.

## Durée pendant laquelle un appui reste valable (s).
var duration: float

var _pressed_at: Dictionary[StringName, float] = {}


func _init(buffer_duration: float) -> void:
	duration = buffer_duration


## Enregistre un appui au temps `now` (s).
func press(action: StringName, now: float) -> void:
	_pressed_at[action] = now


## Vrai si un appui encore valable attend, sans le consommer.
func is_buffered(action: StringName, now: float) -> bool:
	return _pressed_at.has(action) and now - _pressed_at[action] <= duration


## Vrai si l'action a été appuyée il y a au plus `duration` secondes ; l'appui est alors consommé.
func consume(action: StringName, now: float) -> bool:
	if not is_buffered(action, now):
		return false
	_pressed_at.erase(action)
	return true


## Oublie tous les appuis en attente.
func clear() -> void:
	_pressed_at.clear()
