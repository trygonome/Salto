extends GutTest
## Mémoire des appuis : un appui reste valable un court moment, et ne sert qu'une fois.

const DURATION := 0.2

var buffer: InputBuffer


func before_each() -> void:
	buffer = InputBuffer.new(DURATION)


func test_un_appui_recent_est_consomme() -> void:
	buffer.press(&"jump", 1.0)
	assert_true(buffer.consume(&"jump", 1.0 + DURATION))


func test_un_appui_trop_ancien_est_oublie() -> void:
	buffer.press(&"jump", 1.0)
	assert_false(buffer.consume(&"jump", 1.0 + DURATION * 1.5))


func test_un_appui_ne_sert_qu_une_fois() -> void:
	buffer.press(&"jump", 1.0)
	assert_true(buffer.consume(&"jump", 1.05))
	assert_false(buffer.consume(&"jump", 1.1))


func test_regarder_sans_consommer() -> void:
	buffer.press(&"dodge", 1.0)
	assert_true(buffer.is_buffered(&"dodge", 1.1))
	assert_true(buffer.consume(&"dodge", 1.1))


func test_les_actions_sont_independantes() -> void:
	buffer.press(&"jump", 1.0)
	assert_false(buffer.consume(&"dodge", 1.0))
	assert_true(buffer.consume(&"jump", 1.0))


func test_un_nouvel_appui_repart_a_zero() -> void:
	buffer.press(&"jump", 1.0)
	buffer.press(&"jump", 1.5)
	assert_true(buffer.consume(&"jump", 1.5 + DURATION))


func test_clear_oublie_tout() -> void:
	buffer.press(&"jump", 1.0)
	buffer.clear()
	assert_false(buffer.consume(&"jump", 1.0))
