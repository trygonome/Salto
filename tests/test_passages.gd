extends GutTest
## Passages rituels (version 3.5) : portes-totems à l'icône de la récompense, vague de couleur qui
## dissout la brume de la clairière suivante, musique qui revient à sa base puis reprend.

const LevelScene: PackedScene = preload("res://scenes/levels/expedition.tscn")
const GateScene: PackedScene = preload("res://scenes/expedition/exit_gate.tscn")

var tuning: TuningData = Tuning.data
var level: Expedition
var hero: Hero


func before_each() -> void:
	Save.path = "user://test_passages.json"
	Game.profile = Profile.create()
	Game.profile.expeditions = 1
	Game.start_on_load = false
	Game.run = null


func after_each() -> void:
	get_tree().paused = false
	Game.run = null
	Game.playing = false
	RenderingServer.global_shader_parameter_set(&"salto_fog_density", tuning.fog_density)
	RenderingServer.global_shader_parameter_set(&"salto_wave", Vector4.ZERO)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.path))


func test_la_vague_part_forte_dans_la_brume_puis_s_efface() -> void:
	var start: Vector2 = WorldMood.wave_state(0.0, tuning)
	assert_eq(start.x, 1.0, "au départ, la vague est pleine")
	assert_almost_eq(start.y, tuning.passage_fog_boost, 0.001, "et la brume épaisse")
	var end: Vector2 = WorldMood.wave_state(tuning.passage_wave_reach, tuning)
	assert_eq(end.x, 0.0, "au bout de sa course, elle s'est effacée")
	assert_almost_eq(end.y, 1.0, 0.001, "la brume est redevenue normale")
	var middle: Vector2 = WorldMood.wave_state(tuning.passage_wave_reach * 0.4, tuning)
	assert_between(middle.y, 1.0, tuning.passage_fog_boost, "elle se dissout peu à peu")


func test_une_porte_totem_montre_l_icone_de_sa_recompense() -> void:
	var gate: ExitGate = GateScene.instantiate() as ExitGate
	gate.reward = RunState.HEAL
	add_child_autofree(gate)
	var emblem: Node3D = gate.get_node_or_null(^"Emblem") as Node3D
	assert_not_null(emblem, "l'icône voxel de la récompense entre les mâts")
	var color: Vector3 = gate.colors[RunState.HEAL]
	var cells: PackedFloat32Array = ExitGate.totem_cells(color)
	var colored: int = 0
	for i: int in cells.size() / WorldGen.STRIDE:
		if Vector3(cells[i * WorldGen.STRIDE + 3], cells[i * WorldGen.STRIDE + 4], cells[i * WorldGen.STRIDE + 5]) == color:
			colored += 1
	assert_gt(colored, 10, "des yeux, des ailes, un seuil aux couleurs de la récompense")
	assert_ne(gate.veil_color(), Color.BLACK)


func test_franchir_un_passage_est_un_petit_moment() -> void:
	var level_node: Expedition = LevelScene.instantiate() as Expedition
	level = level_node
	hero = level.get_node("Hero") as Hero
	add_child_autofree(level)
	await get_tree().process_frame
	level.start_sortie()
	hero.reads_player_input = false
	level.set(&"_cleared", true)
	level.call(&"_open_exits")
	var gates: Array[Node] = level.get_node("Pickups").get_children().filter(func(n: Node) -> bool: return n is ExitGate)
	assert_false(gates.is_empty())
	var gate: ExitGate = gates[0] as ExitGate
	var room: int = Game.run.room
	gate.chosen.emit(gate.reward)
	assert_eq(Rhythm.audible_layers(), 1, "la musique revient à sa base")
	await get_tree().create_timer(tuning.room_fade_time * 1.5).timeout
	assert_eq(Game.run.room, room + 1, "de l'autre côté")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(level.mood.is_waving(), "une vague de couleur part du héros")
	assert_gt(level.mood.fog_boost(), 1.0, "dans la brume")
	await get_tree().create_timer(tuning.passage_music_delay + 0.2).timeout
	assert_eq(Rhythm.audible_layers(), level.get(&"_music_layers"), "puis la musique reprend ses couches")
	await get_tree().create_timer(tuning.passage_wave_reach / tuning.passage_wave_speed).timeout
	assert_false(level.mood.is_waving())
	assert_eq(level.mood.fog_boost(), 1.0, "la brume s'est dissoute")
