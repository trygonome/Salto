extends Node
## Sauvegarde du profil : un fichier JSON versionné dans user://. L'écriture passe par un
## fichier temporaire, remplacé d'un coup : une coupure en pleine écriture ne l'abîme pas.

const DEFAULT_PATH := "user://salto_save.json"

## Fichier de sauvegarde (les tests en utilisent un autre).
var path: String = DEFAULT_PATH


## Relit le profil ; un profil neuf s'il n'y a pas de sauvegarde ou qu'elle est illisible.
func load_profile() -> Profile:
	if not FileAccess.file_exists(path):
		return Profile.new()
	var json := JSON.new()
	var parsed: Error = json.parse(FileAccess.get_file_as_string(path))
	var data: Variant = json.data
	if parsed != OK or not data is Dictionary:
		push_warning("Sauvegarde illisible, profil neuf : %s" % path)
		return Profile.new()
	return Profile.from_dict(data)


## Écrit le profil ; renvoie faux si l'écriture a échoué.
func save_profile(profile: Profile) -> bool:
	var temporary: String = path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("Sauvegarde impossible : %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(profile.to_dict(), "\t"))
	file.close()
	if DirAccess.rename_absolute(temporary, path) == OK:
		return true
	# Windows ne remplace pas un fichier existant en le renommant.
	DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(temporary, path) == OK


## Efface la sauvegarde (tests).
func erase() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
