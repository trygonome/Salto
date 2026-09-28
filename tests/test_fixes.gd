extends GutTest
## Correctifs 3.8.1 (vidéo du téléphone) : la page de départ ne se rouvre plus en boucle au passage du
## nord, le joystick se relâche pendant une pause, une case ne parle qu'au héros qui s'y arrête.

const LevelScene: PackedScene = preload("res://scenes/levels/expedition.tscn")
const ControlsScene: PackedScene = preload("res://scenes/ui/touch_controls.tscn")

var tuning: TuningData = Tuning.data
var level: Expedition
var hero: Hero


func before_each() -> void:
	Save.path = "user://test_fixes.json"
	Game.profile = Profile.create()
	Game.profile.expeditions = 2
	Game.start_on_load = false
	Game.village_on_load = false
	Game.last_summary = {}
	Game.run = null


func after_each() -> void:
	get_tree().paused = false
	Game.run = null
	Game.playing = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.path))


func after_all() -> void:
	Game.profile = Profile.new()
	Game.refresh_stats()


func _village() -> void:
	level = LevelScene.instantiate() as Expedition
	hero = level.get_node("Hero") as Hero
	add_child_autofree(level)
	await get_tree().process_frame
	level.enter_village()
	level.set(&"_chief_lines", PackedStringArray())
	hero.reads_player_input = false


func test_retour_au_passage_du_nord_ne_rouvre_pas_la_page() -> void:
	await _village()
	var gate: Vector2 = WorldGen.gap_point(0.0, level.get(&"_radius") - tuning.room_exit_inset / tuning.voxel_unit) * tuning.voxel_unit
	hero.global_position = Vector3(gate.x, 0.0, gate.y)
	for i: int in 5:
		await get_tree().physics_frame
	var depart: DepartScreen = level.get_node("DepartScreen") as DepartScreen
	assert_true(depart.is_open(), "le passage ouvre la page de départ")
	depart.go_back()
	for i: int in 10:
		await get_tree().physics_frame
	assert_false(depart.is_open(), "« Retour » la ferme pour de bon, même le héros encore sur le passage")
	var gates: Array[Node] = level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n is ExitGate and not n.is_queued_for_deletion())
	assert_true((gates[0] as ExitGate).wait_for_leave)
	hero.global_position += Vector3(0.0, 0.0, tuning.gate_rearm_distance + 1.0)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_false((gates[0] as ExitGate).wait_for_leave, "une fois le héros éloigné, le passage se franchit de nouveau")


func test_le_joystick_se_relache_pendant_une_pause() -> void:
	var controls: Node = ControlsScene.instantiate()
	add_child_autofree(controls)
	await get_tree().process_frame
	var stick: FloatingJoystick = controls.find_children("*", "FloatingJoystick", true, false)[0] as FloatingJoystick
	stick.visible = true
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = stick.get_global_rect().get_center()
	stick.call(&"_input", touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = touch.position + Vector2(tuning.joystick_radius_px, 0.0)
	stick.call(&"_input", drag)
	assert_true(stick.is_active())
	assert_gt(stick.vector.length(), 0.0)
	get_tree().paused = true
	await get_tree().process_frame
	assert_false(stick.is_active(), "le doigt levé pendant la pause n'aurait pas été entendu")
	assert_eq(stick.vector, Vector2.ZERO, "le héros ne continue pas de marcher seul")
	get_tree().paused = false


func test_une_case_ne_parle_pas_au_heros_qui_passe() -> void:
	Game.profile.feathers = 200
	await _village()
	var plot: Vector2 = WorldGen.VILLAGE_PLOTS[Village.ALTAR] * tuning.voxel_unit
	var screen: BoonScreen = level.get_node("BoonScreen") as BoonScreen
	# Il traverse la zone de la case en courant.
	hero.global_position = Vector3(plot.x - tuning.village_plot_radius * 1.5, 0.0, plot.y)
	for i: int in 40:
		hero.input_move = Vector2(1.0, 0.0)
		await get_tree().physics_frame
	assert_false(screen.is_open(), "en passant, rien ne s'ouvre")
	hero.input_move = Vector2.ZERO
	hero.global_position = Vector3(plot.x, 0.0, plot.y) + Vector3(0.0, 0.0, tuning.village_plot_radius * 0.5)
	await get_tree().create_timer(tuning.village_plot_dwell + 0.2).timeout
	assert_true(screen.is_open(), "arrêté devant, la case parle")
	screen.hide_screen()
	get_tree().paused = false
