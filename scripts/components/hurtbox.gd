class_name Hurtbox
extends Area3D
## Zone où un personnage peut être touché. Chaque coup reçu retire des points de vie
## à `health` (si elle est renseignée) puis est signalé par `hurt`. Un coup qui arrive
## pendant une invulnérabilité est signalé par `dodged` (esquive parfaite du héros).

signal hurt(hit: HitData)
signal dodged(hit: HitData)
## Le coup a été arrêté (bouclier) : ni dégâts ni effet.
signal blocked(hit: HitData)

## Rayon de la cible (m), ajouté à la portée des coups ; renseigné par le propriétaire.
@export var radius: float
## Points de vie touchés par les coups (facultatif).
@export var health: Health

## Faux pendant une invulnérabilité : les coups sont alors esquivés.
var can_be_hit: bool = true
## Multiplicateur des dégâts reçus (un cornu assommé est plus fragile).
var damage_taken_multiplier: float = 1.0
## Garde facultative : reçoit le HitData et renvoie vrai si le coup est arrêté (bouclier).
var blocker: Callable
## Réglage facultatif d'un coup qui porte, avant les dégâts : reçoit le HitData et peut le changer
## (bonne réponse d'un Muet).
var modifier: Callable


## Reçoit un coup ; renvoie vrai s'il a porté, faux s'il a été esquivé ou arrêté.
func receive(hit: HitData) -> bool:
	if not can_be_hit:
		dodged.emit(hit)
		return false
	if blocker.is_valid() and blocker.call(hit):
		blocked.emit(hit)
		return false
	if modifier.is_valid():
		modifier.call(hit)
	hit.damage *= damage_taken_multiplier
	if health:
		health.take(hit.damage)
	hurt.emit(hit)
	return true


## Centre de la zone (celui de sa première forme de collision).
func center() -> Vector3:
	for child: Node in get_children():
		var shape: CollisionShape3D = child as CollisionShape3D
		if shape:
			return shape.global_position
	return global_position
