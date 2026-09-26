class_name TitleScreen
extends ScreenLayer
## Écran titre du prototype, par-dessus le village qui danse : SALTO, la saga des cinq nuits (faites,
## en cours), le chapitre en cours et ses tambours déjà au village, Commencer / Continuer, Sac,
## Talents, Nouvelle partie (touchée deux fois).

## Taille d'une pastille de la saga (px).
@export var saga_dot_size: float

var _reset_armed: bool = false

@onready var _saga: HBoxContainer = %Saga
@onready var _chapter: Label = %Chapter
@onready var _chapter_small: Label = %ChapterSmall
@onready var _play: Button = %Play
@onready var _bag: Button = %Bag
@onready var _talents: Button = %Talents
@onready var _new_game: Button = %NewGame


func _ready() -> void:
	super()
	add_to_group(&"title_screen")
	%GameTitle.text = GameTexts.GAME_TITLE
	%Subtitle.text = GameTexts.GAME_SUBTITLE
	_play.pressed.connect(_on_play)
	_bag.pressed.connect(func() -> void: _open_sub(&"bag_screen"))
	_talents.pressed.connect(func() -> void: _open_sub(&"talents_screen"))
	_new_game.pressed.connect(_on_new_game)


func _layout() -> void:
	super()
	var compact: bool = get_viewport().get_visible_rect().size.y < compact_height
	(%GameTitle as Label).theme_type_variation = &"DisplayTitleSmall" if compact else &"DisplayTitle"


## Montre l'écran titre, à jour.
func open() -> void:
	refresh()
	show_screen()


func close() -> void:
	hide_screen()


func refresh() -> void:
	var profile: Profile = Game.profile
	var tuning: TuningData = Tuning.data
	for child: Node in _saga.get_children():
		child.queue_free()
	for n: int in range(1, tuning.saga_nights + 1):
		var dot := PanelContainer.new()
		dot.custom_minimum_size = Vector2.ONE * saga_dot_size
		dot.theme_type_variation = &"SagaDone" if n <= profile.nights_done else &"SagaCurrent" if n == profile.night else &"SagaDot"
		var number := Label.new()
		number.text = str(n)
		number.theme_type_variation = &"SagaNumberDone" if n <= profile.nights_done else &"SagaNumber"
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dot.add_child(number)
		_saga.add_child(dot)
	_chapter.text = GameTexts.NIGHT_CHAPTER % [profile.night, GameTexts.night_name(profile.night)]
	if profile.started:
		var banked: String = GameTexts.TITLE_DRUMS % GameTexts.plural(profile.banked_count(), GameTexts.DRUM)
		_chapter_small.text = banked + (GameTexts.TITLE_SORTIES % GameTexts.plural(profile.sortie, GameTexts.SORTIE) if profile.sortie > 0 else "")
	else:
		_chapter_small.text = GameTexts.TITLE_PITCH
	_play.text = GameTexts.CONTINUE if profile.started else GameTexts.START
	_new_game.visible = profile.started
	_reset_armed = false
	_new_game.text = GameTexts.NEW_GAME
	_bag.text = GameTexts.BAG_BUTTON
	_talents.text = GameTexts.TALENTS_BUTTON_POINTS % GameTexts.plural(profile.talent_points, GameTexts.POINT) if profile.talent_points > 0 else GameTexts.TALENTS_BUTTON


func _on_play() -> void:
	close()
	get_tree().call_group(&"night_level", &"start_sortie")


func _on_new_game() -> void:
	if not _reset_armed:
		_reset_armed = true
		_new_game.text = GameTexts.NEW_GAME_CONFIRM
		return
	Game.new_game()
	get_tree().call_group(&"night_level", &"restart", false)


## Ouvre le sac ou les talents ; « Retour » ramène ici.
func _open_sub(group: StringName) -> void:
	hide_screen()
	var screen: Node = get_tree().get_first_node_in_group(group)
	if screen:
		screen.call(&"open", open)


## À l'écran titre, le bouton retour d'Android quitte le jeu.
func _on_back_requested() -> void:
	get_tree().quit()
