class_name NightProgress
extends RefCounted
## Une sortie dans la nuit, comme dans le prototype : sanctuaires libérés, tambours pris, portés
## et rapportés (ceux des sorties précédentes restent au village), Muets libérés, temps écoulé.
## S'évanouir met fin à la sortie : les tambours portés retournent à leurs sanctuaires.

## Tambours à rapporter pour accomplir la nuit (un par sanctuaire).
var drums_required: int
## Par sanctuaire : gardien libéré, tambour pris sur l'autel, tambour rapporté au village.
var freed: Array[bool] = []
var picked: Array[bool] = []
var returned: Array[bool] = []
## Tambours rapportés lors des sorties précédentes (ils étaient déjà au village).
var banked_at_start: Array[bool] = []
## Sanctuaires dont le tambour est porté, dans l'ordre où ils ont été pris.
var carrying: Array[int] = []
var drums_returned: int:
	get:
		return returned.count(true)
## Vrai si le héros porte au moins un tambour.
var carrying_drum: bool:
	get:
		return not carrying.is_empty()
## Pages du carnet et objets trouvés pendant la sortie.
var pages: Array[int] = []
var items: Array[ItemData] = []
## Muets libérés pendant la sortie.
var muets_freed: int = 0
## Temps de jeu de la sortie (s), arrêté quand la nuit est accomplie.
var elapsed: float = 0.0


## Sortie d'une nuit à `required` tambours, dont ceux de `banked` sont déjà au village.
func _init(required: int, banked: Array[bool] = []) -> void:
	drums_required = required
	for i: int in required:
		var done: bool = i < banked.size() and banked[i]
		freed.append(done)
		picked.append(done)
		returned.append(done)
		banked_at_start.append(done)


## Le gardien du sanctuaire `index` est libéré : son tambour est à prendre.
func free_sanctuary(index: int) -> void:
	freed[index] = true


## Prend le tambour du sanctuaire `index` ; renvoie faux s'il n'était pas à prendre.
func pick_drum(index: int = -1) -> bool:
	if index < 0:
		index = _first_available()
		if index < 0:
			return false
	if picked[index]:
		return false
	picked[index] = true
	freed[index] = true
	carrying.append(index)
	return true


## Les tambours portés sont perdus : ils retournent sur leurs autels. Renvoie vrai s'il y en avait.
func drop_drums() -> bool:
	if carrying.is_empty():
		return false
	for index: int in carrying:
		picked[index] = false
	carrying.clear()
	return true


## Pose au village tous les tambours portés ; renvoie les sanctuaires dont le tambour est rentré.
func return_drums() -> Array[int]:
	var list: Array[int] = carrying.duplicate()
	for index: int in list:
		returned[index] = true
	carrying.clear()
	return list


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


## Fait avancer le temps de la sortie tant que la nuit n'est pas accomplie.
func advance(delta: float) -> void:
	if not is_complete():
		elapsed += delta


func _first_available() -> int:
	for i: int in drums_required:
		if freed[i] and not picked[i]:
			return i
	for i: int in drums_required:
		if not picked[i]:
			return i
	return -1
