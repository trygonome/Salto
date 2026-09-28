class_name ExpeditionCoach
extends RefCounted
## Conseils de l'expédition (version 2.9), près du bouton à utiliser, comme ceux de la nuit : courir,
## frapper, esquiver, le coup de grâce, le coup chargé, et la réponse qu'attend chaque espèce la
## première fois qu'on la croise. Un seul à la fois ; il s'en va une fois fait, au bout d'un moment,
## ou quand il ne s'applique plus. Les conseils déjà suivis (dans la nuit aussi) ne reviennent pas.

## Conseils dans l'ordre où on les propose : identifiant et bouton.
const HINT_BUTTONS: Array[Array] = [
	[&"move", TouchControls.MOVE], [&"attack", &"attack"], [&"dodge", &"dodge"], [&"grace", &"attack"],
	[&"answer_hopper", &"attack"], [&"answer_shielder", &"jump"], [&"answer_charger", &"dodge"],
	[&"answer_flyer", &"jump"], [&"answer_spitter", &"dodge"], [&"answer_weaver", &"jump"],
	[&"answer_totem", &"attack"], [&"answer_dancer", &"dodge"], [&"answer_brute", &"dodge"], [&"charge", &"attack"],
]
const ANSWER_HINT := "answer_"

var _hud: Hud
var _hero: Hero
var _hint: StringName = &""
var _time: float = 0.0
var _moved: float = 0.0
var _attacks: int = 0
var _cooldowns: Dictionary[StringName, float] = {}


func _init(hud: Hud, hero: Hero) -> void:
	_hud = hud
	_hero = hero
	hero.action_pressed.connect(_on_action_pressed)
	hero.answered.connect(func(species: StringName) -> void: learn(StringName(ANSWER_HINT + species)))
	hero.hit_landed.connect(func(hit: HitData) -> void:
		if hit.move == &"grace" or hit.move == &"charged":
			learn(hit.move if hit.move == &"grace" else &"charge"))


## Un pas de conseils (appelé à chaque image pendant l'expédition).
func update(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	for id: StringName in _cooldowns.keys():
		_cooldowns[id] -= delta
	if _hero.input_move.length() > 0.0:
		_moved += delta
		if _moved > tuning.hint_move_time:
			learn(&"move")
	if _hint != &"":
		_time += delta
		if Game.profile.is_hint_done(_hint) or _time > tuning.hint_show_time or not applies(_hint):
			clear()
		return
	for entry: Array in HINT_BUTTONS:
		var id: StringName = entry[0]
		if Game.profile.is_hint_done(id) or _cooldowns.get(id, 0.0) > 0.0:
			continue
		if id != &"move" and not Game.profile.is_hint_done(&"move"):
			return
		if applies(id):
			_hint = id
			_time = 0.0
			_hud.show_coach(GameTexts.HINTS[id], entry[1])
			return


func current() -> StringName:
	return _hint


## Vrai si le conseil `id` a du sens maintenant.
func applies(id: StringName) -> bool:
	var tuning: TuningData = Tuning.data
	match id:
		&"move":
			return true
		&"attack":
			return _near(func(m: Muet) -> bool: return true, tuning.hint_danger_distance)
		&"dodge":
			return _near(func(m: Muet) -> bool: return m.is_threatening(), tuning.hint_danger_distance)
		&"grace":
			return _hero.grace_target() != null
		&"charge":
			return _attacks >= tuning.hint_combo_after * 2
	if String(id).begins_with(ANSWER_HINT):
		var species := StringName(String(id).trim_prefix(ANSWER_HINT))
		return _near(func(m: Muet) -> bool: return m.species == species, tuning.hint_danger_distance)
	return false


func learn(id: StringName) -> void:
	if Game.profile.is_hint_done(id):
		return
	Game.mark_hint_done(id)
	if _hint == id:
		clear()


func clear() -> void:
	if _hint == &"":
		return
	_cooldowns[_hint] = Tuning.data.hint_cooldown
	_hint = &""
	_hud.hide_coach()


func _on_action_pressed(action: StringName) -> void:
	match action:
		&"attack":
			_attacks += 1
			learn(&"attack")
		&"dodge":
			learn(&"dodge")


func _near(test: Callable, distance: float) -> bool:
	for node: Node in _hero.get_tree().get_nodes_in_group(&"muets"):
		var muet: Muet = node as Muet
		if not muet.is_freed() and muet.global_position.distance_to(_hero.global_position) < distance and test.call(muet):
			return true
	return false
