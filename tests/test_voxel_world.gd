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
	assert_eq(Smoothing.ease_in_out(0.0), 0.0)
	assert_eq(Smoothing.ease_in_out(0.5), 0.5)
	assert_eq(Smoothing.ease_in_out(1.0), 1.0)
	assert_lt(Smoothing.ease_in_out(0.1), 0.1, "démarre lentement")
	assert_gt(Smoothing.ease_in_out(0.9), 0.9, "arrive lentement")


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


func test_un_assemblage_articule_tient_en_un_seul_maillage() -> void:
	var rig := VoxelRig.new()
	var cells := PackedFloat32Array()
	VoxelMesh.add(cells, 0.0, 0.0, 0.0, Vector3(2.5, 0.5, 0.5))
	VoxelMesh.add(cells, 1.0, 0.0, 0.0, Vector3(2.5, 0.5, 0.5))
	var arm := PackedFloat32Array()
	VoxelMesh.add(arm, 0.0, -1.0, 0.0, Vector3(2.1, 0.5, 0.5))
	rig.add_part(&"body", &"", Vector3.ZERO, cells)
	rig.add_part(&"arm", &"body", Vector3(0.0, 2.0, 0.0), arm)
	rig.build(null)
	add_child_autofree(rig)
	assert_eq(rig.skeleton.get_bone_count(), 2)
	assert_eq(rig.skeleton.get_bone_parent(rig.bone(&"arm")), rig.bone(&"body"))
	var mesh: ArrayMesh = rig.mesh_instance.mesh as ArrayMesh
	assert_eq(mesh.get_surface_count(), 1, "un seul appel de dessin")
	var arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	assert_eq(vertices.size(), 3 * 24, "trois cubes de 24 sommets")
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	assert_eq(bones[bones.size() - 4], rig.bone(&"arm"), "le dernier cube suit le bras")
	assert_eq(rig.mesh_instance.get_node_or_null(rig.mesh_instance.skeleton), rig.skeleton, "le maillage suit le squelette")


func test_chaque_muet_a_sa_forme() -> void:
	var hopper: Dictionary = MuetShapes.build(&"hop", false, false, 0.0)
	var boss: Dictionary = MuetShapes.build(&"hop", true, false, 0.0)
	var king: Dictionary = MuetShapes.build(&"hop", true, true, 0.0)
	assert_gt((boss[&"body"] as PackedFloat32Array).size(), (hopper[&"body"] as PackedFloat32Array).size(), "le Grand Muet est plus gros")
	assert_gt((king[&"body"] as PackedFloat32Array).size(), (boss[&"body"] as PackedFloat32Array).size(), "le Roi Muet porte une flèche")
	assert_false((hopper[&"eyes"] as PackedFloat32Array).is_empty())
	assert_true(MuetShapes.build(&"fly", false, false, 0.0).has(&"wing_left"), "le volant a des ailes")
	assert_true(MuetShapes.build(&"shield", false, false, 0.0).has(&"shield"), "le porte-bouclier a son bouclier")
	assert_false(hopper.has(&"shield"))
	var tip_a: PackedFloat32Array = MuetShapes.build(&"hop", false, false, 0.1)[&"body"]
	var tip_b: PackedFloat32Array = MuetShapes.build(&"hop", false, false, 0.6)[&"body"]
	assert_ne(tip_a, tip_b, "bouts d'antennes de couleurs différentes")


func test_la_taille_des_muets_suit_le_prototype() -> void:
	var height: float = MuetShapes.height(MuetShapes.RADIUS[&"hop"]) * tuning.hopper_scale * tuning.voxel_unit
	assert_almost_eq(height, 0.78, 0.01, "sautillant : 3 u")
	var boss: float = MuetShapes.height(MuetShapes.BOSS_RADIUS) * tuning.boss_scale * tuning.voxel_unit
	assert_almost_eq(boss, 1.72, 0.01, "Grand Muet : 6,6 u")


func test_un_mot_jaillit_puis_se_pose() -> void:
	assert_eq(EffectsMath.pop(0.0, tuning), tuning.fx_word_pop_start)
	assert_almost_eq(EffectsMath.pop(tuning.fx_word_pop_time, tuning), tuning.fx_word_pop_peak, 0.0001)
	assert_almost_eq(EffectsMath.pop(1.0, tuning), 1.0, 0.0001)


func test_l_etincelle_est_une_etoile() -> void:
	var long: float = EffectsMath.star_reach(0.0)
	var short: float = EffectsMath.star_reach(TAU / EffectsMath.STAR_POINTS)
	assert_gt(long, short, "pointes longues et courtes")
	assert_almost_eq(EffectsMath.star_reach(TAU - 0.0001), long, 0.01, "l'étoile se referme")


func test_les_mots_font_au_plus_cinq_mots() -> void:
	for text: String in GameTexts.WORDS:
		assert_lte(GameTexts.word_count(text), 5, text)


func test_la_jungle_revit_tambour_apres_tambour() -> void:
	var tuning: TuningData = Tuning.data
	assert_eq(WorldMood.life_target(0, 3, false), 0.0, "nuit muette : couleurs éteintes et immobiles")
	assert_gt(WorldMood.life_target(1, 3, false), 0.0)
	assert_gt(WorldMood.life_target(2, 3, false), WorldMood.life_target(1, 3, false))
	assert_eq(WorldMood.life_target(3, 3, true), 1.0, "nuit gagnée : toutes les couleurs dansent")
	var levels: PackedFloat32Array = tuning.world_saturation_levels
	for i: int in levels.size() - 1:
		assert_gt(levels[i + 1] - levels[i], 0.15, "chaque tambour se voit")
	assert_lt(levels[0], 0.5, "le monde commence désaturé (docs/GDD.md, palette)")
