extends GutTest
## Rythme : durée du temps, décalage d'un appui, jugement Parfait / Bien, bonus.

var tuning: TuningData = Tuning.data
var beat: float


func before_all() -> void:
	beat = RhythmMath.beat_length(tuning)


func test_un_temps_a_104_bpm() -> void:
	assert_almost_eq(beat, 60.0 / 104.0, 0.0001)


func test_decalage_en_avance_et_en_retard() -> void:
	assert_almost_eq(RhythmMath.beat_offset(beat * 3.0 + 0.05, beat), 0.05, 0.0001)
	assert_almost_eq(RhythmMath.beat_offset(beat * 3.0 - 0.05, beat), -0.05, 0.0001)


func test_phase_dans_le_temps() -> void:
	assert_almost_eq(RhythmMath.beat_phase(beat * 2.0, beat), 0.0, 0.0001)
	assert_almost_eq(RhythmMath.beat_phase(beat * 2.5, beat), 0.5, 0.0001)


func test_parfait_sur_le_temps_et_un_peu_apres() -> void:
	assert_eq(RhythmMath.judge(0.0, tuning), RhythmMath.Judgement.PERFECT)
	assert_eq(RhythmMath.judge(tuning.perfect_late, tuning), RhythmMath.Judgement.PERFECT)
	assert_eq(RhythmMath.judge(-tuning.perfect_early, tuning), RhythmMath.Judgement.PERFECT)


func test_le_retard_est_plus_tolere_que_l_avance() -> void:
	var offset: float = (tuning.perfect_early + tuning.perfect_late) / 2.0
	assert_eq(RhythmMath.judge(offset, tuning), RhythmMath.Judgement.PERFECT, "en retard : encore Parfait")
	assert_eq(RhythmMath.judge(-offset, tuning), RhythmMath.Judgement.GOOD, "autant en avance : seulement Bien")


func test_bien_puis_rate() -> void:
	assert_eq(RhythmMath.judge(tuning.good_late, tuning), RhythmMath.Judgement.GOOD)
	assert_eq(RhythmMath.judge(tuning.good_late + 0.01, tuning), RhythmMath.Judgement.MISS)
	assert_eq(RhythmMath.judge(-tuning.good_early - 0.01, tuning), RhythmMath.Judgement.MISS)


func test_bonus_de_degats() -> void:
	assert_eq(RhythmMath.damage_multiplier(RhythmMath.Judgement.PERFECT, tuning), tuning.perfect_multiplier)
	assert_eq(RhythmMath.damage_multiplier(RhythmMath.Judgement.GOOD, tuning), tuning.good_multiplier)
	assert_eq(RhythmMath.damage_multiplier(RhythmMath.Judgement.MISS, tuning), 1.0, "à contretemps, ça marche quand même")


func test_groove_gagne() -> void:
	assert_eq(RhythmMath.groove_gain(RhythmMath.Judgement.PERFECT, tuning), tuning.groove_perfect)
	assert_eq(RhythmMath.groove_gain(RhythmMath.Judgement.GOOD, tuning), tuning.groove_good)
	assert_eq(RhythmMath.groove_gain(RhythmMath.Judgement.MISS, tuning), 0.0)
