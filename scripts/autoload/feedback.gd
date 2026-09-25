extends Node
## Retours d'impact globaux : arrêt sur image (tout le jeu se fige un instant)
## et demandes de secousse, que la caméra écoute.

## Secousse demandée : `trauma` de 0 à 1, `direction` du coup (horizontale) pour pousser la caméra.
signal shake_requested(trauma: float, direction: Vector3)

## Vitesse normale du temps.
const NORMAL_TIME_SCALE := 1.0

var _resume_at_usec: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Fige le jeu pendant `duration` secondes réelles (les arrêts qui se chevauchent s'allongent).
func hit_stop(duration: float) -> void:
	if duration <= 0.0:
		return
	var until: int = Time.get_ticks_usec() + roundi(duration * 1_000_000.0)
	_resume_at_usec = maxi(_resume_at_usec, until)
	Engine.time_scale = 0.0


func is_frozen() -> bool:
	return Engine.time_scale == 0.0


func shake(trauma: float, direction: Vector3) -> void:
	shake_requested.emit(trauma, direction)


func _process(_delta: float) -> void:
	if is_frozen() and Time.get_ticks_usec() >= _resume_at_usec:
		Engine.time_scale = NORMAL_TIME_SCALE
