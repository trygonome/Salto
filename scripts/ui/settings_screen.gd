class_name SettingsScreen
extends ScreenLayer
## Réglages (version 3.3, un onglet du menu) : son, vibrations, chiffres de dégâts, infos techniques
## (versions de test) ; depuis la version 4.2.1, « Copier le journal » (résumé des dernières parties).

@onready var _sound: Button = %Sound
@onready var _vibration: Button = %Vibration
@onready var _damage: Button = %DamageNumbers
@onready var _debug: Button = %DebugInfo
@onready var _journal: Button = %Journal

var _copied_left: float = 0.0


func _ready() -> void:
	super()
	add_to_group(&"settings_screen")
	%Title.text = GameTexts.SETTINGS_TITLE
	%Sub.text = GameTexts.SETTINGS_SUB
	_sound.pressed.connect(func() -> void:
		Game.set_muted(not Game.profile.muted)
		_render())
	_vibration.pressed.connect(func() -> void:
		Game.set_vibration(not Game.profile.vibration)
		_render())
	_damage.pressed.connect(func() -> void:
		Game.set_damage_numbers(not Game.profile.damage_numbers)
		_render())
	_debug.pressed.connect(func() -> void:
		Game.set_debug_info(not Game.profile.debug_info)
		_render())
	_debug.visible = DebugOverlay.available()
	# Journal de jeu (version 4.2.1) : le résumé des dernières parties, à coller dans la conversation.
	_journal.pressed.connect(func() -> void:
		var tuning: TuningData = Tuning.data
		DisplayServer.clipboard_set(Journal.digest(tuning.journal_digest_sessions, tuning.journal_digest_max_chars))
		_copied_left = tuning.journal_copied_time
		_render())


func _process(delta: float) -> void:
	if _copied_left > 0.0:
		_copied_left -= delta
		if _copied_left <= 0.0:
			_render()


## Ouvre les réglages ; « Retour » appelle `back`.
func open(back: Callable = Callable()) -> void:
	back_action = back
	_render()
	show_screen()


func _render() -> void:
	var profile: Profile = Game.profile
	_sound.text = GameTexts.SOUND_OFF if profile.muted else GameTexts.SOUND_ON
	_vibration.text = GameTexts.VIBRATION_ON if profile.vibration else GameTexts.VIBRATION_OFF
	_damage.text = GameTexts.DAMAGE_NUMBERS_ON if profile.damage_numbers else GameTexts.DAMAGE_NUMBERS_OFF
	_debug.text = GameTexts.DEBUG_ON if profile.debug_info else GameTexts.DEBUG_OFF
	_journal.text = GameTexts.JOURNAL_COPIED if _copied_left > 0.0 else GameTexts.JOURNAL_COPY % GameTexts.plural(Journal.run_count(), GameTexts.EXPEDITION)
