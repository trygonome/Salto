extends GutTest
## Joystick flottant : zone morte, progression, pleine vitesse, direction.

const RADIUS := 46.0

var tuning: TuningData = Tuning.data


func _shape(offset: Vector2) -> Vector2:
	return FloatingJoystick.shape(offset, RADIUS, tuning.joystick_dead_zone, tuning.joystick_full_speed)


func test_rien_dans_la_zone_morte() -> void:
	assert_eq(_shape(Vector2.RIGHT * RADIUS * tuning.joystick_dead_zone), Vector2.ZERO)


func test_pleine_vitesse_au_seuil() -> void:
	assert_almost_eq(_shape(Vector2.UP * RADIUS * tuning.joystick_full_speed).length(), 1.0, 0.0001)


func test_jamais_plus_que_la_pleine_vitesse() -> void:
	assert_almost_eq(_shape(Vector2.UP * RADIUS * 3.0).length(), 1.0, 0.0001)


func test_progression_lineaire_entre_les_deux() -> void:
	var middle: float = (tuning.joystick_dead_zone + tuning.joystick_full_speed) / 2.0
	assert_almost_eq(_shape(Vector2.LEFT * RADIUS * middle).length(), 0.5, 0.0001)


func test_garde_la_direction_du_doigt() -> void:
	var offset := Vector2(3.0, -4.0) * RADIUS
	assert_almost_eq(_shape(offset).normalized(), offset.normalized(), Vector2.ONE * 0.0001)
