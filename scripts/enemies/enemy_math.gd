class_name EnemyMath
## Règles des Muets sans état : forces selon le sanctuaire et la nuit, bonds, distances du
## cracheur, piqué du volant, bouclier, rage du Grand Muet, laisse.


## Valeur d'un réglage de Muet (PV, dégâts) : `base`, plus `per_tier` par rang de sanctuaire,
## plus la part `per_night` par nuit après la première ; arrondie.
static func scaled(base: float, per_tier: float, tier: int, per_night: float, night: int) -> float:
	return roundf((base + per_tier * tier) * (1.0 + per_night * maxi(night - 1, 0)))


## Orientation (rad) d'un corps voxel (qui regarde vers +z) tourné vers `direction`.
static func yaw_of(direction: Vector3) -> float:
	return atan2(direction.x, direction.z)


## Avancée d'un bond à la fraction `t` de sa durée : vite au départ, en douceur à l'arrivée.
static func ease_out(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)


## Direction du prochain bond du cracheur, qui garde ses distances : il recule si le héros
## (dans `direction`, à `distance`) est trop près, avance s'il est trop loin, sinon il tourne
## autour de lui en changeant de sens tous les quelques temps.
static func keep_distance(direction: Vector3, distance: float, beat_index: int, parity: int, tuning: TuningData) -> Vector3:
	if distance < tuning.spitter_keep_min:
		return -direction
	if distance > tuning.spitter_keep_max:
		return direction
	var side: float = 1.0 if posmod(floori(float(beat_index) / tuning.spitter_strafe_beats) + parity, 2) == 1 else -1.0
	return Vector3(-direction.z, 0.0, direction.x) * side


## Position du volant pendant son piqué, à la fraction `t` (0 à 1) : il file tout droit de
## `start` dans la direction `direction` sur `length` mètres, descend au ras du sol (à `low`
## au-dessus de `ground`) à mi-chemin, puis remonte.
static func swoop_position(start: Vector3, direction: Vector3, length: float, ground: float, low: float, t: float, curve: float) -> Vector3:
	var flat: Vector3 = start + direction * length * t
	var height: float = low + (start.y - ground - low) * pow(absf(1.0 - 2.0 * t), curve)
	return Vector3(flat.x, ground + height, flat.z)


## Vrai si un coup (`move`) passe par-dessus le bouclier (plongeon, Salto arc-en-ciel).
static func goes_over_shield(move: StringName) -> bool:
	return move == &"dive" or move == &"rainbow"


## Vrai si le bouclier tourné vers `facing` arrête un coup qui arrive dans la direction
## `hit_direction` (du héros vers le Muet) : le héros est devant, à moins de `angle` du regard.
static func shield_blocks(facing: Vector3, hit_direction: Vector3, angle: float) -> bool:
	return facing.dot(-hit_direction) > cos(angle)


## Vrai si le Grand Muet enrage (phase 2) avec la fraction `health_fraction` de ses PV.
static func boss_enraged(health_fraction: float, tuning: TuningData) -> bool:
	return health_fraction <= tuning.boss_phase2_fraction


## Vrai si un Muet posté en `post` est allé trop loin (au-delà de `leash`) et doit y revenir.
static func beyond_leash(post: Vector3, position: Vector3, leash: float) -> bool:
	return Vector2(position.x - post.x, position.z - post.z).length() > leash
