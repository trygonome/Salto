class_name EndScreen
extends CanvasLayer
## Écran de fin de nuit : temps, record, Muets libérés, carnet, objets trouvés ; « Rejouer la
## nuit ». Le jeu s'arrête derrière, la musique complète continue.

@onready var _panel: Control = %Panel
@onready var _stats: GridContainer = %Stats


func _ready() -> void:
	add_to_group(&"end_screen")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	%PlayAgain.text = GameTexts.PLAY_AGAIN
	%PlayAgain.pressed.connect(_play_again)


func open() -> void:
	if visible:
		return
	get_tree().call_group(&"pause_menu", &"close")
	get_tree().paused = true
	%OverTitle.text = GameTexts.NIGHT_LABEL % Game.night
	%TitleText.text = GameTexts.TITLE_NIGHT_COMPLETE
	_fill_stats()
	visible = true
	_panel.modulate.a = 0.0
	create_tween().tween_property(_panel, "modulate:a", 1.0, Tuning.data.title_fade_in_time)


func is_open() -> bool:
	return visible


func _fill_stats() -> void:
	for child: Node in _stats.get_children():
		_stats.remove_child(child)
		child.queue_free()
	var progress: NightProgress = Game.progress
	var profile: Profile = Game.profile
	var best: String = GameTexts.END_NEW_RECORD if Game.new_record else GameTexts.duration(profile.best_time(Game.night))
	var notebook: NotebookData = PauseMenu.NOTEBOOK
	var rows: Array = [
		[GameTexts.END_TIME, GameTexts.duration(progress.elapsed)],
		[GameTexts.END_BEST_TIME, best],
		[GameTexts.END_MUETS_FREED, str(progress.muets_freed)],
		[GameTexts.END_PAGES, GameTexts.NOTEBOOK_COUNT % [profile.pages.size(), notebook.pages.size()]],
		[GameTexts.END_ITEMS, str(progress.items.size())],
	]
	for row: Array in rows:
		var name_label := Label.new()
		name_label.text = row[0]
		name_label.theme_type_variation = &"SmallLabel"
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stats.add_child(name_label)
		var value_label := Label.new()
		value_label.text = row[1]
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_stats.add_child(value_label)


func _play_again() -> void:
	visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()
