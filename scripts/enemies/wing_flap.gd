extends Node3D
## Aile de volant : battement régulier autour de l'axe avant-arrière.

## Battements par seconde.
@export var flap_rate: float
## Amplitude du battement (degrés).
@export var flap_angle_deg: float
## 1 pour l'aile droite, -1 pour la gauche.
@export var side: float

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	rotation.z = side * deg_to_rad(flap_angle_deg) * sin(TAU * flap_rate * _time)
