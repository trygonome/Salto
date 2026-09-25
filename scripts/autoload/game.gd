extends Node
## État de la nuit en cours : tambours rapportés, tambour porté, pages du carnet, objets.
## Les éléments du niveau écoutent ses signaux (couleurs, musique, Chef, tambour).

signal drum_picked
## Le tambour porté est perdu (chute) : il retourne à son sanctuaire.
signal drum_dropped
signal drum_returned(count: int)
signal night_completed
signal page_found(page: int)
signal item_found(item: ItemData)

var progress: NightProgress


func _ready() -> void:
	start_night()


## Remet la nuit à zéro et lance la musique (la base seule).
func start_night() -> void:
	progress = NightProgress.new(Tuning.data.night_drums_required)


func pick_drum() -> void:
	progress.pick_drum()
	drum_picked.emit()


func drop_drum() -> void:
	if progress.drop_drum():
		drum_dropped.emit()


func return_drum() -> void:
	if not progress.return_drum():
		return
	Rhythm.set_layers(music_layers())
	drum_returned.emit(progress.drums_returned)
	if progress.is_complete():
		night_completed.emit()


func add_page(page: int) -> void:
	if progress.add_page(page):
		page_found.emit(page)


func add_item(item: ItemData) -> void:
	progress.add_item(item)
	item_found.emit(item)


func music_layers() -> int:
	return progress.music_layers(Rhythm.NIGHT_LAYERS.size())


func world_saturation() -> float:
	var tuning: TuningData = Tuning.data
	return progress.world_saturation(tuning.night_saturation_start, tuning.night_saturation_full)
