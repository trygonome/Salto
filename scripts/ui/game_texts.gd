class_name GameTexts
## Textes du jeu, repris du prototype (docs/prototype/salto-rpg.html) : nuits de la saga, objectifs,
## bannières, conseils, bulles des villageois, défis, objets, talents, écrans. Les petits mots qui
## montent près de leur source restent courts (charte des retours à l'écran, docs/GDD.md §12).

## Nuits de la saga : titre, Muets rencontrés, réplique du Chef au départ, phrase de fin.
const NIGHTS: Array[Dictionary] = [
	{
		&"title": "Le vol des tambours", &"foes": "Sautillants et volants",
		&"line": "Les Muets ont volé nos trois tambours ! Rapporte-les avant l'aube.",
		&"done": "Les trois tambours sont rentrés ! Mais j'entends déjà des boucliers qui s'entrechoquent…",
	},
	{
		&"title": "La nuit des boucliers", &"foes": "Nouveaux : les porte-boucliers",
		&"line": "Ils ont des boucliers : contourne-les, ou tombe-leur dessus.",
		&"done": "Leurs boucliers n'ont pas tenu ! Mais le sol tremble : des cornus approchent.",
	},
	{
		&"title": "La charge des cornus", &"foes": "Nouveaux : les cornus qui chargent",
		&"line": "Les cornus foncent tout droit. Esquive au dernier moment, ou saute par-dessus !",
		&"done": "Les cornus sont à terre ! Une mélodie muette monte de la brume…",
	},
	{
		&"title": "Le chœur des cracheurs", &"foes": "Nouveaux : les cracheurs de bulles",
		&"line": "Des bulles de silence ! Saute par-dessus ou esquive-les.",
		&"done": "Plus qu'une nuit. Le Roi Muet garde le dernier tambour.",
	},
	{
		&"title": "Le Roi Muet", &"foes": "Le Roi Muet garde le 3e sanctuaire",
		&"line": "C'est la dernière nuit. Rends son tambour à la jungle !",
		&"done": "Le Roi Muet est tombé ! La jungle chante à nouveau.",
	},
]
## Les nuits sans fin, après la saga.
const ENDLESS: Dictionary = {
	&"title": "Les nuits sans fin", &"foes": "Les Muets sont de plus en plus forts",
	&"line": "Les Muets ne renoncent jamais. Jusqu'où iras-tu ?",
	&"done": "Encore une nuit gagnée !",
}
const NIGHT_LABEL := "Nuit %d"
const NIGHT_CHAPTER := "Nuit %d : %s"

const CHIEF_NAME := "Chef Taroum"
const KING_NAME := "Le Roi Muet"
const BOSS_NAME := "Grand Muet %s"
## Conseils du Chef, et ce que disent les danseurs selon les tambours rapportés (puis la fête).
const CHIEF_TIPS: PackedStringArray = [
	"Suis le chemin doré, petit acrobate.",
	"Au village, les Muets n'osent pas entrer.",
	"Frappe sur le battement : c'est là que tu es le plus fort.",
	"Les Muets étaient nos musiciens. Libère-les !",
]
const BARKS: Array = [
	["Sans tambour, mes pieds sont tout mous…", "Mon frère est devenu un Muet… Libère-le !", "Tu entends ce battement ? C'est ton cœur, petit."],
	["J'entends un battement ! Encore !", "Ça revient, je le sens dans mes orteils !"],
	["Deux tambours ! Mes hanches se réveillent !", "Encore un et on danse jusqu'à l'aube !"],
	["Quelle fête ! Regarde-moi ce salto !", "La jungle brille comme jamais !"],
]
## Ce que dit le Chef à chaque tambour rapporté.
const RETURN_LINES: PackedStringArray = [
	"Un tambour ! La jungle respire de nouveau.",
	"Deux tambours ! Plus qu'un !",
	"Les trois tambours sont rentrés !",
]
## Répliques des Muets libérés.
const MUET_FREED_LINES: PackedStringArray = [
	"Ma voix… elle est revenue !",
	"Je me souviens de la chanson !",
	"Merci, petit acrobate !",
	"Enfin, j'entends la jungle !",
]

## Objectifs (bannière du haut) : titre et précision.
const QUEST_RETURN := "Rapporte le tambour au village"
const QUEST_RETURN_SUB := "Le Chef Taroum t'attend près du totem."
const QUEST_PICK := "Ramasse le tambour %s"
const QUEST_PICK_SUB := "Il t'attend sur son autel."
const QUEST_FREE := "Libère le sanctuaire %s"
const QUEST_FREE_SUB := "Un Grand Muet garde le tambour."
const QUEST_FREE_KING_SUB := "Le Roi Muet garde le dernier tambour."
const QUEST_WON := "La jungle danse !"
const QUEST_WON_SUB := "Les trois tambours sont rentrés."
## Distance jusqu'à l'objectif, sous le repère.
const MARKER_DISTANCE := "%d m"

## Bannières (surtitre, titre, précision).
const BANNER_NEW_OBJECTIVE := "Nouvel objectif"
const BANNER_SANCTUARY := "Sanctuaire libéré"
const BANNER_SANCTUARY_TITLE := "Le tambour est à toi !"
const BANNER_SANCTUARY_DETAIL := "Ramasse-le sur son autel"
const BANNER_DRUM := "Tambour rapporté"
const BANNER_DRUM_TITLE := "%d / %d"
const BANNER_DRUM_DETAIL := "Il reste au village, même si tu tombes"
const BANNER_NIGHT_DONE := "Nuit accomplie"
const BANNER_NIGHT_DONE_TITLE := "La jungle danse !"
const BANNER_LEVEL := "Niveau %d"
const BANNER_LEVEL_TITLE := "Point de talent !"
const BANNER_LEVEL_DETAIL := "Dépense-le dans Talents, depuis la pause"
const BANNER_SECOND_WIND := "Second souffle"
const BANNER_SECOND_WIND_TITLE := "Tu te relèves !"
const BANNER_ITEM_STORED := "Rangé dans ton sac"
const BANNER_ITEM_FIRST := "Ouvre ton sac depuis la pause"
const BANNER_ENRAGED := "Gardien"
const BANNER_ENRAGED_TITLE := "Il enrage\u00a0!"
const BANNER_ENRAGED_DETAIL := "Saute par-dessus ses ondes de choc"
const BANNER_CHALLENGE := "Défi réussi"
const BANNER_CHALLENGE_TITLE := "+%d plumes"

## Messages éphémères (toast).
const TOAST_BAG_FULL := "Sac plein : %s recyclé (+%d plumes)"
const TOAST_FAINT := "Tu t'es évanoui…"
const TOAST_ZONE := "Le silence aspire les couleurs… Bats le Grand Muet pour libérer le sanctuaire."
const TOAST_DRUM_LOST := "Tes tambours sont retournés sur leurs autels."

## Mots qui montent près de leur source (un seul à la fois).
const WORD_BLOCKED := "Bloqué"
const WORD_STUNNED := "Étourdi !"
const WORD_PERFECT_DODGE := "Esquive parfaite !"
const WORD_MULTI_HIT := "×%d !"
const WORD_PLUMES := "+%d plumes"
const WORD_HEAL := "+%d"
const WORDS: PackedStringArray = [WORD_BLOCKED, WORD_STUNNED, WORD_PERFECT_DODGE, WORD_MULTI_HIT, WORD_PLUMES, WORD_HEAL]

## Conseils près des boutons (apprentissage par le jeu) : identifiant → texte.
const HINTS: Dictionary[StringName, String] = {
	&"move": "Glisse ton pouce pour courir",
	&"attack": "Frappe !",
	&"jump": "Saute !",
	&"salto": "Encore : salto !",
	&"combo": "Enchaîne 3 coups",
	&"dodge": "Esquive !",
	&"dive": "En l'air, frappe : plongeon !",
	&"beat": "Frappe quand l'anneau se referme",
	&"special": "Jauge pleine : frappe !",
}

## Défis d'une sortie (%d : objectif).
const CHALLENGES: Dictionary[StringName, String] = {
	&"perfect": "Réussis %d coups parfaits",
	&"combo": "Atteins un combo de %d",
	&"multi": "Touche %d Muets d'un seul coup",
	&"dodge": "Réussis %d esquives parfaites",
	&"dive": "Vaincs %d Muets d'un coup plongeant",
}
const CHALLENGE_PROGRESS := "Défi : %s (%d/%d)"
const CHALLENGE_DONE := "Défi réussi : %s"

## Boutons tactiles, HUD.
const PAD_ATTACK := "Frappe"
const PAD_JUMP := "Saut"
const PAD_DODGE := "Esquive"
const LEVEL_CHIP := "Niv. %d"
const HEALTH := "%d / %d"
const COMBO := "combo"

## Écran titre.
const GAME_TITLE := "Salto"
const GAME_SUBTITLE := "La jungle muette"
const START := "Commencer"
const CONTINUE := "Continuer"
const NEW_GAME := "Nouvelle partie"
const NEW_GAME_CONFIRM := "Touche encore pour tout effacer"
const TITLE_PITCH := "Cinq nuits pour rendre ses couleurs à la jungle."
const TITLE_DRUMS := "%s sur 3 au village"
const TITLE_SORTIES := ", %s cette nuit"
const RECORDS := "Meilleur score : %s. Meilleur combo : %d."
const BAG_BUTTON := "Sac et forge (%d plumes)"
const TALENTS_BUTTON := "Talents"
const TALENTS_BUTTON_POINTS := "Talents (%s)"

## Pause.
const PAUSE_TITLE := "Pause"
const RESUME := "Reprendre"
const SOUND_ON := "Son : activé"
const SOUND_OFF := "Son : coupé"
const DAMAGE_NUMBERS_ON := "Chiffres de dégâts : oui"
const DAMAGE_NUMBERS_OFF := "Chiffres de dégâts : non"
const DEBUG_ON := "Infos techniques : oui"
const DEBUG_OFF := "Infos techniques : non"
const QUIT := "Rentrer au village"
const QUIT_CONFIRM := "Touche encore pour rentrer"
const PAUSE_HELP := "Saut deux fois : salto. Frappe trois fois : enchaînement. Frappe en l'air : plongeon, plus fort de haut. Esquive : roulade, ou élan en l'air."

## Résumé d'une sortie.
const SUMMARY_NIGHT := "Nuit accomplie !"
const SUMMARY_FINALE := "La jungle chante !"
const SUMMARY_QUIT := "Retour au village"
const SUMMARY_FAINT := "L'aube se lève"
const SUMMARY_NEXT := "Prochaine nuit : %s."
const SUMMARY_ENDLESS_OPEN := "Les nuits sans fin sont ouvertes."
const SUMMARY_QUIT_SUB := "Tu es rentré sain et sauf. "
const SUMMARY_FAINT_SUB := "Les Muets t'ont eu. "
const SUMMARY_BANKED_ONE := "%s reste au village : il en manque %d."
const SUMMARY_BANKED_MANY := "%s restent au village : il en manque %d."
const SUMMARY_NONE := "Repars : la jungle ne bouge pas tant que la nuit dure."
const SUMMARY_DRUMS := "Tambours de la nuit"
const SUMMARY_MUETS := "Muets libérés"
const SUMMARY_COMBO := "Combo max"
const SUMMARY_PERFECTS := "Coups parfaits"
const SUMMARY_DODGES := "Esquives parfaites"
const SUMMARY_LEVEL := "Niveau atteint"
const SUMMARY_TIME := "Temps"
const SUMMARY_SCORE := "Score"
const SUMMARY_PLUMES := "+%s"
const SUMMARY_CHALLENGE_DONE := "Défi réussi : +%d"
const SUMMARY_CHALLENGE_MISSED := "Défi manqué"
const SUMMARY_RECORD := "Nouveau record !"
const AGAIN := "Repartir"
const NEXT_NIGHT := "Nuit suivante"
const ENDLESS_NIGHT := "Nuit sans fin"
const HOME := "Accueil"
const BACK := "Retour"

## Sac et forge.
const BAG_TITLE := "Sac et forge"
const BAG_SUB := "%s · %d/%d objets"
const BAG_EMPTY := "Les Muets libérés laissent parfois un objet. Les Grands Muets en laissent toujours un."
const SLOT_EMPTY := "Vide"
const ITEM_NEW := "nouveau"
const ITEM_INFO := "%s · %s · niveau %d"
const ITEM_WORN := " · porté"
const ITEM_COMPARE := "Comparé à ton objet porté :"
const EQUIP := "Équiper"
const FORGE := "Forger +%d (%d plumes)"
const RECYCLE := "Recycler (+%d plumes)"
const RARITY_NAMES: PackedStringArray = ["Commun", "Rare", "Épique", "Légendaire"]
## Emplacements : nom, et matières par rareté.
const SLOT_NAMES: PackedStringArray = ["Chevillières", "Masque", "Talisman"]
const SLOT_MATERIALS: Array = [
	["de liane", "de bambou", "de jade", "solaires"],
	["d'écorce", "de corail", "d'obsidienne", "des ancêtres"],
	["de graine", "de nacre", "de lune", "d'étoile"],
]
## Objets légendaires : nom et effet.
const LEGENDARY_NAMES: Dictionary[StringName, String] = {
	&"finale": "Les Pieds du Tonnerre",
	&"shadow": "Le Pas de l'Ombre",
	&"phoenix": "Le Masque du Phénix",
	&"heart": "Le Cœur Battant",
	&"storm": "La Tempête",
}
const LEGENDARY_EFFECTS: Dictionary[StringName, String] = {
	&"finale": "Ton 3e coup libère une onde de choc.",
	&"shadow": "Une esquive parfaite fait exploser le silence autour de toi.",
	&"phoenix": "Une fois par sortie, tu te relèves avec la moitié de tes PV.",
	&"heart": "Chaque coup parfait te soigne de 3 PV.",
	&"storm": "Le Salto arc-en-ciel se charge 30 % plus vite et frappe 50 % plus fort.",
}
const LEGENDARY_MARK := "Unique : %s"
## Effets des objets (%d : valeur, en points ou en pour cent).
const EFFECT_LINES: Dictionary[StringName, String] = {
	&"damage": "+%d % de dégâts",
	&"health": "+%d PV max",
	&"resistance": "+%d % de résistance",
	&"crit": "+%d % de critiques",
	&"speed": "+%d % de vitesse",
	&"attack_speed": "+%d % de vitesse des coups",
	&"groove": "+%d % de jauge de rythme",
	&"dive": "+%d % de dégâts des plongeons",
	&"heal_per_muet": "+%d PV par Muet libéré",
	&"xp": "+%d % d'expérience",
}
## Comparaison : écart en plus (vert) ou en moins (rose).
const COMPARE_UP := "+%s"
const COMPARE_DOWN := "−%s"

## Talents.
const TALENTS_TITLE := "Talents"
const TALENTS_SUB_POINTS := "Niveau %d : %s à dépenser"
const TALENTS_SUB := "Niveau %d : chaque niveau gagné donne un point."
const TALENTS_RESET := "Réinitialiser les talents"
const TALENT_LOCKED := "Il faut %d points en %s"
const BRANCH_NAMES: PackedStringArray = ["Acrobate", "Percussion", "Chamane"]
const TALENT_NAMES: Dictionary[StringName, String] = {
	&"feet": "Pieds légers", &"triple": "Triple saut", &"dash2": "Double élan", &"comet": "Chute de comète",
	&"metro": "Métronome", &"drum": "Grosse caisse", &"roll": "Roulement", &"finale": "Final fracassant",
	&"breath": "Souffle", &"sap": "Sève", &"bark": "Écorce", &"second": "Second souffle",
}
## Effet d'un talent au rang r (%d : valeur au rang r).
const TALENT_EFFECTS: Dictionary[StringName, String] = {
	&"feet": "+%d % de vitesse et de roulade",
	&"triple": "Un saut de plus en l'air.",
	&"dash2": "Deux élans aériens par saut.",
	&"comet": "Plongeons +%d % et plus larges",
	&"metro": "Fenêtre du Parfait +%d %",
	&"drum": "+%d % de dégâts",
	&"roll": "Parfaits : jauge +%d %",
	&"finale": "Ton 3e coup libère une onde de choc.",
	&"breath": "+%d PV max",
	&"sap": "+%d PV par Muet libéré",
	&"bark": "+%d % de résistance",
	&"second": "Une fois par sortie, relève-toi à 40 % PV.",
}

## Pluriels simples : « 1 plume », « 3 plumes ».
const PLUME := "plume"
const DRUM := "tambour"
const POINT := "point"
const SORTIE := "sortie"


## Textes de la nuit `night` (1 à 5, puis les nuits sans fin).
static func night_info(night: int) -> Dictionary:
	return NIGHTS[night - 1] if night >= 1 and night <= NIGHTS.size() else ENDLESS


static func night_name(night: int) -> String:
	return night_info(night)[&"title"]


## « 1 plume », « 3 plumes ».
static func plural(count: int, word: String) -> String:
	return "%d %s%s" % [count, word, "s" if absi(count) > 1 else ""]


## Nombre avec espaces entre les milliers : « 12 450 ».
static func number(value: int) -> String:
	var digits: String = str(absi(value))
	var out: String = ""
	while digits.length() > 3:
		out = " " + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + out


## Nom d'un objet : légendaire, ou emplacement et matière selon la rareté ; « +2 » s'il est forgé.
static func item_name(item: ItemData, with_forge: bool = true) -> String:
	var base: String
	if item.legendary != &"":
		base = LEGENDARY_NAMES[item.legendary]
	else:
		var materials: Array = SLOT_MATERIALS[item.slot]
		base = "%s %s" % [SLOT_NAMES[item.slot], materials[item.rarity]]
	if with_forge and item.forge > 0:
		base += " +%d" % item.forge
	return base


## Valeur affichée d'un effet : points, ou pour cent.
static func effect_amount(effect: StringName, value: float) -> int:
	return roundi(value) if ItemMath.FLAT_EFFECTS.has(effect) else roundi(value * 100.0)


## Ligne d'un effet : « +6 % de dégâts », « +12 PV max ».
static func effect_line(effect: StringName, value: float) -> String:
	return _effect_text(effect, effect_amount(effect, value))


## Lignes d'un objet : ses effets, puis son effet légendaire.
static func item_lines(item: ItemData) -> PackedStringArray:
	var lines := PackedStringArray()
	var values: Dictionary[StringName, float] = item.effect_values()
	for effect: StringName in values:
		lines.append(effect_line(effect, values[effect]))
	if item.legendary != &"":
		lines.append(LEGENDARY_MARK % LEGENDARY_EFFECTS[item.legendary])
	return lines


## Écarts entre `item` et l'objet porté `worn` (peut être null) : en plus (vert) ou en moins (rose) ;
## chaque entrée : [texte, vrai si c'est mieux].
static func compare_lines(item: ItemData, worn: ItemData) -> Array[Array]:
	var mine: Dictionary[StringName, float] = item.effect_values()
	var other: Dictionary[StringName, float] = worn.effect_values() if worn else {} as Dictionary[StringName, float]
	var effects: Array[StringName] = []
	for effect: StringName in mine:
		effects.append(effect)
	for effect: StringName in other:
		if not effects.has(effect):
			effects.append(effect)
	var lines: Array[Array] = []
	for effect: StringName in effects:
		var gap: int = effect_amount(effect, mine.get(effect, 0.0)) - effect_amount(effect, other.get(effect, 0.0))
		if gap == 0:
			continue
		var text: String = _effect_text(effect, absi(gap)).trim_prefix("+")
		lines.append([(COMPARE_UP if gap > 0 else COMPARE_DOWN) % text, gap > 0])
	return lines


## Effet du talent `id` au rang `rank` (au moins 1 pour l'aperçu).
static func talent_effect(id: StringName, rank: int, tuning: TuningData) -> String:
	var text: String = TALENT_EFFECTS[id]
	if not text.contains("%d"):
		return text
	var r: int = maxi(1, rank)
	var value: float = 0.0
	match id:
		&"feet":
			value = tuning.talent_feet_speed * 100.0 * r
		&"comet":
			value = tuning.talent_comet_damage * 100.0 * r
		&"metro":
			value = tuning.talent_metro_window * 100.0 * r
		&"drum":
			value = tuning.talent_drum_damage * 100.0 * r
		&"roll":
			value = tuning.talent_roll_groove * 100.0 * r
		&"breath":
			value = tuning.talent_breath_health * r
		&"sap":
			value = tuning.talent_sap_heal * r
		&"bark":
			value = tuning.talent_bark_resistance * 100.0 * r
	return text.replace("%d", str(roundi(value)))


## Texte du défi `id` pour l'objectif `target`.
static func challenge_text(id: StringName, target: int) -> String:
	return CHALLENGES.get(id, "%d") % target


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


static func _effect_text(effect: StringName, amount: int) -> String:
	return EFFECT_LINES[effect].replace("%d", str(amount))
