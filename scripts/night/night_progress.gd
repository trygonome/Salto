class_name NightProgress
extends RefCounted
## Progression d'une nuit : tambours rapportés, tambour porté, pages et objets trouvés cette
## nuit, Muets libérés, temps écoulé.
## Tomber ramène au village : on garde ce qui a été rapporté, le tambour porté est perdu
## (il retourne à son sanctuaire).

## Tambours à rapporter pour accomplir la nuit.
var drums_required: int
var drums_returned: int = 0
var carrying_drum: bool = false
## Pages du carnet trouvées cette nuit (numéros à partir de 1).
var pages: Array[int] = []
var items: Array[ItemData] = []
var muets_freed: int = 0
## Temps de jeu de la nuit (s), arrêté quand elle est accomplie.
var elapsed: float = 0.0


func _init(required: int) -> void:
	drums_required = required


func pick_drum() -> void:
	carrying_drum = true


## Le tambour porté est perdu (chute) ; renvoie vrai s'il y en avait un.
func drop_drum() -> bool:
	var had_drum: bool = carrying_drum
	carrying_drum = false
	return had_drum


## Pose le tambour porté au village ; renvoie vrai s'il y en avait un.
func return_drum() -> bool:
	if not carrying_drum:
		return false
	carrying_drum = false
	drums_returned += 1
	return true


func is_complete() -> bool:
	return drums_returned >= drums_required


## Couches de musique audibles : la base, plus une par tambour rapporté (au plus `layer_count`).
func music_layers(layer_count: int) -> int:
	return mini(1 + drums_returned, layer_count)


## Saturation des couleurs du monde : il commence terne et reprend ses couleurs à chaque tambour.
func world_saturation(start: float, full: float) -> float:
	return lerpf(start, full, float(drums_returned) / drums_required)


## Ajoute une page ; renvoie faux si elle était déjà trouvée.
func add_page(page: int) -> bool:
	if pages.has(page):
		return false
	pages.append(page)
	return true


func add_item(item: ItemData) -> void:
	items.append(item)


## Fait avancer le temps de la nuit tant qu'elle n'est pas accomplie.
func advance(delta: float) -> void:
	if not is_complete():
		elapsed += delta
