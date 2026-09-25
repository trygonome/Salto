class_name HeroMotion
## Règles de mouvement du héros, sans état : testables sans scène.


## Gravité à appliquer (m/s²) : plus forte en montée si le saut est relâché (petit saut), et en descente.
static func gravity(velocity_y: float, jump_held: bool, tuning: TuningData) -> float:
	if velocity_y > 0.0:
		return tuning.gravity_rise_held if jump_held else tuning.gravity_rise_released
	return tuning.gravity_fall


## Vitesse de la roulade (m/s) à la fraction `fraction` de sa durée.
## La fin est ralentie ; la vitesse de base est calculée pour parcourir exactement roll_distance.
static func roll_speed(fraction: float, tuning: TuningData) -> float:
	var tail: float = tuning.roll_tail_fraction
	var slow: float = tuning.roll_tail_speed_factor
	var base_speed: float = tuning.roll_distance / (tuning.roll_duration * (1.0 - tail + tail * slow))
	return base_speed * slow if fraction >= 1.0 - tail else base_speed


## Vrai si le héros est invulnérable à la fraction `fraction` de la roulade.
static func is_roll_invulnerable(fraction: float, tuning: TuningData) -> bool:
	return fraction >= tuning.roll_invuln_start and fraction <= tuning.roll_invuln_end


## Direction dans le monde pour une commande à l'écran (x à droite, y vers le bas) :
## la caméra ne tourne jamais et regarde vers -Z, donc le haut de l'écran est -Z.
static func world_direction(screen_input: Vector2) -> Vector3:
	return Vector3(screen_input.x, 0.0, screen_input.y)


## Angle de lacet (radians) d'un nœud qui regarde dans `direction` (l'avant d'un nœud est -Z).
static func yaw_of(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)
