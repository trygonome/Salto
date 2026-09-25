class_name RhythmMath
## Règles du rythme sans état : durée d'un temps, décalage d'un appui par rapport au temps
## le plus proche, jugement Parfait / Bien, bonus de dégâts et de groove.

enum Judgement { MISS, GOOD, PERFECT }

## Secondes par minute, pour convertir le tempo.
const SECONDS_PER_MINUTE := 60.0


## Durée d'un temps (s).
static func beat_length(tuning: TuningData) -> float:
	return SECONDS_PER_MINUTE / tuning.rhythm_bpm


## Décalage (s) entre `time` et le temps le plus proche : négatif en avance, positif en retard.
static func beat_offset(time: float, beat: float) -> float:
	return time - roundf(time / beat) * beat


## Avancée dans le temps en cours, de 0 (sur le temps) à 1 (juste avant le suivant).
static func beat_phase(time: float, beat: float) -> float:
	return fposmod(time, beat) / beat


## Jugement d'un appui décalé de `offset` secondes : les fenêtres tolèrent plus le retard
## que l'avance (le tactile arrive toujours un peu tard).
static func judge(offset: float, tuning: TuningData) -> Judgement:
	if offset >= -tuning.perfect_early and offset <= tuning.perfect_late:
		return Judgement.PERFECT
	if offset >= -tuning.good_early and offset <= tuning.good_late:
		return Judgement.GOOD
	return Judgement.MISS


## Multiplicateur de dégâts d'un coup jugé `judgement`.
static func damage_multiplier(judgement: Judgement, tuning: TuningData) -> float:
	match judgement:
		Judgement.PERFECT:
			return tuning.perfect_multiplier
		Judgement.GOOD:
			return tuning.good_multiplier
	return 1.0


## Groove gagné par un coup jugé `judgement` qui touche.
static func groove_gain(judgement: Judgement, tuning: TuningData) -> float:
	match judgement:
		Judgement.PERFECT:
			return tuning.groove_perfect
		Judgement.GOOD:
			return tuning.groove_good
	return 0.0
