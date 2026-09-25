class_name HeroStats
extends RefCounted
## Forces du héros, comme dans le prototype : ce que donnent son niveau, ses talents et les objets
## qu'il porte. Recalculées quand le profil change (niveau, talent, équipement, forge).

var max_health: float = 0.0
## Attaque de base (avant les multiplicateurs du coup, du rythme et du combo).
var attack: float = 0.0
var crit_chance: float = 0.0
## Part des dégâts reçus (1 : tous ; moins avec l'écorce et la résistance).
var damage_taken: float = 1.0
## Multiplicateurs de la course, de la roulade, de la vitesse des coups, du groove, des plongeons
## (dégâts et rayon), de l'expérience.
var speed: float = 1.0
var roll: float = 1.0
var attack_speed: float = 1.0
var groove: float = 1.0
var dive_damage: float = 1.0
var dive_radius: float = 1.0
var xp: float = 1.0
## PV rendus par Muet libéré.
var heal_per_muet: float = 0.0
## Sauts en l'air en plus, élans aériens par saut.
var extra_jumps: int = 0
var air_dashes: int = 1
## Fenêtre du coup Parfait (multiplicateur) et groove gagné par un Parfait (multiplicateur).
var perfect_window: float = 1.0
var perfect_groove: float = 1.0
## Le troisième coup de l'enchaînement libère une onde (Final fracassant, Pieds du Tonnerre).
var finale: bool = false
## Part des PV rendus quand il se relève une fois par sortie (0 : jamais).
var second_wind: float = 0.0
## Effets légendaires : l'esquive parfaite fait exploser le silence (Pas de l'Ombre), un coup
## parfait soigne (Cœur Battant), le Salto arc-en-ciel se charge plus vite et frappe plus fort
## (Tempête).
var shadow: bool = false
var perfect_heal: float = 0.0
var rainbow_damage: float = 1.0


## Forces pour le profil `profile`.
static func compute(profile: Profile, tuning: TuningData) -> HeroStats:
	var stats := HeroStats.new()
	var items: Array[ItemData] = profile.equipped_items()
	var gear: Dictionary[StringName, float] = ItemMath.total_effects(items)
	var legendaries: Array[StringName] = []
	for item: ItemData in items:
		if item.legendary != &"":
			legendaries.append(item.legendary)
	var n: int = profile.level - 1
	stats.max_health = roundf(tuning.hero_health_base + tuning.hero_health_per_level * n + tuning.talent_breath_health * profile.talent_rank(&"breath") + gear.get(&"health", 0.0))
	stats.attack = (tuning.hero_attack_base + tuning.hero_attack_per_level * n) * (1.0 + tuning.talent_drum_damage * profile.talent_rank(&"drum") + gear.get(&"damage", 0.0))
	stats.crit_chance = tuning.crit_chance + gear.get(&"crit", 0.0)
	stats.damage_taken = maxf(tuning.hero_min_damage_taken, 1.0 - tuning.talent_bark_resistance * profile.talent_rank(&"bark") - gear.get(&"resistance", 0.0))
	var feet: float = tuning.talent_feet_speed * profile.talent_rank(&"feet")
	stats.speed = 1.0 + feet + gear.get(&"speed", 0.0)
	stats.roll = 1.0 + feet
	stats.attack_speed = 1.0 + gear.get(&"attack_speed", 0.0)
	stats.groove = (1.0 + gear.get(&"groove", 0.0)) * (tuning.legendary_storm_groove if legendaries.has(&"storm") else 1.0)
	stats.dive_damage = 1.0 + tuning.talent_comet_damage * profile.talent_rank(&"comet") + gear.get(&"dive", 0.0)
	stats.dive_radius = 1.0 + tuning.talent_comet_radius * profile.talent_rank(&"comet")
	stats.xp = 1.0 + gear.get(&"xp", 0.0)
	stats.heal_per_muet = tuning.talent_sap_heal * profile.talent_rank(&"sap") + gear.get(&"heal_per_muet", 0.0)
	stats.extra_jumps = profile.talent_rank(&"triple")
	stats.air_dashes = 1 + profile.talent_rank(&"dash2")
	stats.perfect_window = 1.0 + tuning.talent_metro_window * profile.talent_rank(&"metro")
	stats.perfect_groove = 1.0 + tuning.talent_roll_groove * profile.talent_rank(&"roll")
	stats.finale = profile.talent_rank(&"finale") > 0 or legendaries.has(&"finale")
	if legendaries.has(&"phoenix"):
		stats.second_wind = tuning.legendary_phoenix_health
	elif profile.talent_rank(&"second") > 0:
		stats.second_wind = tuning.talent_second_health
	stats.shadow = legendaries.has(&"shadow")
	stats.perfect_heal = tuning.legendary_heart_heal if legendaries.has(&"heart") else 0.0
	stats.rainbow_damage = tuning.legendary_storm_damage if legendaries.has(&"storm") else 1.0
	return stats
