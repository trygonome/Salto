class_name Smoothing
## Lissage exponentiel, indépendant de la fréquence d'images.


## Part du chemin à parcourir vers la cible pendant `delta` secondes, pour un lissage de `rate` par seconde.
static func weight(rate: float, delta: float) -> float:
	return 1.0 - exp(-rate * delta)
