class_name Hud
extends CanvasLayer
## Interface en jeu du prototype :
## - en haut : niveau, PV et expérience ; tambours rapportés et bouton de pause (il brille quand un
##   point de talent ou un objet nouveau attend) ; objectif (il bat quand il change) ; barre du
##   Grand Muet qui se bat ;
## - combo à droite ; repère de l'objectif (au bord de l'écran s'il est hors champ, avec la
##   distance) ;
## - bannières au centre (une à la fois, les suivantes attendent), message court sous l'objectif,
##   conseil près du bouton à utiliser, bulle au-dessus de qui parle ;
## - voile rose quand le héros est touché ; chiffres de dégâts discrets et désactivables.

## Couleur de chaque rareté (commun, rare, épique, légendaire), pictogramme de chaque emplacement
## (carte de l'objet trouvé) ; pictogramme et couleur de la carte d'une page du carnet.
@export var rarity_colors: Array[Color]
@export var page_icon: Texture2D
@export var page_color: Color
@export var slot_icons: Array[Texture2D]
## Icônes de l'objectif : village, tambour, sanctuaire, nuit accomplie.
@export var quest_icons: Dictionary[StringName, Texture2D]
@export var damage_number_scene: PackedScene
## Écart minimal entre un texte et les bords de l'écran (px).
@export var screen_margin: float
## Hauteur du point d'impact où apparaît un chiffre de dégâts (m, au-dessus du contact).
@export var damage_number_height: float
## Repère : marge sur les côtés, espace laissé sous le haut de l'interface, en bas en portrait et en
## paysage (px) ; hauteur visée au-dessus de l'objectif, et du village (m) ; caché plus près que (m).
@export var marker_side: float
@export var marker_top_gap: float
@export var marker_bottom_portrait: float
@export var marker_bottom_landscape: float
@export var marker_height: float
@export var marker_home_height: float
@export var marker_min_distance: float
## Écart entre le haut de l'interface et les messages (bannière, message court) (px).
@export var message_gap: float
## Bulle : écart sous le haut de l'interface (px) ; marge hors écran avant de la cacher (px).
@export var bubble_top_gap: float
@export var bubble_offscreen: float
## Conseil : écart au-dessus du bouton (px) ; place pour le conseil « courir » (fraction de la
## largeur, px depuis le bas).
@export var coach_gap: float
@export var coach_move_x: float
@export var coach_move_bottom: float
## Le conseil flotte doucement : hauteur (px), durée d'un aller-retour (s).
@export var coach_bob_height: float
@export var coach_bob_period: float
## Largeur au plus d'une bulle (px), d'un message, d'un conseil, d'une bannière, de l'objectif
## (fraction de l'écran).
@export var bubble_max_width: float
@export var toast_max_fraction: float
@export var coach_max_fraction: float
@export var banner_max_fraction: float
@export var quest_max_fraction: float
## Combo : à partir de combien il s'affiche, et devient doré.
@export var combo_min: int
@export var combo_hot: int
## Barre du Grand Muet : visible à moins de (m).
@export var boss_bar_range: float
## Expérience mise de côté pendant la sortie (elle s'ajoute au village) : couleur de sa part de la
## barre, qui bat doucement.
@export var xp_carry_color: Color

var _hero: Hero
var _night: VoxelNight
var _banners: Array[PackedStringArray] = []
var _banner_busy: bool = false
var _toast_left: float = 0.0
var _bubble_left: float = 0.0
var _bubble_source: Node3D
var _bubble_height: float = 0.0
var _coach_action: StringName = &""
var _hint: StringName = &""
var _quest_key: String = ""
var _combo_shown: int = 0
var _time: float = 0.0
var _reply_index: int = 0
## Valeurs affichées (on ne réécrit un texte que s'il change).
var _shown_level: int = -1
var _shown_health := Vector2i(-1, -1)
var _shown_drums: String = ""
var _shown_boss: Muet
var _attention_left: float = 0.0
var _card_tween: Tween

@onready var _safe: Control = $SafeArea
@onready var _top: VBoxContainer = %Top
@onready var _level: Label = %LevelLabel
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _hp_text: Label = %HpText
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _xp_carry: ColorRect = %XpCarry
@onready var _drums: Array[PanelContainer] = [%Drum1, %Drum2, %Drum3]
@onready var _pause_button: Button = %PauseButton
@onready var _quest: PanelContainer = %Quest
@onready var _quest_icon: TextureRect = %QuestIcon
@onready var _quest_title: Label = %QuestTitle
@onready var _quest_sub: Label = %QuestSub
@onready var _boss: Control = %Boss
@onready var _boss_name: Label = %BossName
@onready var _boss_bar: ProgressBar = %BossBar
@onready var _combo: Control = %Combo
@onready var _combo_number: Label = %ComboNumber
@onready var _marker: Control = %Marker
@onready var _marker_arrow: Control = %MarkerArrow
@onready var _marker_label: Label = %MarkerLabel
@onready var _banner: Control = %Banner
@onready var _banner_small: Label = %BannerSmall
@onready var _banner_title: Label = %BannerTitle
@onready var _banner_detail: Label = %BannerDetail
@onready var _toast: PanelContainer = %Toast
@onready var _toast_label: Label = %ToastLabel
@onready var _coach: PanelContainer = %Coach
@onready var _coach_label: Label = %CoachLabel
@onready var _bubble: PanelContainer = %Bubble
@onready var _bubble_label: Label = %BubbleLabel
@onready var _flash: CanvasItem = %Flash
@onready var _card: PanelContainer = %LootCard
@onready var _card_icon: TextureRect = %CardIcon
@onready var _card_name: Label = %CardName
@onready var _level_chip: Control = %LevelChip
@onready var _banner_sound: AudioStreamPlayer = $BannerSound
@onready var _click_sound: AudioStreamPlayer = $ClickSound


func _ready() -> void:
	add_to_group(&"hud")
	for control: CanvasItem in [_banner, _toast, _coach, _bubble, _marker, _boss, _combo, _flash, _card]:
		control.visible = false
	_pause_button.pressed.connect(func() -> void:
		_click_sound.play()
		get_tree().call_group(&"pause_menu", &"open"))
	Game.sanctuary_freed.connect(func() -> void:
		show_banner(GameTexts.BANNER_SANCTUARY, GameTexts.BANNER_SANCTUARY_TITLE, GameTexts.BANNER_SANCTUARY_DETAIL))
	Game.item_found.connect(_on_item_found)
	Game.page_found.connect(_on_page_found)
	Game.level_up.connect(func(_level: int) -> void: _pulse_level())
	Game.sortie_started.connect(func() -> void: _quest_key = "")
	get_viewport().size_changed.connect(_layout)
	_layout()


func _process(delta: float) -> void:
	_time += delta
	if _hero == null:
		_find_hero()
	if _night == null:
		_night = get_tree().get_first_node_in_group(&"night_level") as VoxelNight
	if not visible:
		return
	_update_me()
	_update_quest()
	_update_boss()
	_update_combo()
	_update_marker()
	_update_toast(delta)
	_update_bubble(delta)
	_update_coach()
	_attention_left -= delta
	if _attention_left <= 0.0:
		_attention_left = Tuning.data.hud_slow_refresh
		_pause_button.theme_type_variation = &"IconBadge" if _needs_attention() else &"IconButton"


## Bannière au centre : surtitre, titre, précision ; `chime` : elle sonne. Une à la fois ; au plus
## trois attendent.
func show_banner(small: String, title: String, detail: String = "", chime: bool = true) -> void:
	if _banners.size() >= Tuning.data.banner_queue_max:
		_banners.pop_front()
	_banners.append(PackedStringArray([small, title, detail, "1" if chime else ""]))
	if not _banner_busy:
		_next_banner()


## Bannière affichée (vide s'il n'y en a pas).
func current_banner() -> String:
	return _banner_title.text if _banner.visible else ""


## Message court sous l'objectif.
func show_toast(text: String, duration: float = -1.0) -> void:
	_toast_label.text = text
	_fit(_toast_label, _view_width() * toast_max_fraction)
	_toast_left = duration if duration > 0.0 else Tuning.data.toast_time
	_toast.visible = true
	_toast.modulate.a = 0.0


func current_toast() -> String:
	return _toast_label.text if _toast_left > 0.0 else ""


## Bulle au-dessus de `source` (un villageois, le Chef, un Muet libéré), `height` m au-dessus de
## ses pieds.
func show_bubble(text: String, source: Node3D, height: float) -> void:
	_bubble_label.text = text
	_fit(_bubble_label, bubble_max_width)
	_bubble_source = source
	_bubble_height = height
	_bubble_left = Tuning.data.bubble_time
	_bubble.visible = true
	_bubble.reset_size()
	_place_bubble()


func current_bubble() -> String:
	return _bubble_label.text if _bubble_left > 0.0 else ""


## Conseil près du bouton de `action` (« move » : près du joystick), qui brille.
func show_coach(text: String, action: StringName) -> void:
	hide_coach()
	_coach_action = action
	_coach_label.text = text
	_fit(_coach_label, _view_width() * coach_max_fraction)
	_coach.visible = true
	_coach.reset_size()
	_controls_call(&"highlight", [action, true])
	_update_coach()


func hide_coach() -> void:
	if _coach_action != &"":
		_controls_call(&"highlight", [_coach_action, false])
	_coach_action = &""
	_hint = &""
	_coach.visible = false


## Conseil affiché (vide s'il n'y en a pas).
func current_coach() -> String:
	return _coach_label.text if _coach.visible else ""


## Aide d'une zone (parcours d'essai) : un conseil qui s'en va dès que l'action est faite.
func show_hint(hint: StringName, action: StringName, text: String) -> void:
	show_coach(text, action)
	_hint = hint


func hide_hint(hint: StringName) -> void:
	if _hint == hint:
		hide_coach()


func current_hint() -> StringName:
	return _hint


## Niveau, PV, expérience, tambours (les textes ne changent que si les valeurs changent).
func _update_me() -> void:
	var profile: Profile = Game.profile
	if profile.level != _shown_level:
		_shown_level = profile.level
		_level.text = GameTexts.LEVEL_CHIP % profile.level
	if _hero:
		var health := Vector2i(ceili(maxf(_hero.health.current, 0.0)), roundi(_hero.health.maximum))
		if health != _shown_health:
			_shown_health = health
			_hp_bar.max_value = health.y
			_hp_bar.value = health.x
			_hp_text.text = GameTexts.HEALTH % [health.x, health.y]
	_update_xp()
	var progress: NightProgress = Game.progress
	var drums: String = "%s%s" % [progress.returned, progress.carrying]
	if drums != _shown_drums:
		_shown_drums = drums
		for i: int in _drums.size():
			var on: bool = (i < progress.returned.size() and progress.returned[i]) or progress.carrying.has(i)
			_drums[i].theme_type_variation = &"DrumOn" if on else &"DrumOff"
			_drums[i].modulate.a = 1.0
	if progress.carrying_drum:
		var pulse: float = 0.5 + 0.5 * sin(TAU * _time / Tuning.data.hint_pulse_period)
		for i: int in progress.carrying:
			if i < _drums.size():
				_drums[i].modulate.a = lerpf(Tuning.data.drum_pulse_min_alpha, 1.0, pulse)


## Barre d'expérience : la part gagnée, puis celle mise de côté pendant la sortie (elle bat : il
## faut la rapporter au village) ; assez pour un niveau, la pastille du niveau bat aussi.
func _update_xp() -> void:
	var profile: Profile = Game.profile
	var needed: float = ProgressionMath.xp_needed(profile.level, Tuning.data)
	var gained: float = profile.xp / needed
	var carried: float = minf(Game.progress.xp_carried / needed, 1.0 - gained)
	_xp_bar.value = gained
	_xp_carry.visible = carried > 0.0
	if not _xp_carry.visible:
		_level_chip.modulate.a = 1.0
		return
	var width: float = _xp_bar.size.x
	_xp_carry.position = Vector2(width * gained, 0.0)
	_xp_carry.size = Vector2(width * carried, _xp_bar.size.y)
	var pulse: float = 0.5 + 0.5 * sin(TAU * _time / Tuning.data.hint_pulse_period)
	_xp_carry.color = Color(xp_carry_color, lerpf(Tuning.data.drum_pulse_min_alpha, 1.0, pulse) * xp_carry_color.a)
	var level_ready: bool = profile.xp + Game.progress.xp_carried >= needed
	_level_chip.modulate.a = lerpf(Tuning.data.drum_pulse_min_alpha, 1.0, pulse) if level_ready else 1.0


## Objectif : il bat quand il change ; pendant une sortie, une bannière l'annonce.
func _update_quest() -> void:
	var goal: Dictionary = _goal()
	var key: String = String(goal.get(&"title", GameTexts.QUEST_WON))
	if key != _quest_key:
		_quest_key = key
		_quest_icon.texture = quest_icons[goal.get(&"icon", &"won")]
		_quest_title.text = key
		_quest_sub.text = String(goal.get(&"sub", GameTexts.QUEST_WON_SUB))
		_fit(_quest_title, _view_width() * quest_max_fraction)
		_fit(_quest_sub, _view_width() * quest_max_fraction)
		_pulse_quest()


## Objectif du moment (vide hors sortie ou nuit accomplie).
func _goal() -> Dictionary:
	return _night.current_goal() if _night and _night.in_sortie else {}


func _pulse_quest() -> void:
	var tuning: TuningData = Tuning.data
	_quest.pivot_offset = _quest.size / 2.0
	_quest.theme_type_variation = &"QuestFlash"
	var tween: Tween = create_tween()
	for i: int in tuning.quest_pulses:
		tween.tween_property(_quest, "scale", Vector2.ONE * tuning.quest_pulse_scale, tuning.quest_pulse_time * tuning.quest_pulse_rise)
		tween.tween_property(_quest, "scale", Vector2.ONE, tuning.quest_pulse_time * (1.0 - tuning.quest_pulse_rise))
	tween.tween_callback(func() -> void: _quest.theme_type_variation = &"QuestPanel")


## Barre du Grand Muet qui se bat contre le héros.
func _update_boss() -> void:
	var fighting: Muet = null
	if _hero:
		for node: Node in get_tree().get_nodes_in_group(&"bosses"):
			var boss: Muet = node as Muet
			if boss.target != null and not boss.is_freed() and boss.global_position.distance_to(_hero.global_position) < boss_bar_range:
				fighting = boss
				break
	_boss.visible = fighting != null
	if fighting:
		if fighting != _shown_boss:
			_shown_boss = fighting
			_boss_name.text = fighting.display_name
		_boss_bar.max_value = fighting.health.maximum
		_boss_bar.value = fighting.health.current


func _update_combo() -> void:
	var hits: int = _hero.combo.hits if _hero else 0
	_combo.visible = hits >= combo_min
	if hits == _combo_shown:
		return
	var grew: bool = hits > _combo_shown
	_combo_shown = hits
	if not _combo.visible:
		return
	_combo_number.text = str(hits)
	_combo_number.theme_type_variation = &"ComboHot" if hits >= combo_hot else &"ComboNumber"
	if grew:
		var tuning: TuningData = Tuning.data
		_combo_number.pivot_offset = _combo_number.size / 2.0
		_combo_number.scale = Vector2.ONE * tuning.combo_pop_scale
		create_tween().tween_property(_combo_number, "scale", Vector2.ONE, tuning.combo_pop_time).set_ease(Tween.EASE_OUT)


## Repère de l'objectif : au-dessus de lui s'il est à l'écran, sinon au bord, pointé vers lui.
func _update_marker() -> void:
	var goal: Dictionary = _goal()
	var camera: Camera3D = get_viewport().get_camera_3d()
	if goal.is_empty() or _hero == null or camera == null:
		_marker.visible = false
		return
	var point: Vector3 = goal[&"point"]
	var distance: float = Vector2(point.x - _hero.global_position.x, point.z - _hero.global_position.z).length()
	if distance < marker_min_distance:
		_marker.visible = false
		return
	_marker.visible = true
	var target: Vector3 = point + Vector3.UP * (marker_home_height if goal[&"kind"] == &"return" else marker_height)
	var behind: bool = camera.is_position_behind(target)
	var screen: Vector2 = camera.unproject_position(target)
	var view: Vector2 = get_viewport().get_visible_rect().size
	var top: float = _top.get_global_rect().end.y + marker_top_gap
	var bottom: float = view.y - (marker_bottom_portrait if CameraRig.is_portrait(view) else marker_bottom_landscape)
	var inside: bool = not behind and screen.x > marker_side and screen.x < view.x - marker_side and screen.y > top and screen.y < bottom
	var angle: float = 0.0
	if not inside:
		var center := Vector2(view.x / 2.0, (top + bottom) / 2.0)
		var toward: Vector2 = screen - center
		if behind:
			toward = -toward
		var kx: float = (view.x / 2.0 - marker_side) / maxf(0.001, absf(toward.x))
		var ky: float = ((center.y - top) if toward.y < 0.0 else (bottom - center.y)) / maxf(0.001, absf(toward.y))
		screen = center + toward * minf(kx, ky)
		angle = toward.angle() - PI / 2.0
	_marker.position = screen - Vector2(_marker.size.x / 2.0, _marker.size.y)
	_marker_arrow.pivot_offset = _marker_arrow.size / 2.0
	_marker_arrow.rotation = angle
	_marker_label.text = GameTexts.MARKER_DISTANCE % (roundi(distance / Tuning.data.marker_distance_step) * Tuning.data.marker_distance_step)


func _update_toast(delta: float) -> void:
	if _toast_left <= 0.0:
		return
	var tuning: TuningData = Tuning.data
	_toast_left -= delta
	_toast.modulate.a = clampf(minf(_toast.modulate.a + delta / tuning.message_fade_time, _toast_left / tuning.message_fade_time), 0.0, 1.0)
	_toast.reset_size()
	_toast.position = Vector2((_safe.size.x - _toast.size.x) / 2.0, _message_top())
	if _toast_left <= 0.0:
		_toast.visible = false


func _update_bubble(delta: float) -> void:
	if _bubble_left <= 0.0:
		return
	_bubble_left -= delta
	if _bubble_left <= 0.0 or not is_instance_valid(_bubble_source):
		_bubble_left = 0.0
		_bubble.visible = false
		return
	_place_bubble()


func _place_bubble() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or not is_instance_valid(_bubble_source):
		return
	var world: Vector3 = _bubble_source.global_position + Vector3.UP * _bubble_height
	var view: Vector2 = get_viewport().get_visible_rect().size
	var point: Vector2 = camera.unproject_position(world)
	var shown: bool = not camera.is_position_behind(world) and point.x > -bubble_offscreen and point.x < view.x + bubble_offscreen \
		and point.y > 0.0 and point.y < view.y + bubble_offscreen
	_bubble.modulate.a = 1.0 if shown else 0.0
	_bubble.reset_size()
	var size: Vector2 = _bubble.size
	var top: float = _top.get_global_rect().end.y + bubble_top_gap
	_bubble.position = Vector2(
		clampf(point.x - size.x / 2.0, screen_margin, maxf(screen_margin, view.x - size.x - screen_margin)),
		clampf(point.y - size.y, top, maxf(top, view.y - size.y - screen_margin)))


## Le conseil se place au-dessus de son bouton (ou du joystick) ; un conseil de zone s'en va dès
## que le héros court.
func _update_coach() -> void:
	if _coach_action == &"":
		return
	if _hint != &"" and _coach_action == TouchControls.MOVE and _hero and Vector2(_hero.velocity.x, _hero.velocity.z).length() > Tuning.data.hint_move_speed:
		_complete_hint()
		return
	var view: Vector2 = get_viewport().get_visible_rect().size
	_coach.reset_size()
	var size: Vector2 = _coach.size
	var anchor := Vector2(view.x * coach_move_x, view.y - coach_move_bottom)
	var rect: Variant = _controls_call(&"button_rect", [_coach_action])
	var pad: Variant = _controls_call(&"pad_rect", [])
	if rect is Rect2 and (rect as Rect2).has_area() and pad is Rect2:
		anchor = Vector2((rect as Rect2).get_center().x, (pad as Rect2).position.y - coach_gap)
	var bob: float = sin(TAU * _time / coach_bob_period) * coach_bob_height
	_coach.position = Vector2(clampf(anchor.x - size.x / 2.0, screen_margin, maxf(screen_margin, view.x - size.x - screen_margin)), anchor.y - size.y + bob)


func _complete_hint() -> void:
	if _hint != &"":
		Game.mark_hint_done(_hint)
	hide_coach()


func _next_banner() -> void:
	if _banners.is_empty():
		_banner_busy = false
		_banner.visible = false
		return
	var tuning: TuningData = Tuning.data
	var entry: PackedStringArray = _banners.pop_front()
	_banner_busy = true
	_banner_small.text = entry[0]
	_banner_title.text = entry[1]
	_banner_detail.text = entry[2]
	_banner_small.visible = entry[0] != ""
	_banner_detail.visible = entry[2] != ""
	for label: Label in [_banner_small, _banner_title, _banner_detail]:
		_fit(label, _view_width() * banner_max_fraction)
	_banner.visible = true
	_banner.reset_size()
	_banner.position = Vector2((_safe.size.x - _banner.size.x) / 2.0, _message_top() + (_toast.size.y + message_gap if _toast.visible else 0.0))
	_banner.pivot_offset = _banner.size / 2.0
	_banner.scale = Vector2.ONE * tuning.banner_start_scale
	_banner.modulate.a = 0.0
	if entry[3] != "":
		_banner_sound.play()
	var total: float = tuning.banner_time
	var rise: float = _banner.position.y - _banner.size.y * tuning.banner_rise
	var tween: Tween = create_tween()
	tween.tween_property(_banner, "modulate:a", 1.0, total * tuning.banner_in)
	tween.parallel().tween_property(_banner, "scale", Vector2.ONE * tuning.banner_peak_scale, total * tuning.banner_in)
	tween.tween_property(_banner, "scale", Vector2.ONE, total * tuning.banner_settle)
	tween.tween_interval(total * (tuning.banner_out - tuning.banner_in - tuning.banner_settle))
	tween.tween_property(_banner, "modulate:a", 0.0, total * (1.0 - tuning.banner_out))
	tween.parallel().tween_property(_banner, "position:y", rise, total * (1.0 - tuning.banner_out))
	get_tree().create_timer(tuning.banner_gap, false).timeout.connect(_next_banner)


## Un point de talent à dépenser, ou un objet pas encore regardé.
func _needs_attention() -> bool:
	if Game.profile.talent_points > 0:
		return true
	for item: ItemData in Game.profile.items:
		if item.is_new:
			return true
	return false


## En paysage, l'objectif se range à gauche et perd sa précision (comme dans le prototype).
func _layout() -> void:
	var portrait: bool = CameraRig.is_portrait(get_viewport().get_visible_rect().size)
	_quest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if portrait else Control.SIZE_SHRINK_BEGIN
	_quest_sub.visible = portrait


## Haut de la place des messages : sous l'objectif et la barre du Grand Muet.
func _message_top() -> float:
	return _top.get_global_rect().end.y - _safe.get_global_rect().position.y + message_gap


## Le texte passe à la ligne s'il dépasse `max_width` (px).
func _fit(label: Label, max_width: float) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.custom_minimum_size.x = 0.0
	var font: Font = label.get_theme_font(&"font")
	var font_size: int = label.get_theme_font_size(&"font_size")
	if font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = max_width
	label.reset_size()


func _view_width() -> float:
	return get_viewport().get_visible_rect().size.x


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
		_hero.second_wind.connect(func() -> void: show_toast(GameTexts.TOAST_SECOND_WIND))


func _on_action_pressed(action: StringName) -> void:
	if _hint != &"" and action == _coach_action:
		_complete_hint()


func _on_hit_landed(hit: HitData) -> void:
	if not Game.profile.damage_numbers or hit.target == null or hit.target.health == null:
		return
	var number: DamageNumber = damage_number_scene.instantiate() as DamageNumber
	_hero.get_parent().add_child(number)
	number.global_position = hit.point + Vector3.UP * damage_number_height
	number.play(hit.damage, hit.critical)


## Le héros est touché : voile rose (la barre de PV dit le reste).
func _on_hero_hurt(_hit: HitData) -> void:
	var tuning: TuningData = Tuning.data
	_flash.visible = true
	_flash.modulate.a = 1.0
	create_tween().tween_property(_flash, "modulate:a", 0.0, tuning.hurt_flash_time)


## Objet trouvé : petite carte en bas (charte des retours à l'écran).
func _on_item_found(item: ItemData) -> void:
	_show_card(slot_icons[item.slot], GameTexts.item_name(item), rarity_colors[item.rarity])


## Page du carnet trouvée : petite carte en bas.
func _on_page_found(page: int) -> void:
	_show_card(page_icon, GameTexts.PAGE_FOUND % page, page_color)


## Petite carte en bas, au-dessus des boutons, pendant un moment.
func _show_card(icon: Texture2D, text: String, color: Color) -> void:
	var tuning: TuningData = Tuning.data
	_card_icon.texture = icon
	_card_name.text = text
	_card_name.modulate = color
	_card.visible = true
	_card.modulate.a = 0.0
	_card.reset_size()
	var view: Vector2 = get_viewport().get_visible_rect().size
	var pad: Variant = _controls_call(&"pad_rect", [])
	var bottom: float = (pad as Rect2).position.y if pad is Rect2 and (pad as Rect2).has_area() else view.y
	_card.position = Vector2((view.x - _card.size.x) / 2.0, bottom - _card.size.y - coach_gap)
	if _card_tween:
		_card_tween.kill()
	_card_tween = create_tween()
	_card_tween.tween_property(_card, "modulate:a", 1.0, tuning.message_fade_time)
	_card_tween.tween_interval(tuning.loot_card_time)
	_card_tween.tween_property(_card, "modulate:a", 0.0, tuning.message_fade_time)
	_card_tween.tween_callback(_card.hide)


## Niveau gagné : la pastille du niveau bat (le monde fait le reste : gerbe et anneau).
func _pulse_level() -> void:
	var tuning: TuningData = Tuning.data
	_level_chip.pivot_offset = _level_chip.size / 2.0
	var tween: Tween = create_tween()
	for i: int in tuning.quest_pulses:
		tween.tween_property(_level_chip, "scale", Vector2.ONE * tuning.level_pulse_scale, tuning.quest_pulse_time * tuning.quest_pulse_rise)
		tween.tween_property(_level_chip, "scale", Vector2.ONE, tuning.quest_pulse_time * (1.0 - tuning.quest_pulse_rise))
