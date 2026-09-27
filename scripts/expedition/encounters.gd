class_name Encounters
## Rencontres d'une expédition (clairières sans combat) : un personnage, ce qu'il dit, et deux
## choix. Les effets et leurs valeurs (Tuning.encounter_*) sont appliqués par l'expédition.
##  - spring (la source des anciens) : boire (tous les PV) ou y plonger la main (un don, contre des PV) ;
##  - merchant (le marchand muet) : un don contre des plumes d'or, ou un peu de soin ;
##  - drummer (le vieux tambourinaire) : son rythme (Métronome, un rang) ou son histoire (une page) ;
##  - wounded (le villageois blessé) : le soigner (un objet, contre des PV) ou lui montrer le chemin
##    (des plumes d'or).

const IDS: Array[StringName] = [&"spring", &"merchant", &"drummer", &"wounded"]


## Vrai si le choix `choice` de la rencontre `id` est possible (le marchand demande des plumes).
static func can_choose(id: StringName, choice: int, feathers: int, tuning: TuningData) -> bool:
	if id == &"merchant" and choice == 0:
		return feathers >= tuning.encounter_merchant_price
	return true
