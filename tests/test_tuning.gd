extends GutTest
## Les réglages se chargent, sont tous renseignés et restent cohérents entre eux.

var tuning: TuningData


func before_all() -> void:
	tuning = load("res://data/tuning.tres") as TuningData


func test_la_ressource_se_charge() -> void:
	assert_not_null(tuning, "data/tuning.tres doit être une ressource TuningData")


func test_l_autoload_donne_les_memes_reglages() -> void:
	assert_eq(Tuning.data, tuning)


func test_aucun_reglage_n_est_oublie() -> void:
	# Le script n'a aucune valeur par défaut : un réglage absent du .tres vaut 0.
	for property: Dictionary in tuning.get_property_list():
		var is_script_value: bool = property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE
		var is_number: bool = property["type"] == TYPE_FLOAT or property["type"] == TYPE_INT
		if is_script_value and is_number:
			assert_ne(float(tuning.get(property["name"])), 0.0, "réglage manquant : %s" % property["name"])


func test_le_petit_saut_est_plus_court_que_le_grand() -> void:
	assert_gt(tuning.gravity_rise_released, tuning.gravity_rise_held)


func test_les_fractions_de_roulade_restent_dans_la_roulade() -> void:
	assert_lt(tuning.roll_invuln_start, tuning.roll_invuln_end)
	assert_lte(tuning.roll_invuln_end, 1.0)
	assert_lte(tuning.roll_chain_from, 1.0)
	assert_lt(tuning.roll_jump_from, 1.0)
	assert_lt(tuning.roll_tail_fraction, 1.0)


func test_l_invulnerabilite_de_l_elan_ne_depasse_pas_l_elan() -> void:
	assert_lte(tuning.air_dash_invuln, tuning.air_dash_duration)


func test_la_zone_morte_precede_la_pleine_vitesse() -> void:
	assert_lt(tuning.joystick_dead_zone, tuning.joystick_full_speed)
	assert_lte(tuning.joystick_full_speed, 1.0)


func test_les_fenetres_de_rythme_s_emboitent() -> void:
	assert_lt(tuning.perfect_early, tuning.good_early)
	assert_lt(tuning.perfect_late, tuning.good_late)
	assert_lt(tuning.good_early + tuning.good_late, RhythmMath.beat_length(tuning), "les fenêtres Bien de deux temps voisins ne se chevauchent pas")


func test_le_carillon_monte() -> void:
	var notes: PackedFloat32Array = tuning.chime_scale_semitones
	assert_gt(notes.size(), 1)
	for i: int in range(1, notes.size()):
		assert_gt(notes[i], notes[i - 1])
