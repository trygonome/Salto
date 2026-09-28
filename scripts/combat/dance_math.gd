class_name DanceMath
## Danses de la voie de l'Onde (version 4.1), sans état : quelle figure vient, ce qu'elle coûte en
## groove, ce qu'elle frappe et où elle vise. Le héros danse, la vibration part du bout de ses
## doigts : l'onde de paume file droit et traverse, la spirale lance trois orbes qui tournent, la
## pluie de pas éclate là où l'on vise, le fil d'écho est un rayon qu'on tient et qu'on balaie.

const PALM := &"palm"
const SPIRAL := &"spiral"
const RAIN := &"rain"
const THREAD := &"thread"
## Figures qui s'enchaînent, dans l'ordre (le fil d'écho se tient à part).
const CHAIN: Array[StringName] = [PALM, SPIRAL, RAIN]
## Toutes les figures (ce sont aussi les noms des coups qu'elles portent).
const FIGURES: Array[StringName] = [PALM, SPIRAL, RAIN, THREAD]


## Vrai si le héros sait danser (la paume est le premier talent de la voie).
static func can_dance(ranks: Dictionary) -> bool:
	return int(ranks.get(PALM, 0)) > 0


## Figure de l'enchaînement au pas `step` (0 : la première) : les figures apprises tournent dans
## l'ordre ; vide si aucune n'est apprise.
static func figure(step: int, ranks: Dictionary) -> StringName:
	var known: Array[StringName] = []
	for f: StringName in CHAIN:
		if int(ranks.get(f, 0)) > 0:
			known.append(f)
	if known.is_empty():
		return &""
	return known[posmod(step, known.size())]


## Groove que coûte la figure `f` (pour le fil d'écho : ce qu'il faut pour le commencer).
static func cost(f: StringName, tuning: TuningData) -> float:
	match f:
		PALM:
			return tuning.dance_cost_palm
		SPIRAL:
			return tuning.dance_cost_spiral
		RAIN:
			return tuning.dance_cost_rain
		THREAD:
			return tuning.dance_thread_min
	return 0.0


## Multiplicateur de l'attaque d'un coup de la figure `f` au rang `rank` (pour le fil d'écho : par
## seconde de rayon).
static func damage(f: StringName, rank: int, tuning: TuningData) -> float:
	var r: int = maxi(rank, 1) - 1
	match f:
		PALM:
			return tuning.dance_palm_damage + tuning.dance_palm_step * r
		SPIRAL:
			return tuning.dance_spiral_damage + tuning.dance_spiral_step * r
		RAIN:
			return tuning.dance_rain_damage + tuning.dance_rain_step * r
		THREAD:
			return tuning.dance_thread_damage
	return 0.0


## Visée d'un glisser-relâcher : `stick` est le déplacement du pouce depuis le bouton (longueur 0 à
## 1, le haut de l'écran est l'avant). Direction dans le monde (horizontale, normalisée).
static func aim_direction(stick: Vector2) -> Vector3:
	if stick.is_zero_approx():
		return Vector3.ZERO
	return HeroMotion.world_direction(stick.normalized())


## Distance du point visé par la pluie de pas : plus on glisse loin, plus elle tombe loin.
static func rain_distance(stick: Vector2, tuning: TuningData) -> float:
	return lerpf(tuning.dance_rain_min, tuning.dance_rain_max, clampf(stick.length(), 0.0, 1.0))


## Cible de la visée automatique (toucher bref) : la plus proche à portée, quelle que soit sa
## direction ; -1 s'il n'y en a pas.
static func auto_target(origin: Vector3, targets: PackedVector3Array, max_range: float) -> int:
	var best: int = -1
	var best_distance: float = max_range
	for i: int in targets.size():
		var distance: float = Vector2(targets[i].x - origin.x, targets[i].z - origin.z).length()
		if distance <= best_distance:
			best = i
			best_distance = distance
	return best


## Distance horizontale de `point` au segment [from, to] (le rayon du fil d'écho).
static func distance_to_segment(point: Vector3, from: Vector3, to: Vector3) -> float:
	var p := Vector2(point.x, point.z)
	var a := Vector2(from.x, from.z)
	var b := Vector2(to.x, to.z)
	var ab: Vector2 = b - a
	var t: float = 0.0 if ab.is_zero_approx() else clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Position d'un orbe de la spirale, `time` secondes après son départ : il avance le long de
## `direction` en tournant autour de la ligne (décalage de phase `phase`, en radians).
static func spiral_offset(direction: Vector3, time: float, phase: float, tuning: TuningData) -> Vector3:
	var side: Vector3 = direction.cross(Vector3.UP).normalized()
	var angle: float = phase + time * tuning.dance_spiral_turn_speed
	var radius: float = tuning.dance_spiral_radius * minf(1.0, time / tuning.dance_spiral_open_time)
	return direction * tuning.dance_spiral_speed * time + side * cos(angle) * radius + Vector3.UP * sin(angle) * radius * tuning.dance_spiral_lift
