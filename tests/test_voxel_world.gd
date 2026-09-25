extends GutTest
## Logique du monde voxel : couleurs qui reviennent à chaque tambour, conversion des teintes,
## entrain des villageois, forme des personnages et des ombres.

var tuning: TuningData = Tuning.data


func test_le_monde_reprend_ses_couleurs_a_chaque_tambour() -> void:
	var previous: float = 0.0
	for drums: int in tuning.night_drums_required + 1:
		var saturation: float = WorldMood.saturation_target(drums, false, tuning)
		assert_gt(saturation, previous, "plus de couleurs avec %d tambours" % drums)
		previous = saturation
	assert_eq(WorldMood.saturation_target(10, false, tuning), tuning.world_saturation_levels[-1], "pas au-delà du dernier palier")
	assert_gt(WorldMood.saturation_target(0, true, tuning), previous, "la nuit gagnée éclate de couleurs")


func test_les_teintes_se_convertissent_comme_dans_le_prototype() -> void:
	assert_eq(WorldMood.hsl(0.0, 1.0, 0.5), Color(1.0, 0.0, 0.0))
	assert_eq(WorldMood.hsl(1.0 / 3.0, 1.0, 0.5), Color(0.0, 1.0, 0.0))
	assert_eq(WorldMood.hsl(0.5, 0.0, 0.3), Color(0.3, 0.3, 0.3), "sans saturation : un gris")
	assert_eq(WorldMood.hsl(1.25, 1.0, 0.5), WorldMood.hsl(0.25, 1.0, 0.5), "la teinte fait le tour")


func test_le_village_danse_plus_fort_a_chaque_tambour() -> void:
	var previous: float = 0.0
	for drums: int in tuning.night_drums_required + 1:
		var amount: float = Villager.dance_amount(drums, false, tuning)
		assert_gt(amount, previous)
		previous = amount
	assert_eq(Villager.dance_amount(0, true, tuning), tuning.villager_dance_won)


func test_le_salto_part_et_arrive_en_douceur() -> void:
	assert_eq(Villager.ease_in_out(0.0), 0.0)
	assert_eq(Villager.ease_in_out(0.5), 0.5)
	assert_eq(Villager.ease_in_out(1.0), 1.0)
	assert_lt(Villager.ease_in_out(0.1), 0.1, "démarre lentement")
	assert_gt(Villager.ease_in_out(0.9), 0.9, "arrive lentement")


func test_les_villageois_ont_la_taille_du_heros() -> void:
	# Du bas des pieds au haut de la tête, en voxels (makeChar du prototype) : 7 u pour 1,8 m.
	var hip: float = VoxelCharacter.HIP_Y
	var feet: float = hip - 3.0 - 3.0 - 1.0
	var head_top: float = hip + 2.0 + 5.6 + 6.0
	var height: float = (head_top - feet) * tuning.character_voxel * tuning.voxel_unit
	assert_almost_eq(height, 1.8, 0.05)


func test_chaque_villageois_a_sa_tenue() -> void:
	var parts: Dictionary = VoxelStyles.character_parts(VoxelStyles.dancer(0))
	for key: StringName in [&"pelvis", &"torso", &"head", &"eyes", &"thigh", &"shin", &"foot", &"upper", &"fore"]:
		assert_false((parts[key] as PackedFloat32Array).is_empty(), "partie %s" % key)
	assert_ne(VoxelStyles.dancer(0)[&"cloth"], VoxelStyles.dancer(1)[&"cloth"])
	assert_true(VoxelStyles.dancer(1).has(&"band"), "un bandeau sur deux")
	assert_false(VoxelStyles.dancer(0).has(&"band"))
	var chief: Dictionary = VoxelStyles.character_parts(VoxelStyles.chief())
	assert_gt((chief[&"head"] as PackedFloat32Array).size(), (parts[&"head"] as PackedFloat32Array).size(), "les plumes du Chef")


func test_l_ombre_est_un_disque_plein() -> void:
	var segments: int = tuning.shadow_segments
	var disc: ArrayMesh = BlobShadow.disc(segments)
	var vertices: PackedVector3Array = disc.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	assert_eq(vertices.size(), segments * 3)
	for v: Vector3 in vertices:
		assert_eq(v.y, 0.0)
		assert_lt(v.length(), 1.0001)
