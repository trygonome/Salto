class_name Hud
extends CanvasLayer
## Interface en jeu, selon la charte des retours à l'écran (docs/GDD.md, section 12) :
## - le monde parle d'abord : le HUD se limite aux PV, aux tambours et au bouton de pause ;
## - au plus un message éphémère à la fois, en haut, ou près de sa source (répliques) ;
## - grands titres pour trois moments seulement (début de nuit, sanctuaire libéré, nuit
##   accomplie) ; pendant un titre, les messages du haut et les aides attendent ;
## - carte de l'objet trouvé en bas, pendant loot_card_time ;
## - aide contextuelle : le bon bouton brille, 2 à 4 mots, jusqu'à ce que l'action soit faite ;
## - chiffres de dégâts discrets et désactivables.

## Le grand titre en cours vient de disparaître.
signal title_finished

## Importance d'un message : une réplique ne remplace pas une information.
enum Priority { REPLY, INFO }

## Couleur de chaque rareté (commun, rare, épique, légendaire).
@export var rarity_colors: Array[Color]
## Pictogramme de chaque emplacement d'objet (chevillières, masque, talisman).
@export var slot_icons: Array[Texture2D]
@export var drum_icon: Texture2D
@export var drum_empty_icon: Texture2D
## Taille d'un pictogramme de tambour (px).
@export var drum_icon_size: float
@export var damage_number_scene: PackedScene
## Écart minimal entre un texte et les bords de l'écran (px).
@export var screen_margin: float
## Hauteur du point d'impact où apparaît un chiffre de dégâts (m, au-dessus du contact).
@export var damage_number_height: float
## Largeur d'une réplique (px) : les longues passent à la ligne.
@export var reply_width: float
## Une réplique dont celui qui parle sort de l'écran de plus que cette marge (px) se cache.
@export var reply_offscreen_margin: float
## Écart entre la carte d'objet et le bas de l'écran : en portrait, au-dessus des boutons ;
## en paysage, tout en bas entre le joystick et les boutons (px).
@export var card_bottom_portrait: float
@export var card_bottom_landscape: float

var _hero: Hero
var _title_active: bool = false
var _message_priority: Priority = Priority.REPLY
var _message_time: float = 0.0
var _message_left: float = 0.0
var _message_label: Label
var _reply_source: Node3D
var _reply_point: Vector3 = Vector3.ZERO
var _reply_height: float = 0.0
## Message du haut arrivé pendant un titre : [texte].
var _pending_message: String = ""
var _pending_hint: Array = []
var _hint: StringName = &""
var _hint_action: StringName = &""
var _reply_index: int = 0
var _time: float = 0.0
var _card_tween: Tween

@onready var _health_bar: HealthBar = %HealthBar
@onready var _drums: HBoxContainer = %Drums
@onready var _pause_button: Button = %PauseButton
@onready var _message: Label = %Message
@onready var _reply: Label = %Reply
@onready var _title: Control = %Title
@onready var _over_title: Label = %OverTitle
@onready var _title_text: Label = %TitleText
@onready var _card: Control = %LootCard
@onready var _card_icon: TextureRect = %CardIcon
@onready var _card_name: Label = %CardName
@onready var _hint_label: Label = %Hint
@onready var _title_sound: AudioStreamPlayer = $TitleSound
@onready var _click_sound: AudioStreamPlayer = $ClickSound


func _ready() -> void:
	add_to_group(&"hud")
	for control: CanvasItem in [_message, _reply, _title, _card, _hint_label]:
		control.visible = false
	_pause_button.pressed.connect(func() -> void:
		_click_sound.play()
		get_tree().call_group(&"pause_menu", &"open"))
	Game.night_started.connect(_on_night_started)
	Game.drum_picked.connect(_on_drum_picked)
	Game.drum_dropped.connect(_on_drum_dropped)
	Game.drum_returned.connect(func(_count: int) -> void: _rebuild_drums())
	Game.sanctuary_freed.connect(func() -> void: show_title("", GameTexts.TITLE_SANCTUARY_FREED))
	Game.night_completed.connect(_on_night_completed)
	Game.muet_freed.connect(_on_muet_freed)
	Game.page_found.connect(func(_page: int) -> void: show_message(GameTexts.MESSAGE_PAGE_FOUND))
	Game.item_found.connect(show_item)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_rebuild_drums()


func _process(delta: float) -> void:
	_time += delta
	if _hero == null:
		_find_hero()
	if _hero:
		_health_bar.set_fraction(_hero.health.current / _hero.health.maximum)
	_update_message(delta)
	_update_hint()
	_pulse_carried_drum()


## Message éphémère en haut de l'écran (remplace le précédent, sauf une information par une
## réplique). Pendant un grand titre, il attend la fin du titre.
func show_message(text: String, priority: Priority = Priority.INFO) -> void:
	if _title_active:
		_pending_message = text
		return
	if not _can_replace(priority):
		return
	_start_message(_message, text, priority, Tuning.data.message_time)
	_reply_source = null


## Réplique près de sa source (un Muet libéré, le Chef), `height` mètres au-dessus de ses pieds.
func show_reply(text: String, source: Node3D, height: float, duration: float, priority: Priority = Priority.REPLY) -> void:
	if not _can_replace(priority):
		return
	_reply_source = source
	_reply_point = source.global_position
	_reply_height = height
	_start_message(_reply, text, priority, duration)
	_place_reply()


## Grand titre : un petit surtitre (facultatif) et le titre.
func show_title(over_title: String, title: String) -> void:
	_title_active = true
	_message.visible = false
	_over_title.text = over_title
	_over_title.visible = over_title != ""
	_title_text.text = title
	_title.visible = true
	_title.modulate.a = 0.0
	_title_sound.play()
	var tuning: TuningData = Tuning.data
	var tween: Tween = create_tween()
	tween.tween_property(_title, "modulate:a", 1.0, tuning.title_fade_in_time)
	tween.tween_interval(tuning.title_hold_time)
	tween.tween_property(_title, "modulate:a", 0.0, tuning.title_fade_out_time)
	tween.tween_callback(_end_title)


## Durée totale d'un grand titre (s).
static func title_duration(tuning: TuningData) -> float:
	return tuning.title_fade_in_time + tuning.title_hold_time + tuning.title_fade_out_time


func is_title_active() -> bool:
	return _title_active


## Texte du message éphémère affiché (vide s'il n'y en a pas).
func current_message() -> String:
	if _message_left <= 0.0:
		return ""
	return _message_label.text


## Carte de l'objet trouvé, en bas, pendant loot_card_time.
func show_item(item: ItemData) -> void:
	_card_icon.texture = slot_icons[item.slot]
	_card_icon.modulate = rarity_colors[item.rarity]
	_card_name.text = GameTexts.item_name(item)
	_card_name.modulate = rarity_colors[item.rarity].lerp(Color.WHITE, 0.5)
	_card.visible = true
	_card.modulate.a = 0.0
	if _card_tween:
		_card_tween.kill()
	var tuning: TuningData = Tuning.data
	_card_tween = create_tween()
	_card_tween.tween_property(_card, "modulate:a", 1.0, tuning.message_fade_time)
	_card_tween.tween_interval(tuning.loot_card_time)
	_card_tween.tween_property(_card, "modulate:a", 0.0, tuning.message_fade_time)
	_card_tween.tween_callback(_card.hide)


## Aide contextuelle : le bouton de `action` brille, avec `text` au-dessus.
func show_hint(hint: StringName, action: StringName, text: String) -> void:
	if _title_active:
		_pending_hint = [hint, action, text]
		return
	_clear_hint()
	_hint = hint
	_hint_action = action
	_hint_label.text = text
	_hint_label.visible = true
	_controls_call(&"highlight", [action, true])


func hide_hint(hint: StringName) -> void:
	if not _pending_hint.is_empty() and _pending_hint[0] == hint:
		_pending_hint = []
	if _hint == hint:
		_clear_hint()


## Aide affichée (vide s'il n'y en a pas).
func current_hint() -> StringName:
	return _hint


func _can_replace(priority: Priority) -> bool:
	return _message_left <= 0.0 or priority >= _message_priority


func _start_message(label: Label, text: String, priority: Priority, duration: float) -> void:
	_message.visible = false
	_reply.visible = false
	_message_label = label
	_message_priority = priority
	_message_time = duration
	_message_left = duration
	label.text = text
	label.modulate.a = 0.0
	label.visible = true


func _update_message(delta: float) -> void:
	if _message_left <= 0.0:
		return
	_message_left -= delta
	var fade: float = Tuning.data.message_fade_time
	var shown: float = _message_time - _message_left
	_message_label.modulate.a = clampf(minf(shown, _message_left) / fade, 0.0, 1.0)
	if _message_label == _reply:
		_place_reply()
	if _message_left <= 0.0:
		_message_label.visible = false


func _place_reply() -> void:
	if is_instance_valid(_reply_source):
		_reply_point = _reply_source.global_position
	var camera: Camera3D = _reply.get_viewport().get_camera_3d()
	if camera == null:
		return
	var world: Vector3 = _reply_point + Vector3.UP * _reply_height
	if camera.is_position_behind(world):
		_reply.visible = false
		return
	var point: Vector2 = camera.unproject_position(world)
	var screen: Vector2 = _reply.get_viewport_rect().size
	var margin: float = reply_offscreen_margin
	_reply.visible = point.x > -margin and point.x < screen.x + margin and point.y > 0.0 and point.y < screen.y + margin
	if not _reply.visible:
		return
	_reply.size = Vector2(reply_width, 0.0)
	_reply.size = Vector2(reply_width, _reply.get_combined_minimum_size().y)
	# Jamais sur la barre du haut (PV, tambours, pause) : au plus haut, à la place des messages.
	var top: float = _message.get_global_rect().position.y
	_reply.position = _clamp_to_screen(point - Vector2(_reply.size.x / 2.0, _reply.size.y), _reply.size, top)


func _clamp_to_screen(position: Vector2, size: Vector2, top: float) -> Vector2:
	var screen: Vector2 = _reply.get_viewport_rect().size
	return Vector2(
		clampf(position.x, screen_margin, maxf(screen_margin, screen.x - size.x - screen_margin)),
		clampf(position.y, top, maxf(top, screen.y - size.y - screen_margin)))


## Place la carte d'objet selon l'orientation de l'écran.
func _layout() -> void:
	var height: float = card_bottom_portrait if CameraRig.is_portrait(_card.get_viewport_rect().size) else card_bottom_landscape
	var card_height: float = _card.offset_bottom - _card.offset_top
	_card.offset_bottom = -height
	_card.offset_top = -height - card_height


func _end_title() -> void:
	_title.visible = false
	_title_active = false
	if _pending_message != "":
		show_message(_pending_message)
		_pending_message = ""
	if not _pending_hint.is_empty():
		var pending: Array = _pending_hint
		_pending_hint = []
		show_hint(pending[0], pending[1], pending[2])
	title_finished.emit()


func _update_hint() -> void:
	if _hint == &"":
		return
	if _hint_action == TouchControls.MOVE and _hero:
		var running: Vector3 = Vector3(_hero.velocity.x, 0.0, _hero.velocity.z)
		if running.length() > Tuning.data.hint_move_speed:
			_complete_hint()
			return
	var anchor: Variant = _controls_call(&"hint_anchor", [_hint_action])
	if anchor is Vector2:
		_hint_label.reset_size()
		var top_left: Vector2 = anchor - Vector2(_hint_label.size.x / 2.0, _hint_label.size.y)
		_hint_label.position = _clamp_to_screen(top_left, _hint_label.size, screen_margin)


func _complete_hint() -> void:
	Game.mark_hint_done(_hint)
	_clear_hint()


func _clear_hint() -> void:
	if _hint_action != &"":
		_controls_call(&"highlight", [_hint_action, false])
	_hint = &""
	_hint_action = &""
	_hint_label.visible = false


func _controls_call(method: StringName, arguments: Array) -> Variant:
	var controls: Node = get_tree().get_first_node_in_group(&"touch_controls")
	if controls == null:
		return null
	return controls.callv(method, arguments)


func _find_hero() -> void:
	_hero = get_tree().get_first_node_in_group(&"hero") as Hero
	if _hero:
		_hero.hit_landed.connect(_on_hit_landed)
		_hero.hurtbox.hurt.connect(_on_hero_hurt)
		_hero.action_pressed.connect(_on_action_pressed)


func _on_action_pressed(action: StringName) -> void:
	if _hint != &"" and action == _hint_action:
		_complete_hint()


func _on_hit_landed(hit: HitData) -> void:
	if not Game.profile.damage_numbers or hit.target == null or hit.target.health == null:
		return
	var number: DamageNumber = damage_number_scene.instantiate() as DamageNumber
	_hero.get_parent().add_child(number)
	number.global_position = hit.point + Vector3.UP * damage_number_height
	number.play(hit.damage, hit.critical)


## PV perdus par le héros, en rose au-dessus de lui.
func _on_hero_hurt(hit: HitData) -> void:
	if not Game.profile.damage_numbers:
		return
	var number: DamageNumber = damage_number_scene.instantiate() as DamageNumber
	_hero.get_parent().add_child(number)
	number.global_position = _hero.global_position + Vector3.UP * (Tuning.data.hero_height + damage_number_height)
	number.play(hit.damage, false, true)


func _on_night_started(night: int) -> void:
	_rebuild_drums()
	show_title(GameTexts.NIGHT_LABEL % night, GameTexts.night_name(night))
	await title_finished
	var chief: Node3D = get_tree().get_first_node_in_group(&"chief") as Node3D
	if chief and GameTexts.CHIEF_NIGHT_START.has(night):
		chief.call(&"greet")
		var tuning: TuningData = Tuning.data
		show_reply(GameTexts.CHIEF_NIGHT_START[night], chief, tuning.chief_height + tuning.reply_gap, tuning.chief_line_time, Priority.INFO)


func _on_drum_picked() -> void:
	_rebuild_drums()
	show_message(GameTexts.MESSAGE_DRUM_PICKED)


func _on_drum_dropped() -> void:
	_rebuild_drums()
	show_message(GameTexts.MESSAGE_DRUM_LOST)


func _on_night_completed() -> void:
	show_title(GameTexts.NIGHT_LABEL % Game.night, GameTexts.TITLE_NIGHT_COMPLETE)
	get_tree().create_timer(Tuning.data.end_screen_delay, false).timeout.connect(
		func() -> void: get_tree().call_group(&"end_screen", &"open"))


func _on_muet_freed(muet: Node3D) -> void:
	var lines: PackedStringArray = GameTexts.MUET_FREED_LINES
	var tuning: TuningData = Tuning.data
	var body: MuetBody = muet.get_node_or_null(^"Body") as MuetBody
	var height: float = body.height if body else 0.0
	show_reply(lines[_reply_index % lines.size()], muet, height + tuning.reply_gap, tuning.reply_time)
	_reply_index += 1


## Un pictogramme par tambour à rapporter : plein s'il est rapporté.
func _rebuild_drums() -> void:
	for child: Node in _drums.get_children():
		child.queue_free()
	for i: int in Game.progress.drums_required:
		var icon := TextureRect.new()
		icon.texture = drum_icon if i < Game.progress.drums_returned else drum_empty_icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2.ONE * drum_icon_size
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_drums.add_child(icon)


## Le tambour qu'on rapporte bat dans sa case, au rythme des aides.
func _pulse_carried_drum() -> void:
	var slot: int = Game.progress.drums_returned
	if slot >= _drums.get_child_count():
		return
	var icon: TextureRect = _drums.get_child(slot) as TextureRect
	if icon.is_queued_for_deletion():
		return
	if Game.progress.carrying_drum:
		icon.texture = drum_icon
		icon.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(TAU * _time / Tuning.data.hint_pulse_period))
	else:
		icon.texture = drum_empty_icon
		icon.modulate.a = 1.0
