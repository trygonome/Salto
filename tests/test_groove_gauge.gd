extends GutTest
## Jauge de groove : se remplit, plafonne, se vide.

var gauge: GrooveGauge


func before_each() -> void:
	gauge = GrooveGauge.new(10.0)


func test_se_remplit_et_plafonne() -> void:
	gauge.add(4.0)
	assert_eq(gauge.fraction(), 0.4)
	gauge.add(100.0)
	assert_true(gauge.is_full())
	assert_eq(gauge.value, 10.0)


func test_pas_pleine_avant_le_maximum() -> void:
	gauge.add(9.5)
	assert_false(gauge.is_full())


func test_se_vide() -> void:
	gauge.add(10.0)
	gauge.empty()
	assert_eq(gauge.value, 0.0)
	assert_false(gauge.is_full())
