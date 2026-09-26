extends GutTest
## Jauge de groove : se remplit, plafonne, se vide, retombe sans rythme.

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


func test_sans_rythme_la_jauge_retombe_sauf_pleine() -> void:
	gauge.add(5.0)
	gauge.drain(2.0, 3.0, 1.0)
	assert_eq(gauge.value, 5.0, "un court silence ne coûte rien")
	gauge.drain(2.0, 3.0, 1.0)
	assert_eq(gauge.value, 3.0, "puis le silence revient")
	gauge.add(1.0)
	gauge.drain(1.0, 3.0, 1.0)
	assert_eq(gauge.value, 4.0, "un gain relance l'attente")
	gauge.drain(100.0, 3.0, 1.0)
	assert_eq(gauge.value, 0.0)
	gauge.add(10.0)
	gauge.drain(100.0, 3.0, 1.0)
	assert_true(gauge.is_full(), "pleine, elle attend le Salto arc-en-ciel")
