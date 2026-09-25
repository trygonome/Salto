class_name NightProgress
extends RefCounted
## Progression d'une nuit : tambours rapportés, tambours portés, pages et objets trouvés cette
## nuit, Muets libérés, temps écoulé.
## Tomber ramène au village : on garde ce qui a été rapporté, les tambours portés sont perdus
## (ils retournent à leurs sanctuaires).

## Tambours à rapporter pour accomplir la nuit.
var drums_required: int
var drums_returned: int = 0
## Tambours portés (on peut en porter plusieurs à la fois).
var drums_carried: int = 0
## Vrai si le héros porte au moins un tambour.
var carrying_drum: bool:
	get:
		return drums_carried > 0
## Pages du carnet trouvées cette nuit (numéros à partir de 1).
var pages: Array[int] = []
var items: Array[ItemData] = []
var muets_freed: int = 0
## Temps de jeu de la nuit (s), arrêté quand elle est accomplie.
var elapsed: float = 0.0


func _init(required: int) -> void:
	drums_required = required


func pick_drum() -> void:
	drums_carried += 1


## Les tambours portés sont perdus (chute, PV à zéro) ; renvoie vrai s'il y en avait.
func drop_drum() -> bool:
	var had_drum: bool = carrying_drum
	drums_carried = 0
	return had_drum


## Pose au village tous les tambours portés ; renvoie vrai s'il y en avait.
func return_drum() -> bool:
	if not carrying_drum:
		return false
	drums_returned += drums_carried
	drums_carried = 0
	return true


func is_complete() -> bool:
	return drums_returned >= drums_required


## Couches de musique audibles : la base, plus une par tambour rapporté (au plus `layer_count`).
func music_layers(layer_count: int) -> int:
	return mini(1 + drums_returned, layer_count)


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
