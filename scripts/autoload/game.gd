extends Node
## État du jeu, comme la saga du prototype : le profil gardé d'une partie à l'autre (nuit en
## cours, tambours déjà rapportés, niveau, talents, sac, plumes, records, réglages) et la sortie
## en cours (sanctuaires, tambours portés, défi, score). Une sortie se termine quand la nuit est
## accomplie, quand le héros s'évanouit ou quand il rentre au village depuis la pause ; les
## tambours rapportés restent au village jusqu'à la fin de la nuit. Sauvegardé à chaque étape.
## Les éléments du niveau et l'interface écoutent ses signaux.

## La nuit `night` est prête (monde, tambours déjà rapportés, défi).
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
## Un objet est trouvé ; `stored` faux : sac plein, il a été recyclé en plumes.
signal item_found(item: ItemData)
signal settings_changed
## Expérience gagnée ; niveau gagné.
signal xp_changed
signal level_up(level: int)
## Le défi de la sortie avance, ou vient d'être réussi.
signal challenge_changed
signal challenge_done(reward: int)
## Les plumes ont changé (gain en jeu, forge, recyclage).
signal plumes_changed
## Niveau, talents ou équipement ont changé : les forces du héros sont recalculées.
signal stats_changed
## La sortie est finie ; `summary` : voir end_sortie().
signal sortie_ended(summary: Dictionary)

## Défis possibles d'une sortie (un tiré au sort).
const CHALLENGES: Array[StringName] = [&"perfect", &"combo", &"multi", &"dodge", &"dive"]

## Numéro de la nuit de la sortie en cours.
var night: int = 1
var progress: NightProgress
var profile: Profile
var stats: HeroStats
## Une sortie est en cours (sinon : écran titre ou résumé).
var playing: bool = false
## La prochaine scène de nuit lance la sortie tout de suite (Repartir, Nuit suivante).
var start_on_load: bool = false
## Vrai si la dernière nuit accomplie a battu le record de temps.
var new_record: bool = false
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


## Prépare la nuit `number` : sanctuaires dont le tambour est déjà au village, défi (le profil
## n'est pas modifié ; voir start_sortie).
func start_night(number: int = 1) -> void:
	night = number
	var banked: Array[bool] = profile.banked if number == profile.night else [] as Array[bool]
	progress = NightProgress.new(Tuning.data.night_drums_required, banked)
	var tuning: TuningData = Tuning.data
	var id: StringName = CHALLENGES[rng.randi_range(0, CHALLENGES.size() - 1)]
	progress.set_challenge(id, tuning.challenge_targets[id], tuning.challenge_reward)
	new_record = false
	night_started.emit(night)


## Une sortie commence dans la nuit en cours du profil.
func start_sortie() -> void:
	profile.begin_sortie()
	refresh_stats()
	save()
	start_night(profile.night)
	playing = true
	sortie_started.emit()


## Tambour du sanctuaire `index` (-1 : le premier à prendre) emporté par le héros.
func pick_drum(index: int = -1) -> void:
	if progress.pick_drum(index):
		drum_picked.emit()


## Les tambours portés sont perdus (ils retournent à leurs autels).
func drop_drum() -> void:
	if progress.drop_drums():
		drum_dropped.emit()


## Le héros pose au village les tambours qu'il porte : ils y restent jusqu'à la fin de la nuit.
func return_drum() -> void:
	var list: Array[int] = progress.return_drums()
	if list.is_empty():
		return
	for index: int in list:
		if night == profile.night:
			profile.banked[index] = true
	Rhythm.set_layers(music_layers())
	save()
	drum_returned.emit(progress.drums_returned)
	if progress.is_complete():
		new_record = profile.complete_night(night, progress.elapsed)
		save()
		night_completed.emit()


## Graine du monde de la nuit : tirée une fois, puis gardée jusqu'à la nuit suivante.
func world_seed() -> int:
	if profile.night_seed == 0:
		profile.night_seed = randi_range(1, 0x7FFFFFFF)
		save()
	return profile.night_seed


## Le gardien du sanctuaire `index` est libéré.
func free_sanctuary(index: int = -1) -> void:
	if index >= 0:
		progress.free_sanctuary(index)
	sanctuary_freed.emit()


## Un Muet vient d'être libéré (appelé par le Muet) : expérience et score.
func on_muet_freed(muet: Node3D) -> void:
	progress.muets_freed += 1
	var tuning: TuningData = Tuning.data
	var species: StringName = muet.get(&"species") if &"species" in muet else &""
	var tier: int = muet.get(&"tier") if &"tier" in muet else 0
	var king: bool = muet.get(&"king") if &"king" in muet else false
	add_xp(ProgressionMath.muet_xp(species, tier, king, tuning) * stats.xp)
	muet_freed.emit(muet)


## Tire l'objet laissé par un Muet (Grand Muet `boss`, Roi Muet `king`) : niveau de la nuit (un de
## plus pour un Grand Muet), rareté selon qui l'a laissé.
func roll_item(boss: bool, king: bool) -> ItemData:
	var tuning: TuningData = Tuning.data
	var weights: PackedFloat32Array = tuning.loot_king_weights if king else tuning.loot_boss_weights if boss else tuning.loot_muet_weights
	return ItemMath.roll_item(rng, night + (1 if boss else 0), weights, tuning)


## Ajoute de l'expérience ; chaque niveau gagné donne un point de talent.
func add_xp(amount: float) -> void:
	var gained: int = profile.add_xp(amount)
	xp_changed.emit()
	if gained > 0:
		refresh_stats()
		save()
		level_up.emit(profile.level)


## Coup parfait, combo, Muets touchés d'un coup, esquive parfaite, Muet vaincu d'un plongeon :
## ce qui compte pour le score et les défis.
func on_perfect() -> void:
	progress.perfects += 1
	_challenge(&"perfect", 1)


func on_combo(hits: int) -> void:
	progress.max_combo = maxi(progress.max_combo, hits)
	_challenge(&"combo", 0, hits)


func on_multi_hit(count: int) -> void:
	progress.best_multi_hit = maxi(progress.best_multi_hit, count)
	_challenge(&"multi", 0, count)


func on_perfect_dodge() -> void:
	progress.perfect_dodges += 1
	_challenge(&"dodge", 1)


func on_dive_kill() -> void:
	progress.dive_kills += 1
	_challenge(&"dive", 1)


## Plumes trouvées en jeu (perchoirs).
func add_plumes(amount: int) -> void:
	profile.plumes += amount
	save()
	plumes_changed.emit()


func add_page(page: int) -> void:
	progress.add_page(page)
	if profile.add_page(page):
		save()
		page_found.emit(page)


## Un objet trouvé va dans le sac (s'il est plein, il est recyclé en plumes).
func add_item(item: ItemData) -> bool:
	progress.add_item(item)
	var stored: bool = profile.add_item(item)
	save()
	item_found.emit(item)
	if not stored:
		plumes_changed.emit()
	return stored


## Équipement, forge, recyclage, talents : le profil a changé depuis le sac ou les talents.
func profile_changed() -> void:
	refresh_stats()
	save()
	stats_changed.emit()
	plumes_changed.emit()


func refresh_stats() -> void:
	stats = HeroStats.compute(profile, Tuning.data)


## Fin de la sortie : `kind` vaut &"night" (nuit accomplie), &"faint" (évanoui) ou &"quit" (rentré
## au village). Calcule le score et les plumes, met les records et la saga à jour, sauvegarde et
## renvoie le résumé : kind, night (nuit jouée), next_night, finale (la saga s'achève), banked
## (tambours au village), score, record, plumes, challenge (réussi ou non), stats (lignes).
func end_sortie(kind: StringName) -> Dictionary:
	var tuning: TuningData = Tuning.data
	playing = false
	var played: int = night
	var multiplier_score: float = ProgressionMath.night_multiplier(tuning.score_per_night, played)
	var multiplier_plumes: float = ProgressionMath.night_multiplier(tuning.plumes_per_night, played)
	var score: int = progress.score(profile.level, multiplier_score, tuning)
	var plumes: int = progress.plumes(multiplier_plumes, tuning)
	var record: bool = score > profile.best_score and profile.total_sorties > 1
	profile.plumes += plumes
	profile.best_score = maxi(profile.best_score, score)
	profile.best_combo = maxi(profile.best_combo, progress.max_combo)
	var finale: bool = false
	if kind == &"night":
		finale = profile.complete_current_night()
	save()
	var summary: Dictionary = {
		&"kind": kind, &"night": played, &"next_night": profile.night, &"finale": finale,
		&"banked": progress.drums_returned if kind == &"night" else profile.banked_count(),
		&"score": score, &"record": record, &"plumes": plumes,
		&"challenge": progress.challenge, &"challenge_done": progress.challenge_done, &"challenge_reward": progress.challenge_reward,
		&"muets": progress.muets_freed, &"max_combo": progress.max_combo, &"perfects": progress.perfects,
		&"dodges": progress.perfect_dodges, &"level": profile.level, &"time": progress.elapsed,
	}
	plumes_changed.emit()
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


func _challenge(id: StringName, amount: int, value: int = -1) -> void:
	if progress.challenge != id or progress.challenge_done:
		return
	var done: bool = progress.advance_challenge(id, amount, value)
	challenge_changed.emit()
	if done:
		profile.plumes += progress.challenge_reward
		save()
		plumes_changed.emit()
		challenge_done.emit(progress.challenge_reward)
