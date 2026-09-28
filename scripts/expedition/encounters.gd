class_name Encounters
## Rencontres d'une expédition (clairières sans combat) : un personnage, ce qu'il dit, et deux
## choix. Les effets et leurs valeurs (Tuning.encounter_*) sont appliqués par l'expédition.
##  - spring (la source des anciens) : boire (tous les PV) ou y plonger la main (un don, contre des PV) ;
##  - merchant (le marchand muet) : un don contre des plumes d'or, ou un peu de soin ;
##  - drummer (le vieux tambourinaire) : son rythme (Métronome, un rang) ou son histoire (une page) ;
##  - wounded (le villageois blessé) : le soigner (un objet, contre des PV) ou lui montrer le chemin
##    (des plumes d'or) ;
##  - rest (le feu de camp, salle de repos, version 2.6) : te reposer (une part des PV) ou affûter
##    un don déjà pris (un rang de plus) ;
##  - weaver_lady (la Tisseuse de couleurs, version 2.8) : des plumes d'or contre un don rare, ou une
##    couleur qui remplit la jauge de groove ;
##  - echo_spirit (l'Écho solitaire) : lui répondre (un don double, s'il y en a un de possible) ou
##    l'écouter (Tempo, un rang) ;
##  - mute_tree (l'Arbre muet) : frapper ses racines (un don des racines, rare) ou dormir à son ombre
##    (une part des PV).

const IDS: Array[StringName] = [&"spring", &"merchant", &"drummer", &"wounded", &"weaver_lady", &"echo_spirit", &"mute_tree"]


## Vrai si le choix `choice` de la rencontre `id` est possible (le marchand et la Tisseuse demandent
## des plumes ; affûter demande un don `sharpenable`, pris et pas au rang maximal ; répondre à
## l'Écho, un don double possible : `duo_ready`).
static func can_choose(id: StringName, choice: int, feathers: int, tuning: TuningData, sharpenable: bool = true, duo_ready: bool = true) -> bool:
	if id == &"merchant" and choice == 0:
		return feathers >= tuning.encounter_merchant_price
	if id == &"weaver_lady" and choice == 0:
		return feathers >= tuning.encounter_weaver_price
	if id == &"echo_spirit" and choice == 0:
		return duo_ready
	if id == &"rest" and choice == 1:
		return sharpenable
	return true
