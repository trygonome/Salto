class_name CombatMath
## Règles de combat sans état : zone touchée, visée automatique, dégâts, combo, plongeon.

## Arc d'un coup qui touche tout autour (degrés).
const FULL_CIRCLE_DEG := 360.0


## Attaque du héros au niveau `level` (le niveau 1 donne l'attaque de base).
static func hero_attack(level: int, tuning: TuningData) -> float:
	return tuning.hero_attack_base + tuning.hero_attack_per_level * (level - 1)


## Points de vie du héros au niveau `level`.
static func hero_max_health(level: int, tuning: TuningData) -> float:
	return tuning.hero_health_base + tuning.hero_health_per_level * (level - 1)


## Multiplicateur de combo quand `hits` coups ont déjà touché sans interruption.
static func combo_multiplier(hits: int, tuning: TuningData) -> float:
	return 1.0 + minf(tuning.combo_bonus_max, tuning.combo_bonus_per_hit * hits)


## Dégâts d'un coup : attaque × multiplicateur du coup × combo × critique éventuel.
static func damage(attack: float, move_multiplier: float, combo: float, critical: bool, tuning: TuningData) -> float:
	var critical_factor: float = tuning.crit_multiplier if critical else 1.0
	return attack * move_multiplier * combo * critical_factor


## Vrai si une cible de rayon `target_radius` en `target` est touchée par un coup porté
## depuis `origin` vers `forward` : distance au plus `reach` + rayon de la cible, et cible
## (au moins en partie) dans l'arc de `arc_deg` degrés centré sur `forward`. Hauteur ignorée.
static func in_strike_zone(origin: Vector3, forward: Vector3, target: Vector3, target_radius: float, reach: float, arc_deg: float) -> bool:
	var to_target := Vector3(target.x - origin.x, 0.0, target.z - origin.z)
	var distance: float = to_target.length()
	if distance > reach + target_radius:
		return false
	if arc_deg >= FULL_CIRCLE_DEG or distance <= target_radius:
		return true
	var flat_forward := Vector3(forward.x, 0.0, forward.z)
	var half_width_deg: float = rad_to_deg(asin(target_radius / distance))
	return rad_to_deg(flat_forward.angle_to(to_target)) <= arc_deg / 2.0 + half_width_deg


## Index de la cible visée automatiquement : la plus proche à au plus `max_range`,
## dans un cône de `cone_deg` degrés autour de `forward` ; -1 s'il n'y en a pas.
static func pick_target(origin: Vector3, forward: Vector3, targets: PackedVector3Array, max_range: float, cone_deg: float) -> int:
	var best: int = -1
	var best_distance: float = INF
	var flat_forward := Vector3(forward.x, 0.0, forward.z)
	for i: int in targets.size():
		var to_target := Vector3(targets[i].x - origin.x, 0.0, targets[i].z - origin.z)
		var distance: float = to_target.length()
		if distance > max_range or distance >= best_distance or is_zero_approx(distance):
			continue
		if rad_to_deg(flat_forward.angle_to(to_target)) <= cone_deg / 2.0:
			best = i
			best_distance = distance
	return best


## Rayon de l'onde du plongeon pour une chute de `fall_height` mètres (bonus plafonné).
static func dive_radius(fall_height: float, tuning: TuningData) -> float:
	var bonus: float = tuning.dive_radius_per_meter * maxf(fall_height, 0.0)
	return tuning.dive_radius_base + minf(bonus, tuning.dive_radius_bonus_max)


## Multiplicateur de dégâts du plongeon pour une chute de `fall_height` mètres (bonus plafonné).
static func dive_multiplier(fall_height: float, tuning: TuningData) -> float:
	var bonus: float = tuning.dive_multiplier_per_meter * maxf(fall_height, 0.0)
	return tuning.dive_multiplier_base + minf(bonus, tuning.dive_multiplier_bonus_max)
