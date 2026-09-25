class_name GameTexts
## Textes du jeu (docs/GDD.md, annexe et charte des retours à l'écran). Les messages éphémères
## font au plus 5 mots, les aides 2 à 4 mots.

## Noms des nuits (la nuit 1 est la première).
const NIGHT_NAMES: PackedStringArray = [
	"Le vol des tambours",
	"La nuit des boucliers",
	"La charge des cornus",
	"Le chœur des cracheurs",
	"Le Roi Muet",
]
const NIGHT_LABEL := "Nuit %d"
## Réplique du Chef Taroum au début de chaque nuit (numéro de la nuit → texte).
const CHIEF_NIGHT_START: Dictionary[int, String] = {
	1: "Les Muets ont volé nos trois tambours ! Rapporte-les avant l'aube.",
}
const CHIEF_NAME := "Chef Taroum"
## Répliques des Muets libérés.
const MUET_FREED_LINES: PackedStringArray = [
	"Ma voix… elle est revenue !",
	"Je me souviens de la chanson !",
	"Merci, petit acrobate !",
	"Enfin, j'entends la jungle !",
]

## Grands titres (3 moments seulement : début de nuit, sanctuaire libéré, nuit accomplie).
const TITLE_SANCTUARY_FREED := "Sanctuaire libéré"
const TITLE_NIGHT_COMPLETE := "Nuit accomplie"

## Messages éphémères.
const MESSAGE_DRUM_PICKED := "Rapporte le tambour au village"
const MESSAGE_DRUM_LOST := "Tambour perdu !"
const MESSAGE_PAGE_FOUND := "Nouvelle page du carnet"
const MESSAGES: PackedStringArray = [MESSAGE_DRUM_PICKED, MESSAGE_DRUM_LOST, MESSAGE_PAGE_FOUND]

## Menus.
const PAUSE_TITLE := "Pause"
const RESUME := "Reprendre"
const NOTEBOOK := "Carnet"
const BAG := "Sac"
const SETTINGS := "Réglages"
const RESTART_NIGHT := "Recommencer la nuit"
const BACK := "Retour"
const SETTING_DAMAGE_NUMBERS := "Chiffres de dégâts"
const SETTING_DEBUG_INFO := "Infos techniques"
const NOTEBOOK_COUNT := "%d / %d pages"
const PAGE_MISSING := "Page %d — pas encore trouvée"
const PAGE_TITLE := "Page %d"
const BAG_EMPTY := "Le sac est vide."
const END_TIME := "Temps"
const END_BEST_TIME := "Record"
const END_NEW_RECORD := "Nouveau record !"
const END_MUETS_FREED := "Muets libérés"
const END_PAGES := "Carnet"
const END_ITEMS := "Objets trouvés"
const PLAY_AGAIN := "Rejouer la nuit"

## Noms des objets : pour chaque emplacement (chevillières, masque, talisman), les quatre
## raretés dans l'ordre.
const ITEM_NAMES: PackedStringArray = [
	"Chevillières communes", "Chevillières rares", "Chevillières épiques", "Chevillières légendaires",
	"Masque commun", "Masque rare", "Masque épique", "Masque légendaire",
	"Talisman commun", "Talisman rare", "Talisman épique", "Talisman légendaire",
]
## Nom de chaque effet d'objet.
const EFFECT_LABELS: Dictionary[StringName, String] = {
	&"attack_speed": "Vitesse de frappe",
	&"crit": "Coups critiques",
	&"damage": "Dégâts",
	&"dive": "Plongeon",
	&"groove": "Groove",
	&"heal_per_muet": "PV par Muet libéré",
	&"health": "PV max",
	&"resistance": "Résistance",
	&"speed": "Vitesse",
	&"xp": "Expérience",
}
## Effets comptés en points (les autres sont des pourcentages).
const FLAT_EFFECTS: Array[StringName] = [&"health", &"heal_per_muet"]


static func night_name(night: int) -> String:
	return NIGHT_NAMES[night - 1]


static func item_name(item: ItemData) -> String:
	return ITEM_NAMES[item.slot * ItemData.Rarity.size() + item.rarity]


## Ligne d'un effet : « Dégâts +6 % » (espace insécable), « PV max +12 ».
static func effect_line(effect: StringName, value: float) -> String:
	if FLAT_EFFECTS.has(effect):
		return "%s +%d" % [EFFECT_LABELS[effect], roundi(value)]
	return "%s +%d\u00a0%%" % [EFFECT_LABELS[effect], roundi(value * 100.0)]


## Durée en minutes et secondes : « 4:07 ».
static func duration(seconds: float) -> String:
	var total: int = floori(seconds)
	return "%d:%02d" % [floori(seconds / 60.0), total % 60]


## Nombre de mots d'un texte (la ponctuation isolée ne compte pas).
static func word_count(text: String) -> int:
	var count: int = 0
	for word: String in text.split(" ", false):
		if word.strip_edges().lstrip("!?…:;,.") != "":
			count += 1
	return count
