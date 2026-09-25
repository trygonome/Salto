class_name NotebookData
extends Resource
## Pages du carnet (textes du jeu) : elles racontent l'histoire des Muets et du Grand Silence.

## Texte de chaque page, dans l'ordre (la page 1 est la première).
@export var pages: PackedStringArray


## Texte de la page `page` (numérotée à partir de 1).
func text(page: int) -> String:
	return pages[page - 1]
