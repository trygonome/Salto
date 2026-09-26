class_name PauseMenu
extends ScreenLayer
## Pause du prototype : la nuit en cours, un rappel des gestes, Reprendre, Sac et Talents (au
## village seulement : c'est là que le héros grandit), Carnet, Vibrations, Son, chiffres de dégâts (et
## infos techniques des versions de test), Rentrer au village (touché deux fois : la sortie se
## termine). S'ouvre avec le bouton de pause, Échap / Start, le bouton retour d'Android, ou quand
## le jeu passe en arrière-plan.

## Pages du carnet (leur nombre).
@export var notebook: NotebookData

var _quit_armed: bool = false

@onready var _info: Label = %Info
@onready var _resume: Button = %Resume
@onready var _bag: Button = %Bag
@onready var _talents: Button = %Talents
@onready var _notebook: Button = %Notebook
@onready var _sound: Button = %Sound
@onready var _damage: Button = %DamageNumbers
@onready var _vibration: Button = %Vibration
@onready var _debug: Button = %DebugInfo
@onready var _quit: Button = %Quit


func _ready() -> void:
	super()
	add_to_group(&"pause_menu")
	%Title.text = GameTexts.PAUSE_TITLE
	%Help.text = GameTexts.PAUSE_HELP
	_resume.text = GameTexts.RESUME
	_resume.pressed.connect(close)
	_bag.pressed.connect(func() -> void: _open_sub(&"bag_screen"))
	_talents.pressed.connect(func() -> void: _open_sub(&"talents_screen"))
	_notebook.pressed.connect(func() -> void: _open_sub(&"notebook_screen"))
	_sound.pressed.connect(func() -> void:
		Game.set_muted(not Game.profile.muted)
		_refresh())
	_vibration.pressed.connect(func() -> void:
		Game.set_vibration(not Game.profile.vibration)
		_refresh())
	_damage.pressed.connect(func() -> void:
		Game.set_damage_numbers(not Game.profile.damage_numbers)
		_refresh())
	_debug.pressed.connect(func() -> void:
		Game.set_debug_info(not Game.profile.debug_info)
		_refresh())
	_debug.visible = DebugOverlay.available()
	_quit.pressed.connect(_on_quit)


## Met le jeu en pause et ouvre le menu (pendant une sortie seulement).
func open() -> void:
	if visible or get_tree().paused or not _in_sortie():
		return
	get_tree().paused = true
	_quit_armed = false
	_refresh()
	show_screen()


## Revient au menu (depuis le sac ou les talents), le jeu reste en pause.
func reopen() -> void:
	_refresh()
	show_screen()


## Reprend la partie.
func close() -> void:
	if not visible:
		return
	hide_screen()
	get_tree().paused = false


## Retour : du menu vers le jeu, du jeu vers le menu.
func back() -> void:
	if visible:
		close()
	else:
		open()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if visible:
			close()
			get_viewport().set_input_as_handled()
		elif not get_tree().paused and _in_sortie():
			open()
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if visible:
				close()
			elif not get_tree().paused:
				open()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			open()


func _refresh() -> void:
	var profile: Profile = Game.profile
	_info.text = GameTexts.NIGHT_CHAPTER % [Game.night, GameTexts.night_name(Game.night)]
	var home: bool = Game.at_village or not Game.playing
	_bag.disabled = not home
	_talents.disabled = not home
	if home:
		_bag.text = GameTexts.BAG_BUTTON
		_talents.text = GameTexts.TALENTS_BUTTON_POINTS % GameTexts.plural(profile.talent_points, GameTexts.POINT) if profile.talent_points > 0 else GameTexts.TALENTS_BUTTON
	else:
		_bag.text = GameTexts.BAG_AT_VILLAGE
		_talents.text = GameTexts.TALENTS_AT_VILLAGE
	_sound.text = GameTexts.SOUND_OFF if profile.muted else GameTexts.SOUND_ON
	_damage.text = GameTexts.DAMAGE_NUMBERS_ON if profile.damage_numbers else GameTexts.DAMAGE_NUMBERS_OFF
	_notebook.text = GameTexts.NOTEBOOK_BUTTON % [profile.pages.size(), notebook.pages.size()]
	_vibration.text = GameTexts.VIBRATION_ON if profile.vibration else GameTexts.VIBRATION_OFF
	_debug.text = GameTexts.DEBUG_ON if profile.debug_info else GameTexts.DEBUG_OFF
	_quit.text = GameTexts.QUIT_CONFIRM if _quit_armed else GameTexts.QUIT


func _on_quit() -> void:
	if not _quit_armed:
		_quit_armed = true
		_refresh()
		return
	hide_screen()
	get_tree().call_group(&"night_level", &"end_sortie", &"quit")


func _open_sub(group: StringName) -> void:
	hide_screen()
	var screen: Node = get_tree().get_first_node_in_group(group)
	if screen:
		screen.call(&"open", reopen)


func _in_sortie() -> bool:
	var night: Node = get_tree().get_first_node_in_group(&"night_level")
	return night == null or bool(night.get(&"in_sortie"))
