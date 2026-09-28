class_name Village
## Le village vivant (version 2.7) : les plumes d'or rapportées des expéditions rebâtissent ses
## cases, et chaque case change quelque chose :
##  - l'autel des esprits : un don de plus au choix ;
##  - la case du tambourinaire : les rencontres paraissent plus souvent ;
##  - la source : des PV de départ en plus (trois rangs) ;
##  - la scène : la troupe accompagne l'expédition, la musique part avec une couche de plus.
## Au retour, le Chef Taroum commente l'expédition (`chief_lines`). Logique pure : les prix et les
## effets viennent de Tuning (village_*).

const ALTAR := &"altar"
const DRUM_HUT := &"drum_hut"
const SPRING := &"spring"
const STAGE := &"stage"
const IDS: Array[StringName] = [ALTAR, DRUM_HUT, SPRING, STAGE]


## Rang de la case `id` (0 : pas encore rebâtie).
static func rank(profile: Profile, id: StringName) -> int:
	return profile.village.get(id, 0)


static func max_rank(id: StringName, tuning: TuningData) -> int:
	return (tuning.village_costs.get(id, PackedInt32Array()) as PackedInt32Array).size()


## Prix du rang suivant de la case `id` (-1 : déjà au rang maximal).
static func cost(profile: Profile, id: StringName, tuning: TuningData) -> int:
	var costs: PackedInt32Array = tuning.village_costs.get(id, PackedInt32Array())
	var level: int = rank(profile, id)
	return costs[level] if level < costs.size() else -1


static func can_build(profile: Profile, id: StringName, tuning: TuningData) -> bool:
	var price: int = cost(profile, id, tuning)
	return price >= 0 and profile.feathers >= price


## Rebâtit la case `id` d'un rang contre des plumes d'or ; faux si c'est impossible.
static func build(profile: Profile, id: StringName, tuning: TuningData) -> bool:
	if not can_build(profile, id, tuning):
		return false
	profile.feathers -= cost(profile, id, tuning)
	profile.village[id] = rank(profile, id) + 1
	return true


## Cases rebâties (au moins un rang).
static func built_count(profile: Profile) -> int:
	var count: int = 0
	for id: StringName in IDS:
		if rank(profile, id) > 0:
			count += 1
	return count


## Dons proposés en plus à chaque offre (autel des esprits).
static func extra_boons(profile: Profile) -> int:
	return rank(profile, ALTAR)


## PV de départ en plus (source).
static func extra_health(profile: Profile, tuning: TuningData) -> float:
	return rank(profile, SPRING) * tuning.village_spring_health


## Rencontres en plus dans le tirage des passages (case du tambourinaire).
static func extra_encounters(profile: Profile) -> int:
	return rank(profile, DRUM_HUT)


## Couches de musique au départ de l'expédition (scène : une de plus).
static func music_layers(profile: Profile) -> int:
	return 1 + rank(profile, STAGE)


## Couches des régions dont le gardien est libéré (version 3.7 : chaque gardien rend la sienne à la
## musique du village) ; le Grand Muet du Sous-bois, lui, rend la voix de la troupe.
static func guardian_layers(profile: Profile) -> Array[StringName]:
	var layers: Array[StringName] = []
	for region: StringName in profile.regions_won:
		if Rhythm.REGION_LAYERS.has(region):
			layers.append(region)
	return layers


## Voix de la troupe au village : celle de la scène, plus forte une fois le Grand Muet libéré.
static func village_band(profile: Profile, tuning: TuningData) -> float:
	var band: float = band_floor(profile, tuning)
	if profile.regions_won.has(Regions.UNDERGROWTH):
		band = maxf(band, tuning.village_guardian_band)
	return band


## Voix de la troupe pendant l'expédition, même sans combo (scène).
static func band_floor(profile: Profile, tuning: TuningData) -> float:
	return tuning.village_stage_band if rank(profile, STAGE) > 0 else 0.0


## Premières fois dont le Chef parle, de la plus marquante à la moins marquante (version 3.7).
const FIRSTS_ORDER: Array[StringName] = [&"hidden", &"stele", &"duo", &"pact"]
## Le Chef parle des chutes à la 3e, puis toutes les CHIEF_FALLS_EVERY.
const CHIEF_FALLS_FIRST := 3
const CHIEF_FALLS_EVERY := 5


## Réplique qui réagit à ce qui s'est passé (version 3.7) : une première fois (Muet doré caché, stèle,
## don double, pacte, nouvel instrument), les chutes qui s'accumulent, sinon la famille de dons qui a
## porté le héros ; vide si rien à dire.
static func reaction(summary: Dictionary) -> String:
	var firsts: Array = summary.get(&"firsts", [])
	for event: StringName in FIRSTS_ORDER:
		if firsts.has(event):
			return GameTexts.CHIEF_FIRSTS[event]
	for event: Variant in firsts:
		var id: String = str(event)
		if id.begins_with("weapon_"):
			return GameTexts.CHIEF_FIRST_WEAPON % GameTexts.WEAPON_NAMES.get(StringName(id.trim_prefix("weapon_")), "")
	var faints: int = summary.get(&"faints", 0)
	if summary.get(&"kind", &"") == &"faint" and (faints == CHIEF_FALLS_FIRST or (faints > CHIEF_FALLS_FIRST and faints % CHIEF_FALLS_EVERY == 0)):
		return GameTexts.CHIEF_FALLS % faints
	var family: StringName = summary.get(&"family", &"")
	return GameTexts.CHIEF_FAMILY.get(family, "")


## Ce que dit le Chef au retour de l'expédition `summary` (vide : on arrive au village sans en
## revenir), une réplique à la fois ; la dernière rappelle de rebâtir si les plumes le permettent.
## `summary` : voir Game.end_run (kind, room, rooms, record, region, unlocked, fallen_to,
## boss_left).
static func chief_lines(summary: Dictionary, profile: Profile, tuning: TuningData) -> PackedStringArray:
	var lines := PackedStringArray()
	var kind: StringName = summary.get(&"kind", &"")
	var region: StringName = summary.get(&"region", Regions.UNDERGROWTH)
	var guardian: String = GameTexts.GUARDIAN_NAMES.get(region, GameTexts.ROOM_BOSS_TITLE)
	match kind:
		&"won":
			var unlocked: StringName = summary.get(&"unlocked", &"")
			if unlocked != &"":
				lines.append(GameTexts.CHIEF_UNLOCKED % GameTexts.REGION_NAMES.get(unlocked, ""))
			elif profile.runs_won == 1:
				lines.append(GameTexts.CHIEF_FIRST_WIN)
			else:
				lines.append(GameTexts.CHIEF_WON % guardian)
		&"faint":
			var room: int = summary.get(&"room", 0)
			var boss_left: float = summary.get(&"boss_left", -1.0)
			var fallen_to: StringName = summary.get(&"fallen_to", &"")
			if room >= int(summary.get(&"rooms", 0)) and boss_left >= 0.0:
				lines.append((GameTexts.CHIEF_BOSS_CLOSE if boss_left <= tuning.village_close_boss else GameTexts.CHIEF_BOSS_LOST) % guardian)
			elif summary.get(&"record", false) and room > 1:
				lines.append(GameTexts.CHIEF_RECORD % room)
			elif GameTexts.CHIEF_FALLEN.has(fallen_to):
				lines.append(GameTexts.CHIEF_FALLEN[fallen_to])
			elif room <= 2:
				lines.append(GameTexts.CHIEF_EARLY)
			else:
				lines.append(GameTexts.CHIEF_FAINT)
		&"quit":
			lines.append(GameTexts.CHIEF_QUIT)
		_:
			lines.append(GameTexts.CHIEF_WELCOME if profile.best_room == 0 else GameTexts.CHIEF_HELLO[profile.total_sorties % GameTexts.CHIEF_HELLO.size()])
	if kind != &"":
		var reactive: String = reaction(summary)
		if reactive != "":
			lines.append(reactive)
	var cheapest: int = -1
	for id: StringName in IDS:
		var price: int = cost(profile, id, tuning)
		if price >= 0 and (cheapest < 0 or price < cheapest):
			cheapest = price
	if cheapest >= 0 and profile.feathers >= cheapest:
		lines.append(GameTexts.CHIEF_BUILD % profile.feathers)
	return lines
