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
	return keep_between(direction, distance, beat_index, parity, tuning.spitter_keep_min, tuning.spitter_keep_max, tuning.spitter_strafe_beats)


## Comme keep_distance, entre `keep_min` et `keep_max` mètres (tisserand, totem, danseur…),
## en changeant de sens tous les `strafe_beats` temps.
static func keep_between(direction: Vector3, distance: float, beat_index: int, parity: int, keep_min: float, keep_max: float, strafe_beats: int) -> Vector3:
	if distance < keep_min:
		return -direction
	if distance > keep_max:
		return direction
	var side: float = 1.0 if posmod(floori(float(beat_index) / strafe_beats) + parity, 2) == 1 else -1.0
	return Vector3(-direction.z, 0.0, direction.x) * side


## Position du volant pendant son piqué, à la fraction `t` (0 à 1) : il file tout droit de
## `start` dans la direction `direction` sur `length` mètres, descend au ras du sol (à `low`
## au-dessus de `ground`) à mi-chemin, puis remonte.
static func swoop_position(start: Vector3, direction: Vector3, length: float, ground: float, low: float, t: float, curve: float) -> Vector3:
	var flat: Vector3 = start + direction * length * t
	var height: float = low + (start.y - ground - low) * pow(absf(1.0 - 2.0 * t), curve)
	return Vector3(flat.x, ground + height, flat.z)


## Vrai si le coup `move` est la réponse attendue parmi `answers` (voir Tuning.muet_answers) :
## `stunned` : le Muet est étourdi ; `behind` : le coup est passé à côté de son bouclier.
static func is_answer(answers: PackedStringArray, move: StringName, stunned: bool, behind: bool) -> bool:
	return answers.has(String(move)) or (stunned and answers.has("stunned")) or (behind and answers.has("behind"))


## Vrai si un coup (`move`) passe par-dessus le bouclier (plongeon, Salto arc-en-ciel).
static func goes_over_shield(move: StringName) -> bool:
	return move == &"dive" or move == &"rainbow"


## Vrai si un coup (`move`) brise la garde : coup chargé, coup de grâce, riposte, et le choc d'un
## Muet projeté ; le bouclier ne l'arrête pas.
static func breaks_guard(move: StringName) -> bool:
	return move == &"charged" or move == &"grace" or move == &"riposte" or move == &"impact"


## Équilibre d'un Muet : `base` (réglage de l'espèce), plus la part `per_tier` par rang.
static func max_poise(base: float, per_tier: float, tier: int) -> float:
	return base * (1.0 + per_tier * tier)


## Équilibre après `delta` s : il revient (part `rate` du maximum par seconde) une fois passé
## `delay` s sans coup reçu (`idle` : temps depuis le dernier coup, `delta` compris).
static func recovered_poise(poise: float, maximum: float, idle: float, delay: float, rate: float, delta: float) -> float:
	if idle < delay:
		return poise
	return minf(maximum, poise + maximum * rate * delta)


## Vitesse (m/s) et durée (s) du recul d'un coup de projection `launch` sur un Muet qui recule
## d'un facteur `factor` (les lourds reculent moins).
static func knockback_speed(launch: float, factor: float, tuning: TuningData) -> float:
	return (tuning.muet_knockback_speed + launch * tuning.launch_speed) * factor


static func knockback_time(launch: float, factor: float, tuning: TuningData) -> float:
	return tuning.muet_knockback_time + launch * factor * tuning.launch_time


## Vrai si la projection est assez forte pour que le Muet se blesse contre ce qu'il heurte.
static func is_launched(launch: float, factor: float, tuning: TuningData) -> bool:
	return launch * factor >= tuning.launch_impact_min


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
