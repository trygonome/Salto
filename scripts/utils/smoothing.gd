class_name Smoothing
## Lissage exponentiel, indépendant de la fréquence d'images.


## Part du chemin à parcourir vers la cible pendant `delta` secondes, pour un lissage de `rate` par seconde.
static func weight(rate: float, delta: float) -> float:
	return 1.0 - exp(-rate * delta)


## Avancée adoucie au début et à la fin (0 à 1), comme easeInOut du prototype (saltos, roulades).
static func ease_in_out(t: float) -> float:
	return 2.0 * t * t if t < 0.5 else 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0
