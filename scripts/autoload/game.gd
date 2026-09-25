extends Node
## État du jeu : la nuit en cours (tambours, temps, Muets libérés) et le profil gardé d'une
## partie à l'autre (carnet, objets, aides suivies, records, réglages), sauvegardé à chaque
## changement. Les éléments du niveau et l'interface écoutent ses signaux.

signal night_started(night: int)
signal drum_picked
## Le tambour porté est perdu (chute) : il retourne à son sanctuaire.
signal drum_dropped
signal drum_returned(count: int)
## Le gardien d'un sanctuaire est libéré : son tambour est à prendre.
signal sanctuary_freed
signal night_completed
signal muet_freed(muet: Node3D)
## Une page arrive dans le carnet pour la première fois.
signal page_found(page: int)
signal item_found(item: ItemData)
signal settings_changed

## Numéro de la nuit en cours.
var night: int = 1
var progress: NightProgress
var profile: Profile
## Vrai si la dernière nuit accomplie a battu le record.
var new_record: bool = false


func _ready() -> void:
	profile = Save.load_profile()
	start_night(night)


func _process(delta: float) -> void:
	progress.advance(delta)


## Remet la nuit `number` à zéro (le profil est gardé).
func start_night(number: int = 1) -> void:
	night = number
	progress = NightProgress.new(Tuning.data.night_drums_required)
	new_record = false
	night_started.emit(night)


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
		new_record = profile.complete_night(night, progress.elapsed)
		profile.nights_done = maxi(profile.nights_done, night)
		profile.night_seed = 0
		save()
		night_completed.emit()


## Graine du monde de la nuit : tirée une fois, puis gardée jusqu'à la nuit suivante.
func world_seed() -> int:
	if profile.night_seed == 0:
		profile.night_seed = randi_range(1, 0x7FFFFFFF)
		save()
	return profile.night_seed


func free_sanctuary() -> void:
	sanctuary_freed.emit()


## Un Muet vient d'être libéré (appelé par le Muet).
func on_muet_freed(muet: Node3D) -> void:
	progress.muets_freed += 1
	muet_freed.emit(muet)


func add_page(page: int) -> void:
	progress.add_page(page)
	if profile.add_page(page):
		save()
		page_found.emit(page)


func add_item(item: ItemData) -> void:
	progress.add_item(item)
	profile.add_item(item)
	save()
	item_found.emit(item)


## Note une aide contextuelle comme suivie (elle ne reviendra plus).
func mark_hint_done(hint: StringName) -> void:
	if profile.mark_hint_done(hint):
		save()


func set_damage_numbers(enabled: bool) -> void:
	profile.damage_numbers = enabled
	save()
	settings_changed.emit()


func set_debug_info(enabled: bool) -> void:
	profile.debug_info = enabled
	save()
	settings_changed.emit()


func save() -> void:
	Save.save_profile(profile)


func music_layers() -> int:
	return progress.music_layers(Rhythm.NIGHT_LAYERS.size())


func world_saturation() -> float:
	var tuning: TuningData = Tuning.data
	return progress.world_saturation(tuning.night_saturation_start, tuning.night_saturation_full)
