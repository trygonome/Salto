extends GutTest
## Langage visuel 3.2 : chaque don, objet, instrument, récompense, case, pacte et région a son icône
## voxel (dessin 7 × 7) ; les familles ont leur couleur.

const OTHERS: Array[StringName] = [
	&"boon", &"heal", &"feathers", &"encounter", &"rest", &"treasure", &"secret", &"boss", &"depart",
	&"anklets", &"mask", &"talisman", &"altar", &"drum_hut", &"spring", &"stage",
	&"thick_skin", &"hard_hits", &"fragile", &"stingy", &"undergrowth", &"sunken", &"canopy",
]


func test_chaque_dessin_fait_sept_sur_sept() -> void:
	for id: StringName in VoxelIcons.ART:
		var art: PackedStringArray = VoxelIcons.ART.get(id)
		assert_eq(art.size(), 7, String(id))
		for line: String in art:
			assert_eq(line.length(), 7, "%s : %s" % [id, line])
			for ch: String in line:
				assert_true(ch == "." or ch == "F" or ch == "f" or VoxelIcons.PALETTE.has(ch), "%s : lettre %s" % [id, ch])


func test_tout_a_son_icone() -> void:
	var tuning: TuningData = Tuning.data
	for id: StringName in Boons.IDS + Boons.DUOS.keys():
		assert_true(VoxelIcons.ART.has(id), "don %s" % id)
		assert_gt(VoxelIcons.boon(id).size(), 0)
	for id: StringName in OTHERS:
		assert_true(VoxelIcons.ART.has(id), String(id))
	for weapon: WeaponData in tuning.weapons:
		assert_gt(HeroVisual.instrument_cells(weapon).size(), 0)
	for family: StringName in Boons.FAMILIES:
		assert_true(VoxelIcons.FAMILY_COLORS.has(family))
		assert_ne(VoxelIcons.family_color(family), VoxelIcons.family_color(family, true), "une teinte claire, une sombre")
	assert_ne(VoxelIcons.family_color(Boons.FEU), VoxelIcons.family_color(Boons.EAU))
