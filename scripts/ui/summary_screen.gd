class_name SummaryScreen
extends ScreenLayer
## Résumé d'une sortie, comme dans le prototype : titre (nuit accomplie, saga achevée, retour au
## village, évanoui), ce qui reste à faire, les chiffres de la sortie (tambours, Muets libérés,
## niveau, temps) ; Repartir (ou Nuit suivante), Sac, Talents, Accueil.

var _summary: Dictionary = {}

@onready var _title: Label = %Title
@onready var _sub: Label = %Sub
@onready var _stats: GridContainer = %Stats
@onready var _gain: Label = %Gain
@onready var _again: Button = %Again
@onready var _bag: Button = %Bag
@onready var _talents: Button = %Talents
@onready var _home: Button = %Home


func _ready() -> void:
	super()
	add_to_group(&"summary_screen")
	_home.text = GameTexts.HOME
	_again.pressed.connect(func() -> void: _restart(true))
	_home.pressed.connect(func() -> void: _restart(false))
	_bag.pressed.connect(func() -> void: _open_sub(&"bag_screen"))
	_talents.pressed.connect(func() -> void: _open_sub(&"talents_screen"))


## Ouvre le résumé de `summary` (voir Game.end_sortie).
func open(summary: Dictionary) -> void:
	_summary = summary
	_fill()
	show_screen()


## Revient au résumé (depuis le sac ou les talents).
func reopen() -> void:
	_fill()
	show_screen()


func _fill() -> void:
	var s: Dictionary = _summary
	var kind: StringName = s.get(&"kind", &"quit")
	var night: bool = kind == &"night"
	var finale: bool = s.get(&"finale", false)
	var drums: int = Tuning.data.night_drums_required
	if night:
		_title.text = GameTexts.SUMMARY_FINALE if finale else GameTexts.SUMMARY_NIGHT
		var next: String = GameTexts.SUMMARY_ENDLESS_OPEN if finale else GameTexts.SUMMARY_NEXT % GameTexts.night_name(s[&"next_night"])
		_sub.text = "%s %s" % [GameTexts.night_info(s[&"night"])[&"done"], next]
	else:
		_title.text = GameTexts.SUMMARY_QUIT if kind == &"quit" else GameTexts.SUMMARY_FAINT
		var banked: int = s.get(&"banked", 0)
		var rest: String = GameTexts.SUMMARY_NONE
		if banked > 0:
			rest = (GameTexts.SUMMARY_BANKED_MANY if banked > 1 else GameTexts.SUMMARY_BANKED_ONE) % [GameTexts.plural(banked, GameTexts.DRUM), drums - banked]
		_sub.text = (GameTexts.SUMMARY_QUIT_SUB if kind == &"quit" else GameTexts.SUMMARY_FAINT_SUB) + rest
	for child: Node in _stats.get_children():
		child.queue_free()
	var rows: Array = [
		[GameTexts.SUMMARY_DRUMS, "%d / %d" % [drums if night else s.get(&"banked", 0), drums]],
		[GameTexts.SUMMARY_MUETS, str(s.get(&"muets", 0))],
		[GameTexts.SUMMARY_LEVEL, str(s.get(&"level", 1))],
		[GameTexts.SUMMARY_TIME, GameTexts.duration(s.get(&"time", 0.0))],
	]
	for row: Array in rows:
		var name_label := Label.new()
		name_label.text = row[0]
		name_label.theme_type_variation = &"StatName"
		_stats.add_child(name_label)
		var value := Label.new()
		value.text = row[1]
		value.theme_type_variation = &"StatValue"
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_stats.add_child(value)
	_gain.text = ""
	_gain.visible = false
	_again.text = (GameTexts.ENDLESS_NIGHT if finale else GameTexts.NEXT_NIGHT) if night else GameTexts.AGAIN
	var profile: Profile = Game.profile
	_bag.text = GameTexts.BAG_BUTTON
	_talents.text = GameTexts.TALENTS_BUTTON_POINTS % GameTexts.plural(profile.talent_points, GameTexts.POINT) if profile.talent_points > 0 else GameTexts.TALENTS_BUTTON


func _restart(play: bool) -> void:
	hide_screen()
	get_tree().call_group(&"night_level", &"restart", play)


func _open_sub(group: StringName) -> void:
	hide_screen()
	var screen: Node = get_tree().get_first_node_in_group(group)
	if screen:
		screen.call(&"open", reopen)


## Le bouton retour d'Android ramène à l'accueil.
func _on_back_requested() -> void:
	_restart(false)
