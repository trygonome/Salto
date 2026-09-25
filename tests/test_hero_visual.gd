extends GutTest
## Héros voxel : taille, poses calculées de la course et du repos (comme dans le prototype).

var tuning: TuningData = Tuning.data


func test_le_heros_voxel_mesure_la_taille_du_heros() -> void:
	var natural: float = VoxelCharacter.HEIGHT * tuning.character_voxel * tuning.voxel_unit
	assert_almost_eq(natural, tuning.hero_height, 0.05, "le personnage du prototype mesure déjà 1,8 m")


func test_en_courant_bras_et_jambes_se_balancent_en_opposition() -> void:
	var stride: Dictionary = HeroAnimator.run_pose(PI / 2.0, 1.0)
	assert_almost_eq(float(stride[&"lLx"]), -float(stride[&"lRx"]), 0.0001, "une jambe en avant, l'autre en arrière")
	assert_lt(float(stride[&"lLx"]) * float(stride[&"sLx"]), 0.0, "le bras gauche part à l'opposé de la jambe gauche")
	var still: Dictionary = HeroAnimator.run_pose(PI / 2.0, 0.0)
	assert_eq(float(still[&"lLx"]), 0.0, "sans vitesse, pas de foulée")


func test_au_repos_il_se_balance_sur_le_temps() -> void:
	var on_beat: Dictionary = HeroAnimator.idle_pose(1.0)
	var between: Dictionary = HeroAnimator.idle_pose(0.0)
	assert_lt(float(on_beat[&"hy"]), float(between[&"hy"]), "il fléchit sur le temps")
	assert_gt(float(on_beat[&"kL"]), float(between[&"kL"]))


func test_le_coup_de_pied_de_la_meia_lua_part_de_la_jambe_gauche() -> void:
	assert_true(HeroAnimator.LEFT_LEG_ATTACKS.has(&"meia_lua"))
	assert_false(HeroAnimator.LEFT_LEG_ATTACKS.has(&"martelo"))
