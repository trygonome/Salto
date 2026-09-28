class_name GameTexts
## Textes du jeu, repris du prototype (docs/prototype/salto-rpg.html) : nuits de la saga, objectifs,
## bannières, conseils, bulles des villageois, objets, talents, écrans. Les petits mots qui
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
	"Reviens souvent : c'est au village que tu grandis.",
	"Ramène un tambour, et le cadeau de son Grand Muet vient avec.",
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

## Le Chef, quand le héros grandit au village.
const LEVEL_UP_LINES: PackedStringArray = [
	"Tu grandis, petit acrobate !",
	"Tes pieds deviennent légers !",
	"La jungle t'a appris des choses !",
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

## Grands titres (surtitre, titre, précision) : trois moments seulement (charte des retours à
## l'écran) : début de nuit, sanctuaire libéré, nuit accomplie.
const BANNER_SANCTUARY := "Sanctuaire libéré"
const BANNER_SANCTUARY_TITLE := "Le tambour est à toi !"
const BANNER_SANCTUARY_DETAIL := "Ramasse-le sur son autel"
const BANNER_NIGHT_DONE := "Nuit accomplie"
const BANNER_NIGHT_DONE_TITLE := "La jungle danse !"

## Expédition : écran titre, clairières, récompenses, résumé.
const EXPEDITION_TITLE := "Expédition"
const EXPEDITION_PITCH := "Traverse les clairières, choisis tes dons, libère le Grand Muet."
const EXPEDITION_START := "Partir en expédition"
const EXPEDITION_INFO := "%d plumes d'or · meilleure : clairière %d"
const ROOM_TITLE := "Clairière %d / %d"
const ROOM_FIGHT := "Libère les Muets · %s"
const ROOM_BOSS_TITLE := "Le Grand Muet"
const ROOM_BOSS_SUB := "Libère-le pour sortir de la jungle"
const ROOM_CHOOSE := "Choisis ton passage"
const REWARD_NAMES: Dictionary[StringName, String] = {
	&"boon": "don des esprits", &"heal": "soin", &"feathers": "plumes d'or", &"boss": "le gardien",
	&"encounter": "rencontre", &"rest": "repos", &"treasure": "trésor", &"secret": "secret",
}
## Noms des clairières, par forme (tirés de la graine).
const ROOM_NAMES: Dictionary[StringName, PackedStringArray] = {
	&"clearing": ["Clairière des Lianes", "Clairière du Silence", "Pré des Lucioles", "Clairière aux Pierres"],
	&"ruins": ["Ruines du Tambour Brisé", "Cercle des Anciens", "Autel Oublié", "Temple Muet"],
	&"grove": ["Bosquet des Murmures", "Sous-bois des Échos", "Bosquet Endormi"],
	&"logs": ["Troncs Couchés", "Chablis du Vieux Fromager", "Passage des Troncs"],
	&"mushrooms": ["Champignonnière", "Jardin des Chapeaux", "Clairière qui Rebondit"],
	&"arena": ["Arène du Gardien"],
	&"flooded": ["Gué des Pierres", "Rivière Muette", "Bras Engloutis"],
	&"heights": ["Passerelles des Cimes", "Plateformes du Vent", "Belvédère des Lianes"],
}
const ROOM_COUNT := "%s · %d/%d"
const ROOM_ENCOUNTER := "Rencontre · approche-toi"
## Rencontres : nom, ce qu'on voit ou entend, deux choix (%d : valeur du réglage).
const ENCOUNTER_NAMES: Dictionary[StringName, String] = {
	&"spring": "La source des anciens", &"merchant": "Le marchand muet",
	&"drummer": "Le vieux tambourinaire", &"wounded": "Un villageois perdu",
	&"rest": "Le feu de camp", &"weaver_lady": "La Tisseuse de couleurs",
	&"echo_spirit": "L'Écho solitaire", &"mute_tree": "L'Arbre muet",
}
const ENCOUNTER_TEXTS: Dictionary[StringName, String] = {
	&"spring": "Une eau claire chante entre les pierres. On dit qu'elle se souvient de la musique.",
	&"merchant": "Un Muet libéré a gardé quelques trésors. Il ne parle pas encore, mais il te montre ses plumes d'or.",
	&"drummer": "« Le rythme est en toi, petit. Assieds-toi, écoute le vieux Kamba. »",
	&"wounded": "« Je cherchais les tambours… les Muets m'ont surpris. Je ne retrouve plus le village. »",
	&"rest": "Un feu crépite entre les racines. Ici, les Muets ne viennent pas.",
	&"weaver_lady": "Elle tisse des fils volés aux Muets. « Un fil pour une plume, petit ? »",
	&"echo_spirit": "Une voix répète chacun de tes pas, un temps plus tard. Elle attend ta réponse.",
	&"mute_tree": "Un fromager immense, gris comme les Muets. Ses racines battent encore, tout doucement.",
}
const ENCOUNTER_CHOICES: Dictionary[StringName, PackedStringArray] = {
	&"spring": ["Boire : tous tes PV reviennent", "Y plonger la main : un don, contre %d % de tes PV"],
	&"merchant": ["Donner %d plumes d'or : un don", "Le saluer : un peu de soin"],
	&"drummer": ["Apprendre son rythme : Tempo, un rang", "Écouter son histoire : une page du carnet, un peu de soin"],
	&"wounded": ["Le soigner (−%d PV) : il t'offre un objet", "Lui montrer le chemin : +%d plumes d'or"],
	&"rest": ["Te reposer : +%d % de PV", "Affûter un don : un rang de plus"],
	&"weaver_lady": ["Donner %d plumes d'or : un don rare ou mieux", "Lui offrir une couleur : ta jauge de groove se remplit"],
	&"echo_spirit": ["Lui répondre : un don double", "L'écouter : Écho du tambour, un rang"],
	&"mute_tree": ["Frapper ses racines : un don de la Sève, rare", "Dormir à son ombre : +%d % de PV"],
}
const FEATHERS_FOUND := "+%d plumes d'or"
const HEALED := "Soin : +%d PV"
const BOON_SHARPENED := "%s : un rang de plus"
const BOON_TITLE := "Don des esprits"
const BOON_SUB := "Choisis un don pour cette expédition"
const BOON_RANK := "Rang %d"
const BOON_NEW := "Nouveau"
const BOON_NAMES: Dictionary[StringName, String] = {
	&"ember": "Pied de braise", &"meteor": "Plongeon météore", &"fury": "Furie", &"blaze": "Brasier",
	&"cinders": "Cendres", &"forge": "Coup de forge", &"prism": "Prisme",
	&"bark": "Écorce", &"counterpoint": "Contre-courant", &"dazzle": "Éblouissement", &"mist": "Brume",
	&"tide": "Ressac", &"frost": "Givre",
	&"heart": "Cœur de la jungle", &"thorns": "Roulade épineuse", &"sap": "Sève", &"regrowth": "Repousse",
	&"anchor": "Ancrage",
	&"swift": "Pieds légers", &"tempo": "Tempo", &"halo": "Halo", &"splash": "Éclaboussure",
	&"rainbow": "Arc-en-ciel", &"echo": "Écho du tambour", &"hawk": "Œil du faucon",
	&"wildfire": "Feu de joie", &"geyser": "Geyser", &"sacred_grove": "Bosquet sacré", &"bloom": "Floraison",
}
## Effet d'un don au rang offert (%d : sa valeur).
const BOON_TEXTS: Dictionary[StringName, String] = {
	&"ember": "Tes coups brûlent : %d % de ton attaque par seconde.",
	&"meteor": "Plongeon : +%d % de dégâts, onde plus large.",
	&"fury": "+%d % de dégâts et de vitesse des coups.",
	&"blaze": "+%d % de dégâts aux Muets en feu.",
	&"cinders": "Un Muet libéré enflamme ses voisins.",
	&"forge": "Coup chargé : +%d % de dégâts, et il brûle.",
	&"prism": "Critiques : +%d % de dégâts.",
	&"bark": "−%d % de dégâts reçus.",
	&"counterpoint": "Riposte : +%d % de dégâts.",
	&"dazzle": "%d % de chances d'étourdir le Muet touché.",
	&"mist": "Roulade : invulnérable plus longtemps (+%d %).",
	&"tide": "Ta roulade repousse les Muets traversés.",
	&"frost": "Les Muets touchés sont ralentis (−%d %).",
	&"heart": "+%d PV max.",
	&"thorns": "Ta roulade blesse les Muets traversés.",
	&"sap": "+%d PV par Muet libéré.",
	&"regrowth": "+%d PV à chaque clairière nettoyée.",
	&"anchor": "+%d % d'équilibre brisé par tes coups.",
	&"swift": "+%d % de vitesse de course et de roulade.",
	&"tempo": "+%d % de vitesse des coups.",
	&"halo": "+%d % de groove gagné.",
	&"splash": "Chaque Muet libéré : +%d % de groove.",
	&"rainbow": "Salto arc-en-ciel : +%d % de dégâts.",
	&"echo": "Ton dernier coup de l'enchaînement libère une onde.",
	&"hawk": "+%d % de chances de critique.",
	&"wildfire": "Un critique enflamme le Muet.",
	&"geyser": "Une esquive parfaite fait jaillir une onde brûlante.",
	&"sacred_grove": "Chaque esquive parfaite rend %d PV.",
	&"bloom": "Le Salto arc-en-ciel rend %d % de tes PV.",
}
## Familles et raretés, sur les cartes.
const BOON_FAMILY_NAMES: Dictionary[StringName, String] = {
	&"feu": "Feu", &"eau": "Eau", &"seve": "Sève", &"vent": "Vent",
}
const BOON_RARITY_NAMES: Dictionary[StringName, String] = {
	&"common": "", &"rare": "Rare", &"epic": "Épique", &"duo": "Don double",
}
const BOON_TAG := "%s · %s"
const BOON_DUO_TAG := "%s + %s"
## Dons qui se comptent en nombre (PV) ; les autres en pour cent.
const BOON_FLAT: Array[StringName] = [&"heart", &"sap", &"regrowth", &"sacred_grove"]
const RUN_WON := "Jungle libérée !"
const RUN_LOST := "L'expédition s'arrête"
const RUN_QUIT := "Retour au camp"
const RUN_WON_SUB := "Le Grand Muet a retrouvé sa voix. Tu rapportes %s."
const RUN_LOST_SUB := "Tu es tombé à la clairière %d. Tu rapportes %s."
const RUN_QUIT_SUB := "Tu rentres de la clairière %d. Tu rapportes %s."
const RUN_ROOMS := "Clairières"
const RUN_BOONS := "Dons"
const RUN_AGAIN := "Nouvelle expédition"
const FEATHER_ONE := "%d plume d'or"
const FEATHER_MANY := "%d plumes d'or"

## Carte d'une page du carnet trouvée.
const PAGE_FOUND := "Page %d du carnet"

## Grand Muet libéré : il retrouve sa voix (bulle au-dessus de lui, docs/GDD.md, annexe).
const BOSS_FREED_LINES: PackedStringArray = [
	"Ma voix… elle est revenue !",
	"Je me souviens de la chanson !",
	"Merci, petit acrobate !",
	"Enfin, j'entends la jungle !",
]

## Messages éphémères (toast).
const TOAST_SECOND_WIND := "Second souffle !"
const TOAST_FAINT := "Tu t'es évanoui…"

## Mots qui montent près de leur source (un seul à la fois).
const WORD_BLOCKED := "Bloqué"
const WORD_STUNNED := "Étourdi !"
const WORD_PERFECT_DODGE := "Esquive parfaite !"
const WORD_HEAL := "+%d"
const WORD_BREAK := "Brisé !"
const WORD_GRACE := "Grâce !"
const WORD_RIPOSTE := "Riposte !"
const WORD_EVADED := "Esquivé !"
const WORD_SECRET := "Un passage !"
const WORDS: PackedStringArray = [WORD_BLOCKED, WORD_STUNNED, WORD_PERFECT_DODGE, WORD_HEAL, WORD_BREAK, WORD_GRACE, WORD_RIPOSTE, WORD_EVADED, WORD_SECRET]

## Régions (version 2.6) et leurs gardiens.
const REGION_NAMES: Dictionary[StringName, String] = {
	&"undergrowth": "Sous-bois", &"sunken": "Ruines englouties", &"canopy": "Canopée",
}
const REGION_LOCKED := "Libère le gardien d'avant"
const RUN_REGION := "Région"
const RUN_UNLOCKED := "Nouvelle région"
const GUARDIAN_NAMES: Dictionary[StringName, String] = {
	&"undergrowth": "Le Grand Muet", &"sunken": "Le Gardien des Ruines", &"canopy": "La Reine des Cimes",
}
const REGION_UNLOCKED := "Nouvelle région : %s"

## Village vivant (version 2.7) : les cases à rebâtir, ce qu'elles font, ce qu'on y entend ; le
## Chef qui commente l'expédition.
## Instruments-armes (version 2.8).
const WEAPON_NAMES: Dictionary[StringName, String] = {
	&"rainstick": "Bâton de pluie", &"maracas": "Maracas jumelles", &"hammer": "Tambour-marteau", &"blowpipe": "Sarbacane",
}
const WEAPON_TEXTS: Dictionary[StringName, String] = {
	&"rainstick": "Trois coups de pied, le dernier en tournoyant.",
	&"maracas": "Quatre secousses très rapides : le combo monte vite.",
	&"hammer": "Deux frappes lentes qui écrasent tout autour.",
	&"blowpipe": "Des fléchettes à distance ; la troisième en éventail, qui traverse.",
}
const RACK_TITLE := "Le râtelier des instruments"
const RACK_TEXT := "Choisis ton instrument pour la prochaine expédition."
const WEAPON_TAKEN := "%s en main !"
## Confort mobile (version 2.9) : reprise, pactes, calibration du son.
const EXPEDITION_RESUME := "Reprendre · clairière %d/%d"
const PAUSE_EXPEDITION := "Expédition · %s"
const PACTS_TITLE := "La pierre des pactes"
const PACTS_TEXT := "Rends l'expédition plus rude : tu rapporteras plus de plumes d'or."
const PACTS_DONE := "C'est décidé : partir ainsi"
const PACT_NAMES: Dictionary[StringName, String] = {
	&"thick_skin": "Peaux épaisses", &"hard_hits": "Coups rudes", &"fragile": "Cœur fragile", &"stingy": "Jungle avare",
}
const PACT_TEXTS: Dictionary[StringName, String] = {
	&"thick_skin": "+%d % de PV pour les Muets", &"hard_hits": "Les Muets frappent %d % plus fort",
	&"fragile": "Tu pars avec %d % de PV en moins", &"stingy": "Ni soin ni repos en chemin",
}
const PACT_CHOICE := "%s%s : %s · +%d %% de plumes"
const PACT_ON := " (actif)"
const PACTS_SUB := " · pactes : +%d %% de plumes"
const RUN_PACTS := "Pactes"
const CALIBRATE_BUTTON := "Calibrer le son"
const CALIBRATE_TITLE := "Calibrer le son"
const CALIBRATE_HELP := "Touche le tambour sur chaque temps de la musique."
const CALIBRATE_TAP := "Tambour"
const CALIBRATE_COUNT := "%d / %d"
const CALIBRATE_RESULT := "Décalage : %+d ms"
const CALIBRATE_RESET := "Remettre à zéro"
const CALIBRATE_DONE := "Terminé"
const VILLAGE_TITLE := "Le village"
const VILLAGE_SUB := "%s · départ au nord"
const VILLAGE_BUTTON := "Le village"
const VILLAGE_DEPART := "Partir en expédition"
const BUILDING_NAMES: Dictionary[StringName, String] = {
	&"altar": "L'autel des esprits", &"drum_hut": "La case du tambourinaire",
	&"spring": "La source", &"stage": "La scène",
}
const BUILDING_TEXTS: Dictionary[StringName, String] = {
	&"altar": "Des pierres renversées, des plumes éparses. Rebâti, les esprits t'offriront un don de plus au choix.",
	&"drum_hut": "Une case sans toit où dormait Kamba. Rebâtie, les rencontres paraîtront plus souvent dans la jungle.",
	&"spring": "Un bassin à sec. Chaque pierre remise en place : +%d PV au départ de l'expédition.",
	&"stage": "Des planches et des mâts tombés. Rebâtie, la troupe t'accompagnera et la musique partira plus riche.",
}
## Ce que disent les cases rebâties quand on s'en approche (le monde parle d'abord).
const BUILDING_LINES: Dictionary[StringName, String] = {
	&"altar": "Les esprits t'attendent : un don de plus au choix.",
	&"drum_hut": "Kamba bat le rappel : les rencontres viennent à toi.",
	&"spring": "L'eau chante : +%d PV au départ.",
	&"stage": "La troupe répète pour ta prochaine expédition !",
}
const BUILD_CHOICE := "Rebâtir : %d plumes d'or"
const BUILD_MORE := "Agrandir (rang %d) : %d plumes d'or"
const BUILD_LATER := "Plus tard"
const BUILD_DONE := "%s est rebâtie !"
const BUILD_MISSING := "Il te manque %d plumes d'or"
## Le Chef au retour de l'expédition (une réplique à la fois, au-dessus de lui).
const CHIEF_WELCOME := "Bienvenue, petit. Nos cases sont en ruine : tes plumes d'or les rebâtiront."
const CHIEF_HELLO: PackedStringArray = [
	"La jungle t'attend, petit acrobate.",
	"Écoute : même les ruines battent la mesure.",
	"Chaque plume d'or rend un peu de vie au village.",
]
const CHIEF_FIRST_WIN := "Le gardien chante à nouveau ! Tout le village danse pour toi !"
const CHIEF_WON := "%s est libéré ! Les tambours te remercient."
const CHIEF_UNLOCKED := "La route des %s est ouverte. Prends garde à son gardien."
const CHIEF_BOSS_CLOSE := "%s vacillait déjà ! La prochaine fois, il chantera."
const CHIEF_BOSS_LOST := "%s est fort. Reviens avec plus de dons."
const CHIEF_RECORD := "Clairière %d ! Jamais un tambourinaire n'était allé si loin."
const CHIEF_EARLY := "Déjà de retour ? La jungle ne pardonne pas les pas pressés."
const CHIEF_FAINT := "Tu t'es relevé, c'est l'essentiel. Repose-toi et repars."
const CHIEF_QUIT := "Sage de rentrer. La jungle attendra."
const CHIEF_BUILD := "Tu as %d plumes d'or : de quoi rebâtir une case !"
## Tombé face à une espèce : le Chef rappelle sa réponse.
const CHIEF_FALLEN: Dictionary[StringName, String] = {
	&"hopper": "Les Sautillants t'ont eu ? Enchaîne : le 3e coup les envoie valser.",
	&"flyer": "Les Volants ? Esquive leur piqué, puis frappe-les au sol.",
	&"shielder": "Un bouclier ne protège que de face : passe derrière, ou plonge dessus.",
	&"charger": "Le Cornu charge tout droit : esquive au dernier moment, il s'assomme.",
	&"spitter": "Les Cracheurs ? Saute leurs bulles et fonce : un coup roulé les fait taire.",
	&"weaver": "Le Tisserand ? Sors vite des ronces, puis plonge sur lui.",
	&"totem": "Abats d'abord le Totem : tant qu'il chante, les autres tiennent.",
	&"dancer": "Le Danseur esquive un coup sur deux : esquive sa vrille, puis riposte.",
	&"brute": "La Brute lève les poings avant de bondir : esquive, puis frappe quand elle souffle.",
	&"trap": "Les pièges suivent la musique : écoute le temps d'avant.",
}

## Muets : nom de chaque espèce, et nom d'un élite (espèce + particularité).
const SPECIES_NAMES: Dictionary[StringName, String] = {
	&"hopper": "Sautillant", &"flyer": "Volant", &"shielder": "Porte-bouclier", &"charger": "Cornu",
	&"spitter": "Cracheur", &"weaver": "Tisserand", &"totem": "Totem chanteur", &"dancer": "Danseur",
	&"brute": "Brute", &"boss": "Grand Muet",
}
const ELITE_NAMES: Dictionary[StringName, String] = {
	&"swift": "%s vif", &"armored": "%s cuirassé", &"volatile": "%s éclatant", &"caller": "%s appelant",
	&"golden": "%s doré",
}
const ELITE_BOON_TITLE := "Don de l'élite"

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
	&"answer_flyer": "Esquive le piqué, frappe !",
	&"answer_shielder": "Saute, plonge dessus !",
	&"answer_charger": "Esquive, puis frappe !",
	&"answer_spitter": "Roule, puis frappe !",
	&"answer_hopper": "Enchaîne : le dernier coup le projette !",
	&"answer_weaver": "Sors des ronces, plonge sur lui !",
	&"answer_totem": "Le totem d'abord : maintiens Frappe !",
	&"answer_dancer": "Esquive sa vrille, puis riposte !",
	&"answer_brute": "Esquive son bond, frappe quand elle souffle !",
	&"grace": "Il chancelle : frappe !",
	&"charge": "Maintiens Frappe : coup chargé",
	&"gongs": "Rejoue la mélodie !",
}

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
const BAG_BUTTON := "Sac"
const NOTEBOOK_BUTTON := "Carnet (%d/%d)"
const NOTEBOOK_SHORT := "Carnet %d/%d"
const BAG_AT_VILLAGE := "Sac : au village"
const TALENTS_AT_VILLAGE := "Talents : au village"
const TALENTS_BUTTON := "Talents"
const TALENTS_BUTTON_POINTS := "Talents (%s)"

## Pause.
const PAUSE_TITLE := "Pause"
const RESUME := "Reprendre"
const SOUND_ON := "Son : activé"
const SOUND_OFF := "Son : coupé"
const DAMAGE_NUMBERS_ON := "Chiffres de dégâts : oui"
const DAMAGE_NUMBERS_OFF := "Chiffres de dégâts : non"
const VIBRATION_ON := "Vibrations : oui"
const VIBRATION_OFF := "Vibrations : non"
const DEBUG_ON := "Infos techniques : oui"
const DEBUG_OFF := "Infos techniques : non"
const QUIT := "Rentrer au village"
const QUIT_TO_TITLE := "Écran titre"
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
const SUMMARY_LEVEL := "Niveau atteint"
const SUMMARY_TIME := "Temps"
const AGAIN := "Repartir"
const NEXT_NIGHT := "Nuit suivante"
const ENDLESS_NIGHT := "Nuit sans fin"
const HOME := "Accueil"
const BACK := "Retour"

## Carnet.
const NOTEBOOK_TITLE := "Carnet"
const NOTEBOOK_SUB := "%d pages sur %d"
const PAGE_TITLE := "Page %d"
const PAGE_GONGS := "Les gongs de la nuit %d la gardent."
const PAGE_PERCH := "Tout en haut d'un perchoir, nuit %d."
const PAGE_EMPTY := "Page encore cachée."

## Sac.
const BAG_TITLE := "Sac"
const BAG_SUB := "%d/%d objets"
const BAG_EMPTY := "Chaque Grand Muet libéré offre un cadeau : il arrive au village avec son tambour."
const SLOT_EMPTY := "Vide"
const ITEM_NEW := "nouveau"
const ITEM_INFO := "%s · %s · niveau %d"
const ITEM_WORN := " · porté"
const ITEM_COMPARE := "Comparé à ton objet porté :"
const EQUIP := "Équiper"
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
	&"heart": "Chaque coup critique te soigne de 3 PV.",
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
	&"metro": "Vitesse des coups +%d %",
	&"drum": "+%d % de dégâts",
	&"roll": "Groove gagné +%d %",
	&"finale": "Ton 3e coup libère une onde de choc.",
	&"breath": "+%d PV max",
	&"sap": "+%d PV par Muet libéré",
	&"bark": "+%d % de résistance",
	&"second": "Une fois par sortie, relève-toi à 40 % PV.",
}

## Pluriels simples : « 1 tambour », « 3 tambours ».
const DRUM := "tambour"
const POINT := "point"
const SORTIE := "sortie"


## Textes de la nuit `night` (1 à 5, puis les nuits sans fin).
static func night_info(night: int) -> Dictionary:
	return NIGHTS[night - 1] if night >= 1 and night <= NIGHTS.size() else ENDLESS


static func night_name(night: int) -> String:
	return night_info(night)[&"title"]


## « 1 tambour », « 3 tambours ».
static func plural(count: int, word: String) -> String:
	return "%d %s%s" % [count, word, "s" if absi(count) > 1 else ""]


## Nom d'un objet : légendaire, ou emplacement et matière selon la rareté.
static func item_name(item: ItemData) -> String:
	if item.legendary != &"":
		return LEGENDARY_NAMES[item.legendary]
	var materials: Array = SLOT_MATERIALS[item.slot]
	return "%s %s" % [SLOT_NAMES[item.slot], materials[item.rarity]]


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
			value = tuning.talent_metro_speed * 100.0 * r
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


## Durée en minutes et secondes : « 4:07 ».
static func duration(seconds: float) -> String:
	var total: int = floori(seconds)
	return "%d:%02d" % [floori(seconds / 60.0), total % 60]


## Noms possibles d'une clairière de la forme `kind`. (Passer par get() : dans Godot 4.7,
## `dico[variable]` sur un dictionnaire typé de PackedStringArray renvoie un tableau faux.)
static func room_names(kind: StringName) -> PackedStringArray:
	return ROOM_NAMES.get(kind, ROOM_NAMES[&"clearing"])


## Choix `index` de la rencontre `id`, sa valeur de réglage à la place de %d.
static func encounter_choice(id: StringName, index: int, value: int) -> String:
	var choices: PackedStringArray = ENCOUNTER_CHOICES.get(id, PackedStringArray())
	return choices[index].replace("%d", str(value)) if index < choices.size() else ""


## Nom d'un élite : « Cornu cuirassé », « Brute vive »…
static func elite_name(species: StringName, affix: StringName) -> String:
	var name: String = SPECIES_NAMES.get(species, SPECIES_NAMES[&"hopper"])
	var pattern: String = ELITE_NAMES.get(affix, "%s")
	if species == &"brute" and affix == &"swift":
		return "Brute vive"
	return pattern % name


## « 1 plume d'or », « 3 plumes d'or ».
static func feathers(count: int) -> String:
	return (FEATHER_MANY if absi(count) > 1 else FEATHER_ONE) % count


## Nom du don `id`.
static func boon_name(id: StringName) -> String:
	return BOON_NAMES.get(id, String(id))


## Effet du don `id` au rang `level` (valeur totale à ce rang).
static func boon_text(id: StringName, level: int, tuning: TuningData) -> String:
	var value: float = Boons.value(id, level, tuning)
	var amount: int = roundi(value) if BOON_FLAT.has(id) else roundi(value * 100.0)
	return BOON_TEXTS[id].replace("%d", str(amount))


## Nombre de mots d'un texte (la ponctuation isolée ne compte pas).
static func word_count(text: String) -> int:
	var count: int = 0
	for word: String in text.split(" ", false):
		if word.strip_edges().lstrip("!?…:;,.") != "":
			count += 1
	return count


static func _effect_text(effect: StringName, amount: int) -> String:
	return EFFECT_LINES[effect].replace("%d", str(amount))
