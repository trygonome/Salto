class_name Hitbox
extends Area3D
## Zone de coup : elle suit en permanence les Hurtbox proches, mais ne touche que pendant
## sa fenêtre d'activité, chaque cible au plus une fois par activation, et seulement si la
## cible est à peu près à la même hauteur (`vertical_reach`).
## Le propriétaire appelle update() à chaque image physique.

signal landed(hit: HitData, hurtbox: Hurtbox)

## Écart de hauteur maximal entre le centre de la zone et celui d'une cible (m) ; renseigné
## par le propriétaire.
var vertical_reach: float = INF

var _time_left: float = 0.0
var _reach: float = 0.0
var _arc_deg: float = 0.0
var _forward: Vector3 = Vector3.FORWARD
var _make_hit: Callable
var _already_hit: Array[Hurtbox] = []


## Active la zone pendant `duration` secondes : elle touche les cibles à au plus `reach`
## (plus leur rayon), dans un arc de `arc_deg` degrés autour de `forward`.
## `make_hit` reçoit la Hurtbox touchée et renvoie le HitData à lui appliquer.
func activate(reach: float, arc_deg: float, forward: Vector3, duration: float, make_hit: Callable) -> void:
	_reach = reach
	_arc_deg = arc_deg
	_forward = forward
	_time_left = duration
	_make_hit = make_hit
	_already_hit.clear()


func deactivate() -> void:
	_time_left = 0.0


func is_active() -> bool:
	return _time_left > 0.0


func update(delta: float) -> void:
	if not is_active():
		return
	for area: Area3D in get_overlapping_areas():
		var hurtbox: Hurtbox = area as Hurtbox
		if hurtbox == null or _already_hit.has(hurtbox):
			continue
		if absf(hurtbox.center().y - center().y) > vertical_reach:
			continue
		if not CombatMath.in_strike_zone(global_position, _forward, hurtbox.global_position, hurtbox.radius, _reach, _arc_deg):
			continue
		_already_hit.append(hurtbox)
		var hit: HitData = _make_hit.call(hurtbox)
		if hurtbox.receive(hit):
			landed.emit(hit, hurtbox)
	_time_left -= delta


## Centre de la zone (celui de sa première forme de collision).
func center() -> Vector3:
	for child: Node in get_children():
		var shape: CollisionShape3D = child as CollisionShape3D
		if shape:
			return shape.global_position
	return global_position
