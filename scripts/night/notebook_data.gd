class_name NotebookData
extends Resource
## Pages du carnet (textes du jeu) : elles racontent l'histoire des Muets et du Grand Silence.

## Texte de chaque page, dans l'ordre (la page 1 est la première).
@export var pages: PackedStringArray
## Pages cachées dans chaque nuit de la saga (la première : dans le coffre du cercle des gongs ;
## les autres : dans des coffres au sommet des perchoirs).
@export var night_pages: Array[PackedInt32Array]


## Pages cachées dans la nuit `night` (aucune dans les nuits sans fin).
func pages_of_night(night: int) -> PackedInt32Array:
	return night_pages[night - 1] if night >= 1 and night <= night_pages.size() else PackedInt32Array()


## Nuit où se cache la page `page` (0 : aucune).
func night_of_page(page: int) -> int:
	for i: int in night_pages.size():
		if night_pages[i].has(page):
			return i + 1
	return 0


## Texte de la page `page` (numérotée à partir de 1).
func text(page: int) -> String:
	return pages[page - 1]
