class_name Regions
## Régions d'une expédition (version 2.6) : chacune ses formes de clairière, ses couleurs (sol,
## feuillage, brume), ses vagues de prédilection, sa couche de musique et son gardien. On commence
## par le Sous-bois ; libérer le gardien d'une région ouvre la suivante.
##  - Sous-bois : clairières, bosquets, troncs couchés, champignonnières ; le Grand Muet.
##  - Ruines englouties : ruines, rivières à franchir sur des ponts, estrades ; eau partout ; le
##    Gardien des Ruines (il fait tomber des piliers).
##  - Canopée : plateformes et passerelles en hauteur, bosquets, champignonnières ; la Reine des
##    Cimes (elle vole et fond sur le héros).

const UNDERGROWTH := &"undergrowth"
const SUNKEN := &"sunken"
const CANOPY := &"canopy"
const IDS: Array[StringName] = [UNDERGROWTH, SUNKEN, CANOPY]

## Formes de clairière de chaque région (tirées de la graine de la clairière).
const KINDS: Dictionary[StringName, Array] = {
	UNDERGROWTH: [&"clearing", &"grove", &"logs", &"mushrooms"],
	SUNKEN: [&"ruins", &"flooded", &"flooded", &"clearing"],
	CANOPY: [&"heights", &"heights", &"grove", &"mushrooms"],
}
## Gardien de chaque région (variante du Grand Muet).
const GUARDIANS: Dictionary[StringName, StringName] = {UNDERGROWTH: &"ground", SUNKEN: &"ruins", CANOPY: &"canopy"}
## Modèles de vague préférés : un sur deux vient de cette liste quand elle en a un de possible.
const FAVORITE_WAVES: Dictionary[StringName, Array] = {
	UNDERGROWTH: [&"pack", &"cavalry", &"brutes"],
	SUNKEN: [&"wall", &"brambles", &"choir"],
	CANOPY: [&"swarm", &"ball", &"fanfare"],
}
## Couleurs : décalage de teinte du feuillage, teinte, saturation et luminosité de l'herbe et de la
## terre du sol, teinte de la brume.
const FOLIAGE_SHIFT: Dictionary[StringName, float] = {UNDERGROWTH: 0.0, SUNKEN: 0.09, CANOPY: -0.08}
const GRASS: Dictionary[StringName, Vector3] = {
	UNDERGROWTH: Vector3(0.31, 0.7, 0.27), SUNKEN: Vector3(0.42, 0.55, 0.25), CANOPY: Vector3(0.2, 0.72, 0.3),
}
const DIRT: Dictionary[StringName, Vector3] = {
	UNDERGROWTH: Vector3(0.08, 0.42, 0.3), SUNKEN: Vector3(0.52, 0.25, 0.26), CANOPY: Vector3(0.09, 0.5, 0.36),
}
const FOG_HUE: Dictionary[StringName, float] = {UNDERGROWTH: -1.0, SUNKEN: 0.48, CANOPY: 0.12}


## Région suivante (vide : c'était la dernière).
static func next(region: StringName) -> StringName:
	var i: int = IDS.find(region)
	return IDS[i + 1] if i >= 0 and i + 1 < IDS.size() else &""


## Régions ouvertes quand `won` sont déjà libérées : la première, et la suivante de chacune.
static func unlocked(won: Array[StringName]) -> Array[StringName]:
	var open: Array[StringName] = [IDS[0]]
	for region: StringName in IDS:
		if won.has(region):
			var following: StringName = next(region)
			if following != &"" and not open.has(following):
				open.append(following)
	return open
