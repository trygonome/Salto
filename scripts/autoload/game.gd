extends Node
## État du jeu, comme la saga du prototype : le profil gardé d'une partie à l'autre (nuit en
## cours, tambours déjà rapportés, niveau, talents, sac, réglages) et la sortie en cours
## (sanctuaires, tambours portés, Muets libérés). Le héros grandit au village : l'expérience des
## Muets libérés s'y ajoute quand il y revient (ou à la fin de la sortie), et le cadeau de chaque
## Grand Muet voyage avec son tambour jusqu'au village. Une sortie se termine quand la nuit est
## accomplie, quand le héros s'évanouit ou quand il rentre au village depuis la pause ; les
## tambours rapportés restent au village jusqu'à la fin de la nuit. Sauvegardé à chaque étape.
## Les éléments du niveau et l'interface écoutent ses signaux.

## La nuit `night` est prête (monde, tambours déjà rapportés).
signal night_started(night: int)
## Une sortie commence (le héros part du village).
signal sortie_started
signal drum_picked
## Les tambours portés sont perdus : ils retournent à leurs sanctuaires.
signal drum_dropped
## Des tambours sont rentrés au village (`count` : tambours rapportés en tout cette nuit).
signal drum_returned(count: int)
## Le gardien d'un sanctuaire est libéré : son tambour est à prendre.
signal sanctuary_freed
signal night_completed
signal muet_freed(muet: Node3D)
## Une page arrive dans le carnet pour la première fois.
signal page_found(page: int)
## Un objet arrive dans le sac (le cadeau d'un Grand Muet, au village).
signal item_found(item: ItemData)
signal settings_changed
## Expérience gagnée (ou mise de côté pendant la sortie) ; niveau gagné.
signal xp_changed
signal level_up(level: int)
## Niveau, talents ou équipement ont changé : les forces du héros sont recalculées.
signal stats_changed
## La sortie est finie ; `summary` : voir end_sortie().
signal sortie_ended(summary: Dictionary)

## Numéro de la nuit de la sortie en cours.
var night: int = 1
var progress: NightProgress
var profile: Profile
var stats: HeroStats
## Une sortie est en cours (sinon : écran titre ou résumé).
var playing: bool = false
## Le héros est au village (le sac et les talents s'ouvrent depuis la pause).
var at_village: bool = false
## La prochaine scène de nuit lance la sortie tout de suite (Repartir, Nuit suivante).
var start_on_load: bool = false
var rng := RandomNumberGenerator.new()


# Avant le niveau : la scène principale lit le profil dès son entrée dans l'arbre.
func _enter_tree() -> void:
	if profile != null:
		return
	rng.randomize()
	profile = Save.load_profile()
	_apply_settings()
	refresh_stats()
	start_night(profile.night)


func _process(delta: float) -> void:
	if playing:
		progress.advance(delta)


## Prépare la nuit `number` : sanctuaires dont le tambour est déjà au village (le profil n'est
## pas modifié ; voir start_sortie).
func start_night(number: int = 1) -> void:
	night = number
	var banked: Array[bool] = profile.banked if number == profile.night else [] as Array[bool]
	progress = NightProgress.new(Tuning.data.night_drums_required, banked)
	night_started.emit(night)


## Une sortie commence dans la nuit en cours du profil.
func start_sortie() -> void:
	profile.begin_sortie()
	refresh_stats()
	save()
	start_night(profile.night)
	playing = true
	at_village = true
	sortie_started.emit()


## Tambour du sanctuaire `index` (-1 : le premier à prendre) emporté par le héros.
func pick_drum(index: int = -1) -> void:
	if progress.pick_drum(index):
		drum_picked.emit()


## Les tambours portés sont perdus (ils retournent à leurs autels).
func drop_drum() -> void:
	if progress.drop_drums():
		drum_dropped.emit()


## Le héros pose au village les tambours qu'il porte : ils y restent jusqu'à la fin de la nuit, et
## le cadeau de chaque Grand Muet va dans le sac.
func return_drum() -> void:
	var list: Array[int] = progress.return_drums()
	if list.is_empty():
		return
	var gifts: Array[ItemData] = []
	for index: int in list:
		if night == profile.night:
			profile.banked[index] = true
		var gift: ItemData = progress.take_gift(index)
		if gift:
			profile.add_item(gift)
			gifts.append(gift)
	Rhythm.set_layers(music_layers())
	save()
	drum_returned.emit(progress.drums_returned)
	for gift: ItemData in gifts:
		item_found.emit(gift)
	if progress.is_complete():
		night_completed.emit()


## Graine du monde de la nuit : tirée une fois, puis gardée jusqu'à la nuit suivante.
func world_seed() -> int:
	if profile.night_seed == 0:
		profile.night_seed = randi_range(1, 0x7FFFFFFF)
		save()
	return profile.night_seed


## Le Grand Muet du sanctuaire `index` (Roi Muet : `king`) est libéré : son cadeau, tiré au
## sort, voyagera avec le tambour.
func give_gift(index: int, king: bool) -> void:
	progress.set_gift(index, roll_gift(king))


## Le gardien du sanctuaire `index` est libéré.
func free_sanctuary(index: int = -1) -> void:
	if index >= 0:
		progress.free_sanctuary(index)
	sanctuary_freed.emit()


## Un Muet vient d'être libéré (appelé par le Muet) : son expérience est mise de côté jusqu'au
## village.
func on_muet_freed(muet: Node3D) -> void:
	progress.muets_freed += 1
	var tuning: TuningData = Tuning.data
	var species: StringName = muet.get(&"species") if &"species" in muet else &""
	var tier: int = muet.get(&"tier") if &"tier" in muet else 0
	var king: bool = muet.get(&"king") if &"king" in muet else false
	progress.xp_carried += ProgressionMath.muet_xp(species, tier, king, tuning) * stats.xp
	xp_changed.emit()
	muet_freed.emit(muet)


## Le héros arrive au village : l'expérience mise de côté s'ajoute (les niveaux se gagnent ici).
func enter_village() -> void:
	at_village = true
	bank_xp()


func leave_village() -> void:
	at_village = false


## Ajoute l'expérience mise de côté pendant la sortie.
func bank_xp() -> void:
	if progress.xp_carried <= 0.0:
		return
	var amount: float = progress.xp_carried
	progress.xp_carried = 0.0
	add_xp(amount)


## Tire le cadeau d'un Grand Muet (Roi Muet : `king`) : un niveau de plus que la nuit, rareté selon
## qui l'offre.
func roll_gift(king: bool) -> ItemData:
	var tuning: TuningData = Tuning.data
	return ItemMath.roll_item(rng, night + 1, tuning.loot_king_weights if king else tuning.loot_boss_weights, tuning)


## Ajoute de l'expérience ; chaque niveau gagné donne un point de talent.
func add_xp(amount: float) -> void:
	var gained: int = profile.add_xp(amount)
	xp_changed.emit()
	if gained > 0:
		refresh_stats()
		save()
		level_up.emit(profile.level)


func add_page(page: int) -> void:
	progress.add_page(page)
	if profile.add_page(page):
		save()
		page_found.emit(page)


## Un objet trouvé va dans le sac (s'il est plein, le plus faible des objets non portés s'en va).
func add_item(item: ItemData) -> void:
	profile.add_item(item)
	save()
	item_found.emit(item)


## Équipement ou talents : le profil a changé depuis le sac ou les talents.
func profile_changed() -> void:
	refresh_stats()
	save()
	stats_changed.emit()


func refresh_stats() -> void:
	stats = HeroStats.compute(profile, Tuning.data)


## Fin de la sortie : `kind` vaut &"night" (nuit accomplie), &"faint" (évanoui) ou &"quit" (rentré
## au village). Met la saga à jour, sauvegarde et renvoie le résumé : kind, night (nuit jouée),
## next_night, finale (la saga s'achève), banked (tambours au village), muets (libérés pendant la
## sortie), level, time.
func end_sortie(kind: StringName) -> Dictionary:
	bank_xp()
	playing = false
	var played: int = night
	var finale: bool = false
	if kind == &"night":
		finale = profile.complete_current_night()
	save()
	var summary: Dictionary = {
		&"kind": kind, &"night": played, &"next_night": profile.night, &"finale": finale,
		&"banked": progress.drums_returned if kind == &"night" else profile.banked_count(),
		&"muets": progress.muets_freed, &"level": profile.level, &"time": progress.elapsed,
	}
	sortie_ended.emit(summary)
	return summary


## Nouvelle partie : tout est effacé, sauf les réglages et les aides déjà suivies.
func new_game() -> void:
	var fresh: Profile = Profile.create()
	fresh.damage_numbers = profile.damage_numbers
	fresh.debug_info = profile.debug_info
	fresh.muted = profile.muted
	fresh.hints_done = profile.hints_done.duplicate()
	profile = fresh
	refresh_stats()
	save()
	start_night(profile.night)


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


func set_muted(muted: bool) -> void:
	profile.muted = muted
	_apply_settings()
	save()
	settings_changed.emit()


func save() -> void:
	Save.save_profile(profile)


func music_layers() -> int:
	return progress.music_layers(Rhythm.NIGHT_LAYERS.size())


func _apply_settings() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), profile.muted)

