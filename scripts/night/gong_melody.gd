class_name GongMelody
extends RefCounted
## Mélodie du cercle des gongs : les gongs la jouent, le joueur doit la rejouer dans l'ordre.
## Une erreur fait tout recommencer.

enum Result { CORRECT, WRONG, COMPLETE }

## Gongs à frapper, dans l'ordre.
var notes: PackedInt32Array
## Nombre de notes déjà bien rejouées.
var progress: int = 0


func _init(melody: PackedInt32Array) -> void:
	notes = melody


## Le gong `index` vient d'être frappé.
func strike(index: int) -> Result:
	if index != notes[progress]:
		progress = 0
		return Result.WRONG
	progress += 1
	if progress >= notes.size():
		return Result.COMPLETE
	return Result.CORRECT


func reset() -> void:
	progress = 0
