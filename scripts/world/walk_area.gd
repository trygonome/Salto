class_name WalkArea
extends RefCounted
## Où l'on marche dans une clairière (version 3.4) : l'union de disques (l'arène, les recoins) et
## de sentiers (segments épais qui s'enchaînent). Tout est en unités du prototype (u). Sert à
## border le chemin d'arbres, à poser la clôture invisible juste derrière et à placer le décor.

## Disques : x, z, rayon.
var discs := PackedFloat32Array()
## Sentiers : ax, az, bx, bz, demi-largeur.
var lanes := PackedFloat32Array()
## Après outline() : pour chaque point, la taille de la forme d'où il vient (rayon d'un disque,
## demi-largeur d'un sentier) : un bord large (l'arène) ou étroit (un sentier).
var outline_sizes := PackedFloat32Array()


func clear() -> void:
	discs.clear()
	lanes.clear()


func is_empty() -> bool:
	return discs.is_empty() and lanes.is_empty()


func add_disc(center: Vector2, radius: float) -> void:
	discs.append_array([center.x, center.y, radius])


func add_lane(a: Vector2, b: Vector2, half_width: float) -> void:
	lanes.append_array([a.x, a.y, b.x, b.y, half_width])


## Un sentier qui passe par `points` (chaque coude arrondi).
func add_path(points: PackedVector2Array, half_width: float) -> void:
	for i: int in range(1, points.size()):
		add_lane(points[i - 1], points[i], half_width)


## Profondeur de `p` dans la zone (u) : positive dedans (distance au bord le plus proche de la
## forme la plus englobante), négative dehors (distance à la zone).
func depth(p: Vector2) -> float:
	var best: float = -INF
	for i: int in discs.size() / 3:
		best = maxf(best, discs[i * 3 + 2] - p.distance_to(Vector2(discs[i * 3], discs[i * 3 + 1])))
	for i: int in lanes.size() / 5:
		var o: int = i * 5
		var d: float = WorldGen.segment_distance(p, Vector2(lanes[o], lanes[o + 1]), Vector2(lanes[o + 2], lanes[o + 3]))
		best = maxf(best, lanes[o + 4] - d)
	return best


func contains(p: Vector2, margin: float = 0.0) -> bool:
	return depth(p) > margin


## Points du bord de la zone, repoussés de `offset` vers l'extérieur, espacés d'environ `spacing`
## (u) ; là où deux formes se rejoignent (un sentier qui débouche), le bord s'ouvre.
func outline(spacing: float, offset: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	outline_sizes.clear()
	for i: int in discs.size() / 3:
		var center := Vector2(discs[i * 3], discs[i * 3 + 1])
		_ring(points, center, discs[i * 3 + 2] + offset, spacing, offset, 0.0, TAU, discs[i * 3 + 2])
	for i: int in lanes.size() / 5:
		var o: int = i * 5
		var a := Vector2(lanes[o], lanes[o + 1])
		var b := Vector2(lanes[o + 2], lanes[o + 3])
		var r: float = lanes[o + 4] + offset
		var along: Vector2 = (b - a).normalized() if not a.is_equal_approx(b) else Vector2.UP
		var side := Vector2(-along.y, along.x)
		var length: float = a.distance_to(b)
		var count: int = maxi(1, ceili(length / spacing))
		for k: int in count + 1:
			var p: Vector2 = a.lerp(b, float(k) / count)
			_keep(points, p + side * r, offset, lanes[o + 4])
			_keep(points, p - side * r, offset, lanes[o + 4])
		# Les bouts du sentier : des demi-cercles (qui ne s'ouvrent que là où rien ne continue).
		var start: float = side.angle()
		_ring(points, a, r, spacing, offset, start, start + PI, lanes[o + 4])
		_ring(points, b, r, spacing, offset, start + PI, start + TAU, lanes[o + 4])
	return points


func _ring(points: PackedVector2Array, center: Vector2, radius: float, spacing: float, offset: float, from: float, to: float, size: float) -> void:
	var count: int = maxi(3, ceili((to - from) * radius / spacing))
	for k: int in count:
		var a: float = lerpf(from, to, (k + 0.5) / count)
		_keep(points, center + Vector2(cos(a), sin(a)) * radius, offset, size)


## Garde `p` s'il est à `offset` au moins de toute la zone (sinon il tomberait dans un passage).
func _keep(points: PackedVector2Array, p: Vector2, offset: float, size: float) -> void:
	if depth(p) <= -offset + 0.05:
		points.append(p)
		outline_sizes.append(size)


## Sentier sinueux (pur, testé) : part de `start` dans la direction `heading` sur `length`, avec
## `bends` coudes qui s'écartent tour à tour d'un côté puis de l'autre, de `sway` à peu près ;
## `rolls` (tirages entre 0 et 1, au moins bends + 1) décident du premier côté et des écarts.
static func winding(start: Vector2, heading: Vector2, length: float, bends: int, sway: float, rolls: PackedFloat32Array) -> PackedVector2Array:
	var points := PackedVector2Array([start])
	var dir: Vector2 = heading.normalized()
	var side := Vector2(-dir.y, dir.x)
	var sign: float = 1.0 if rolls[0] < 0.5 else -1.0
	for k: int in range(1, bends + 1):
		var last: bool = k == bends
		var offset: float = 0.0 if last and bends > 1 else sign * sway * (0.6 + 0.4 * rolls[k])
		points.append(start + dir * length * float(k) / bends + side * offset)
		sign = -sign
	return points
