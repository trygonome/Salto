class_name Level
extends Node3D
## Ce que l'interface attend d'un niveau (nuit dans le monde voxel, expédition) : s'il y a une
## partie en cours, l'objectif du moment et les tambours de la nuit. Le niveau est dans le groupe
## « night_level » et répond à start_sortie(), end_sortie(kind) et restart(play).

## Une partie est en cours (sinon : écran titre ou résumé).
var in_sortie: bool = false


## Objectif du moment : title, sub, icon (et point, en mètres, s'il y a un repère à suivre).
func current_goal() -> Dictionary:
	return {}


## Vrai pour une expédition (écran titre et résumé à part).
func is_expedition() -> bool:
	return false


## Vrai si le haut de l'écran montre les tambours de la nuit.
func shows_drums() -> bool:
	return true
