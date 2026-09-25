extends TextureProgressBar
## Jauge de groove, en anneau autour du bouton Frappe. Pleine, elle passe par toutes les
## couleurs : Frappe en l'air lance alors le Salto arc-en-ciel.

## Teinte de la jauge en cours de remplissage.
@export var filling_color: Color
## Saturation et luminosité de l'arc-en-ciel quand la jauge est pleine.
@export var rainbow_saturation: float
@export var rainbow_value: float

var _hero: Hero


func _process(_delta: float) -> void:
	if _hero == null:
		_hero = get_tree().get_first_node_in_group(&"hero") as Hero
		if _hero == null:
			return
	value = _hero.groove.fraction() * max_value
	if _hero.groove.is_full():
		var seconds: float = Time.get_ticks_msec() / 1000.0
		var hue: float = fposmod(seconds / Tuning.data.groove_rainbow_cycle_time, 1.0)
		tint_progress = Color.from_hsv(hue, rainbow_saturation, rainbow_value)
	else:
		tint_progress = filling_color
