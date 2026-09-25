extends GutTest
## Compteur de combo : les coups s'additionnent, le combo se perd après un temps sans toucher.

const TIMEOUT := 2.6

var combo: ComboCounter


func before_each() -> void:
	combo = ComboCounter.new(TIMEOUT)


func test_compte_les_coups_enchaines() -> void:
	combo.register_hit(1.0)
	combo.register_hit(1.5)
	combo.register_hit(2.0)
	assert_eq(combo.hits, 3)


func test_perdu_apres_trop_longtemps_sans_toucher() -> void:
	combo.register_hit(1.0)
	combo.update(1.0 + TIMEOUT * 1.1)
	assert_eq(combo.hits, 0)


func test_un_coup_tardif_repart_de_un() -> void:
	combo.register_hit(1.0)
	combo.register_hit(2.0)
	combo.register_hit(2.0 + TIMEOUT * 1.1)
	assert_eq(combo.hits, 1)


func test_juste_avant_la_limite_le_combo_tient() -> void:
	combo.register_hit(1.0)
	combo.update(1.0 + TIMEOUT * 0.9)
	assert_eq(combo.hits, 1)


func test_reset() -> void:
	combo.register_hit(1.0)
	combo.reset()
	assert_eq(combo.hits, 0)
