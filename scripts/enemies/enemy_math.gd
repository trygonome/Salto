class_name EnemyMath
## Règles des Muets sans état : bonds, piqué du volant, rage du Grand Muet, laisse.


## Vitesse verticale initiale d'un bond qui monte à `height` mètres sous la gravité `gravity`.
static func hop_speed(height: float, gravity: float) -> float:
	return sqrt(2.0 * gravity * height)


## Durée d'un bond (montée et descente) qui monte à `height` mètres.
static func hop_duration(height: float, gravity: float) -> float:
	return 2.0 * hop_speed(height, gravity) / gravity


## Position du volant pendant son piqué, à la fraction `t` (0 à 1) : il part de `start`,
## passe au ras de `target` à mi-chemin, puis remonte symétriquement de l'autre côté.
static func swoop_position(start: Vector3, target: Vector3, t: float) -> Vector3:
	var end := Vector3(2.0 * target.x - start.x, start.y, 2.0 * target.z - start.z)
	var flat: Vector3 = start.lerp(end, t)
	var dip: float = sin(PI * t)
	return Vector3(flat.x, lerpf(start.y, target.y, dip), flat.z)


## Vrai si le Grand Muet enrage (phase 2) avec la fraction `health_fraction` de ses PV.
static func boss_enraged(health_fraction: float, tuning: TuningData) -> bool:
	return health_fraction <= tuning.boss_phase2_fraction


## Vrai si un Muet posté en `post` est allé trop loin (au-delà de `leash`) et doit y revenir.
static func beyond_leash(post: Vector3, position: Vector3, leash: float) -> bool:
	return Vector2(position.x - post.x, position.z - post.z).length() > leash
