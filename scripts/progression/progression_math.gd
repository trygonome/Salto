class_name ProgressionMath
## Règles de progression sans état, comme dans le prototype : expérience demandée par niveau,
## expérience d'un Muet libéré, score et plumes d'une sortie.


## Expérience à gagner au niveau `level` pour passer au suivant.
static func xp_needed(level: int, tuning: TuningData) -> float:
	var n: float = level - 1
	return tuning.xp_base + tuning.xp_per_level * n + tuning.xp_per_level_squared * n * n


## Ajoute `amount` d'expérience au niveau `level` (avec `xp` déjà gagnée) : renvoie le nouveau
## niveau, l'expérience restante et le nombre de niveaux gagnés.
static func add_xp(level: int, xp: float, amount: float, tuning: TuningData) -> Dictionary:
	var gained: int = 0
	xp += amount
	while xp >= xp_needed(level, tuning):
		xp -= xp_needed(level, tuning)
		level += 1
		gained += 1
	return {&"level": level, &"xp": xp, &"gained": gained}


## Expérience d'un Muet de l'espèce `species`, gardien du sanctuaire de rang `tier` (Roi Muet :
## `king`).
static func muet_xp(species: StringName, tier: int, king: bool, tuning: TuningData) -> float:
	if species == &"boss":
		var xp: float = tuning.xp_boss + tuning.xp_boss_per_tier * tier
		return roundf(xp * (tuning.king_health_factor if king else 1.0))
	return float(tuning.xp_per_species.get(species, 0.0)) + tuning.xp_per_tier * tier


## Multiplicateur du score et des plumes à la nuit `night` (les nuits suivantes rapportent plus).
static func night_multiplier(per_night: float, night: int) -> float:
	return 1.0 + per_night * maxi(night - 1, 0)
