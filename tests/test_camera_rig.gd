extends GutTest
## Cadrage de la caméra selon l'orientation de l'écran.

const PORTRAIT := Vector2(1080.0, 2400.0)
const LANDSCAPE := Vector2(2400.0, 1080.0)

var tuning: TuningData


func before_all() -> void:
	tuning = load("res://data/tuning.tres") as TuningData


func test_detecte_l_orientation() -> void:
	assert_true(CameraRig.is_portrait(PORTRAIT))
	assert_false(CameraRig.is_portrait(LANDSCAPE))


func test_portrait_utilise_les_reglages_portrait() -> void:
	assert_eq(CameraRig.distance_for(PORTRAIT, tuning), tuning.camera_distance_portrait)
	assert_eq(CameraRig.fov_for(PORTRAIT, tuning), tuning.camera_fov_portrait_deg)


func test_paysage_utilise_les_reglages_paysage() -> void:
	assert_eq(CameraRig.distance_for(LANDSCAPE, tuning), tuning.camera_distance_landscape)
	assert_eq(CameraRig.fov_for(LANDSCAPE, tuning), tuning.camera_fov_landscape_deg)


func test_la_camera_est_a_la_bonne_distance() -> void:
	var offset: Vector3 = CameraRig.offset_for(tuning.camera_distance_portrait, tuning.camera_tilt_deg)
	assert_almost_eq(offset.length(), tuning.camera_distance_portrait, 0.001)


func test_la_camera_regarde_vers_le_bas_avec_l_inclinaison_voulue() -> void:
	var offset: Vector3 = CameraRig.offset_for(tuning.camera_distance_portrait, tuning.camera_tilt_deg)
	var pitch_deg: float = rad_to_deg(atan2(offset.y, offset.z))
	assert_almost_eq(pitch_deg, tuning.camera_tilt_deg, 0.001)
	assert_eq(offset.x, 0.0, "la caméra reste dans l'axe, derrière le point visé")


func test_anticipation_pleine_a_vitesse_de_course() -> void:
	var running := Vector3.FORWARD * tuning.run_speed
	assert_almost_eq(CameraRig.lookahead_for(running, tuning), Vector3.FORWARD * tuning.camera_lookahead, Vector3.ONE * 0.0001)


func test_anticipation_proportionnelle_en_dessous() -> void:
	var walking := Vector3.RIGHT * tuning.run_speed / 2.0
	assert_almost_eq(CameraRig.lookahead_for(walking, tuning).length(), tuning.camera_lookahead / 2.0, 0.0001)


func test_anticipation_plafonnee_pendant_une_roulade_ou_un_elan() -> void:
	var dashing := Vector3.LEFT * tuning.air_dash_speed
	assert_almost_eq(CameraRig.lookahead_for(dashing, tuning).length(), tuning.camera_lookahead, 0.0001)
