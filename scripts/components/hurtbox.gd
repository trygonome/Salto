class_name Hurtbox
extends Area3D
## Zone où un personnage peut être touché. Chaque coup reçu retire des points de vie
## à `health` (si elle est renseignée) puis est signalé par `hurt`.

signal hurt(hit: HitData)

## Rayon de la cible (m), ajouté à la portée des coups ; renseigné par le propriétaire.
@export var radius: float
## Points de vie touchés par les coups (facultatif).
@export var health: Health

## Faux pendant une invulnérabilité : les coups sont alors ignorés.
var can_be_hit: bool = true


func receive(hit: HitData) -> void:
	if not can_be_hit:
		return
	if health:
		health.take(hit.damage)
	hurt.emit(hit)
