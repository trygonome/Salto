class_name VoxelIcons
## Icônes en voxels (version 3.2) : chaque don, objet, instrument, récompense, case du village, pacte
## et région a sa petite figure, dessinée en pixel art 7 × 7 puis extrudée en cubes (deux d'épaisseur,
## le cœur en relief). La lettre « F » prend la couleur de la famille du don (Feu rouge, Eau bleue,
## Sève verte, Vent jaune) ; « f », sa teinte claire. Les couleurs sont codées comme celles du monde
## (mode 2 : fixes ; voir VoxelMesh).

## Couleur de chaque famille (codée) et sa version pour l'interface.
const FAMILY_COLORS: Dictionary[StringName, Vector3] = {
	&"feu": Vector3(2.0, 0.85, 0.55), &"eau": Vector3(2.58, 0.8, 0.55),
	&"seve": Vector3(2.33, 0.75, 0.45), &"vent": Vector3(2.13, 0.95, 0.55),
}
const DUO_COLOR := Vector3(2.12, 0.9, 0.6)
## Palette des lettres (couleurs codées) ; « . » : vide.
const PALETTE: Dictionary[String, Vector3] = {
	"w": Vector3(2.0, 0.0, 0.95), "k": Vector3(2.75, 0.3, 0.14), "y": Vector3(2.13, 0.95, 0.58),
	"o": Vector3(2.07, 0.95, 0.55), "r": Vector3(2.0, 0.85, 0.5), "b": Vector3(2.58, 0.8, 0.55),
	"c": Vector3(2.5, 0.8, 0.65), "g": Vector3(2.33, 0.75, 0.45), "l": Vector3(2.28, 0.7, 0.62),
	"p": Vector3(2.93, 0.8, 0.65), "v": Vector3(2.78, 0.6, 0.55), "n": Vector3(2.07, 0.5, 0.35),
	"s": Vector3(2.6, 0.08, 0.6), "m": Vector3(2.07, 0.45, 0.22),
}
## Dessins 7 × 7 (de haut en bas).
const ART: Dictionary[StringName, PackedStringArray] = {
	# Feu.
	&"ember": [".......", "...F...", "..FfF..", ".FfyfF.", ".FyyyF.", "..FFF..", "nnnnn.."],
	&"meteor": ["F......", ".F.....", "..f.s..", "...sss.", "..sssss", "...sss.", "....s.."],
	&"fury": [".......", ".FFFF..", "FfffFF.", "FfffFF.", "FFFFFF.", ".FFFF..", "..FF..."],
	&"blaze": ["...F...", "..FF.F.", ".FfFFF.", "FFfyfFF", "FfyyyfF", ".FyyyF.", "..FFF.."],
	&"cinders": ["F.....F", "..f....", ".....F.", ".F.y...", "....f..", "F.....F", "..F.F.."],
	&"forge": [".sss...", ".sssF..", "..n.F..", "..n....", "..n....", "kkkkkk.", ".kkkk.."],
	&"prism": ["...F...", "..FfF..", ".FfwfF.", "FfwwwfF", ".FfwfF.", "..FfF..", "...F..."],
	# Eau.
	&"bark": [".FFFFF.", "FfffffF", "FfFFFfF", "FfFwFfF", ".FfFfF.", "..FfF..", "...F..."],
	&"counterpoint": ["....F..", "...FF..", "FFFFFF.", "...FF.F", "....F.F", "F.....F", ".FFFFF."],
	&"dazzle": ["F..F..F", ".F.F.F.", "..fwf..", "FFwywFF", "..fwf..", ".F.F.F.", "F..F..F"],
	&"mist": [".......", "..ff...", ".ffFff.", "fFFFFFf", ".......", ".ffffF.", "fFFFF.."],
	&"tide": [".......", "..FF...", ".F..F..", "F.FF.F.", ".FffF.F", "FfffffF", "FFFFFFF"],
	&"frost": ["...F...", ".F.F.F.", "..fFf..", "FFFwFFF", "..fFf..", ".F.F.F.", "...F..."],
	# Sève.
	&"heart": [".......", ".FF.FF.", "FffFffF", "FfffffF", ".FfffF.", "..FfF..", "...F..."],
	&"thorns": ["F..F..F", ".FFFFF.", ".FfffF.", "FFfnfFF", ".FfffF.", ".FFFFF.", "F..F..F"],
	&"sap": ["...F...", "...F...", "..FfF..", ".FfwfF.", ".FfffF.", ".FFfFF.", "..FFF.."],
	&"regrowth": [".F...F.", "FfF.FfF", ".FF.FF.", "...F...", "...F...", ".nnnnn.", "nnnnnnn"],
	&"anchor": ["...n...", "..nnn..", "...n...", "F..n..F", "FF.n.FF", ".FFnFF.", "..FFF.."],
	# Vent.
	&"swift": [".....FF", "...FFf.", "..FfF..", ".FfF...", "FfF....", "FF.....", "F......"],
	&"tempo": [".FFFFF.", ".F...F.", "..FyF..", "...y...", "..FyF..", ".FyyyF.", ".FFFFF."],
	&"halo": [".......", "..FFF..", ".F...F.", "F.....F", ".F...F.", "..FFF..", "......."],
	&"splash": ["F..F..F", ".......", ".F.F.F.", "..fFf..", ".FfffF.", "FFFFFFF", "......."],
	&"rainbow": [".......", "..rrr..", ".roooo.", "royyyor", "roy.yor", "roy.yor", "......."],
	&"echo": ["F.....F", ".F...F.", "..rrr..", ".ryyyr.", ".rrrrr.", ".rnnnr.", "..nnn.."],
	&"hawk": [".......", "..FFF..", ".FfffF.", "FfkwkfF", ".FfffF.", "..FFF..", "......."],
	# Dons doubles.
	&"wildfire": ["y..r..y", "...r...", "..rrr..", "yrroyry", ".roooy.", "..ryr..", "y.....y"],
	&"geyser": ["...c...", "..crc..", "..ccc..", "...c...", "..bcb..", ".bbbbb.", "bbbbbbb"],
	&"sacred_grove": [".ggg...", "gglgg..", "ggggg..", ".gnggg.", "..nglgg", "..n.gg.", ".nnn.n."],
	&"bloom": ["..p.p..", ".ppppp.", "pppyppp", ".ppppp.", "..p.p..", "...g...", "..ggg.."],
	# Récompenses et passages.
	&"boon": ["...y...", "...y...", "yyyyyyy", ".yyyyy.", "..yyy..", ".yy.yy.", "y.....y"],
	&"heal": [".......", ".rr.rr.", "rrrrrrr", "rrwrrrr", ".rrrrr.", "..rrr..", "...r..."],
	&"feathers": [".....yy", "....yyy", "...yyy.", "..yyy..", ".yyy...", ".y.....", "y......"],
	&"encounter": [".ccccc.", "ccccccc", "cckckcc", "ccccccc", ".ccccc.", "..cc...", ".c....."],
	&"rest": ["...o...", "..oyo..", ".oyyyo.", "..oyo..", "n.....n", ".nn.nn.", "..nnn.."],
	&"treasure": [".nnnnn.", "nyyyyyn", "nnnnnnn", "nyyyyyn", "nnnynnn", "nnnnnnn", "......."],
	&"secret": ["..vvv..", ".v...v.", ".v...v.", "..vvv..", "...v...", "...vv..", "...v..."],
	&"boss": [".......", "y..y..y", "yy.y.yy", "yyyyyyy", "yrryrry", "yyyyyyy", "......."],
	&"depart": ["...y...", "..yyy..", "rrrrrrr", "ryyyyyr", "rrrrrrr", "rnnnnnr", ".rrrrr."],
	# Objets (par emplacement).
	&"anklets": [".......", "..nnn..", ".n...n.", "n.....n", "yn...ny", ".yn.ny.", "..yyy.."],
	&"mask": [".nnnnn.", "nyyyyyn", "nykykyn", "nyyyyyn", "nyrrryn", ".nyyyn.", "..nnn.."],
	&"talisman": ["..n.n..", "...n...", "..vvv..", ".vvwvv.", ".vvvvv.", "..vvv..", "...v..."],
	# Cases du village, pactes, régions.
	&"altar": ["...v...", "..vwv..", "...v...", ".sssss.", ".sssss.", "sssssss", "sssssss"],
	&"drum_hut": ["...y...", "..yyy..", ".yyyyy.", "yyyyyyy", ".nn.nn.", ".nn.nn.", ".nnnnn."],
	&"spring": [".......", "...c...", "..ccc..", "...c...", "s.....s", "sbbbbbs", ".sssss."],
	&"stage": ["n.....n", "nrryggn", "n.....n", "n.....n", "nnnnnnn", "nnnnnnn", "n.....n"],
	&"thick_skin": [".sssss.", "sskssks", "sssssss", "ssksksk", "sssssss", ".sssss.", "......."],
	&"hard_hits": [".......", ".rrrr..", "rrrrrr.", "rrrrrr.", "rrrrrr.", ".rrrr..", "rr..rr."],
	&"fragile": [".......", ".rr.rr.", "rrr.rrr", "rr.rrrr", ".rr.rr.", "..r.r..", "...r..."],
	&"stingy": ["...s...", "..sss..", ".s.s.s.", "...s...", "...s...", "..sss..", "......."],
	&"undergrowth": ["...g...", "..ggg..", ".ggggg.", "ggggggg", "...n...", ".g.n.g.", "ggggggg"],
	&"sunken": ["s.s.s..", "sssss..", ".s.s...", ".s.s...", "bbbbbbb", "bcbbcbb", "bbbbbbb"],
	&"canopy": ["..ggg..", ".glglg.", "ggggggg", "...n...", "nnnnnnn", "...n...", "..n.n.."],
}
## Épaisseur (en cubes) et relief des lettres claires (plus en avant).
const DEPTH := 2
const RELIEF := 0.4


## Cubes de l'icône `id` (centrée sur l'origine, une case par cube) ; `family` : la famille du don
## (vide : couleurs de la palette). Un « ? » gris si l'icône n'existe pas.
static func cells(id: StringName, family: StringName = &"") -> PackedFloat32Array:
	var art: PackedStringArray = ART.get(id, PackedStringArray(["..sss..", ".s...s.", "....s..", "...s...", "...s...", ".......", "...s..."]))
	var main: Vector3 = FAMILY_COLORS.get(family, DUO_COLOR if Boons.DUOS.has(id) else PALETTE["s"])
	var light: Vector3 = Vector3(main.x + 0.03, minf(1.0, main.y * 1.05), minf(0.8, main.z + 0.15))
	var result := PackedFloat32Array()
	var rows: int = art.size()
	for row: int in rows:
		var line: String = art[row]
		for col: int in line.length():
			var ch: String = line[col]
			if ch == ".":
				continue
			var color: Vector3 = main if ch == "F" else (light if ch == "f" else PALETTE.get(ch, main))
			var x: float = col - (line.length() - 1) / 2.0
			var y: float = (rows - 1) / 2.0 - row
			var front: float = RELIEF if ch == "f" or ch == "w" or ch == "y" else 0.0
			for z: int in DEPTH:
				VoxelMesh.add(result, x, y, z - (DEPTH - 1) / 2.0 + (front if z == 0 else 0.0), color)
	return result


## Icône d'un don (la couleur de sa famille).
static func boon(id: StringName) -> PackedFloat32Array:
	return cells(id, Boons.family(id))


## Couleur d'interface d'une famille (claire, pour les cadres) et sombre (pour l'encre des effets).
static func family_color(family: StringName, dark: bool = false) -> Color:
	var coded: Vector3 = FAMILY_COLORS.get(family, DUO_COLOR)
	return WorldMood.hsl(coded.x - floorf(coded.x), coded.y * (0.9 if dark else 1.0), coded.z * (0.55 if dark else 1.0))
