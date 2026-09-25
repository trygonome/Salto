class_name EffectsMath
## Formes des effets du prototype, sans état : grossissement d'un mot qui apparaît, étoile des
## étincelles.

## Branches de l'étoile d'étincelle, et longueur des pointes (part du rayon) : longues, moyennes,
## courtes, en alternance.
const STAR_POINTS := 16
const STAR_LONG := 31.0 / 32.0
const STAR_MID := 21.0 / 32.0
const STAR_SHORT := 9.0 / 32.0


## Taille d'un mot à la fraction `t` de sa vie : il jaillit, dépasse un peu, puis se pose.
static func pop(t: float, tuning: TuningData) -> float:
	if t < tuning.fx_word_pop_time:
		return tuning.fx_word_pop_start + t / tuning.fx_word_pop_time * (tuning.fx_word_pop_peak - tuning.fx_word_pop_start)
	return tuning.fx_word_pop_peak - minf(tuning.fx_word_pop_peak - 1.0, t - tuning.fx_word_pop_time)


## Rayon de l'étoile (part du rayon total) dans la direction `angle` (rad).
static func star_reach(angle: float) -> float:
	var step: float = TAU / STAR_POINTS
	var i: int = floori(angle / step) % STAR_POINTS
	var f: float = fposmod(angle, step) / step
	return lerpf(_point(i), _point((i + 1) % STAR_POINTS), f)


static func _point(i: int) -> float:
	if i % 2 == 1:
		return STAR_SHORT
	return STAR_MID if i % 4 != 0 else STAR_LONG
