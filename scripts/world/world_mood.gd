class_name WorldMood
extends Node
## Ambiance du monde voxel : fait vivre les uniformes partagés des matériaux (voir
## scenes/world/salto_world.gdshaderinc) : le temps qui fait onduler les couleurs, la saturation qui
## monte à chaque tambour rapporté, l'éclat du décor sur chaque temps de la musique, le brouillard
## qui change lentement de teinte, les sanctuaires libérés qui reprennent leurs couleurs,
## l'objectif du chemin doré, la position du héros et le cercle du groove : autour du héros, la
## jungle retrouve ses couleurs d'autant plus loin que sa jauge de groove est pleine, et le Salto
## arc-en-ciel le fait éclater.

## Héros suivi (pour le laisser voir à travers le décor).
@export var hero: Node3D

var _time: float = 0.0
var _saturation: float = 0.0
var _pulse: float = 0.0
var _freed_target: PackedFloat32Array = [0.0, 0.0, 0.0]
var _freed: PackedFloat32Array = [0.0, 0.0, 0.0]
var _sanctuaries := PackedVector2Array()
var _won: bool = false
var _life: float = 0.0
var _halo: float = 0.0
var _burst: float = 0.0
## Avancée imposée (0 à 1 ; négative : celle des tambours de la nuit) : en expédition, la jungle
## reprend ses couleurs clairière après clairière.
var _progress: float = -1.0
## Teinte fixe de la brume (0 à 1 ; négative : elle tourne lentement), celle d'une région.
var _fog_hue: float = -1.0
## Vague de couleur d'un passage (version 3.5) : centre (m), rayon (m) ; négatif : aucune.
var _wave_center := Vector3.ZERO
var _wave_radius: float = -1.0
var _fog_boost: float = 1.0
var _wave_fog: bool = true
## Première minute (version 3.6) : le monde muet, sans couleurs, jusqu'à la stèle frappée.
var _silenced: bool = false

const SANCTUARY_PARAMS: Array[StringName] = [&"salto_sanctuary_0", &"salto_sanctuary_1", &"salto_sanctuary_2"]


func _ready() -> void:
	add_to_group(&"world_mood")
	RenderingServer.global_shader_parameter_set(&"salto_village", 1.0)
	var tuning: TuningData = Tuning.data
	_saturation = saturation_target(0, false, tuning)
	_halo = tuning.groove_halo_min
	RenderingServer.global_shader_parameter_set(&"salto_unit", tuning.voxel_unit)
	RenderingServer.global_shader_parameter_set(&"salto_fog_density", tuning.fog_density)
	# (Les réglages partagés survivent au rechargement d'une scène : une vague en cours quand on a
	# quitté resterait figée au sol.)
	RenderingServer.global_shader_parameter_set(&"salto_wave", Vector4.ZERO)
	RenderingServer.global_shader_parameter_set(&"salto_cut", 1.0)
	clear_target()


## Sanctuaires du monde (u) ; ceux qui sont déjà libérés gardent leurs couleurs.
func set_sanctuaries(positions: PackedVector2Array, freed: Array[bool]) -> void:
	_sanctuaries = positions
	for i: int in positions.size():
		_freed_target[i] = 1.0 if freed[i] else 0.0
		_freed[i] = _freed_target[i]
	_push_sanctuaries()


## Le sanctuaire `index` est libéré : ses couleurs reviennent peu à peu.
func free_sanctuary(index: int) -> void:
	_freed_target[index] = 1.0


## La nuit est gagnée : couleurs au plus haut, le monde s'anime plus vite.
func set_won(won: bool) -> void:
	_won = won


## Éclat de couleurs (Salto arc-en-ciel) : `amount` de saturation en plus, qui retombe.
func pulse(amount: float) -> void:
	_pulse = maxf(_pulse, amount)


## Couleurs du monde selon l'avancée `fraction` (0 à 1) d'une expédition, au lieu des tambours.
## `village` faux : pas de place ni de chemins dorés au sol.
func set_progress(fraction: float, village: bool) -> void:
	_progress = clampf(fraction, 0.0, 1.0)
	RenderingServer.global_shader_parameter_set(&"salto_village", 1.0 if village else 0.0)


## Brume d'une teinte fixe `hue` (0 à 1) ; négative : la teinte tourne lentement (Sous-bois, nuit).
func set_fog_hue(hue: float) -> void:
	_fog_hue = hue


## Salto arc-en-ciel : le cercle du groove éclate loin autour du héros, tout le monde s'illumine.
func burst() -> void:
	var tuning: TuningData = Tuning.data
	_burst = tuning.groove_halo_burst
	pulse(tuning.rainbow_world_pulse)


## Passage (version 3.5) : la brume de la nouvelle clairière est épaisse, puis une vague de couleur
## part de `center` (m) et la dissout en s'élargissant. `fog` faux (version 3.6 : une clairière
## libérée) : la vague seule, sans brume.
func wave(center: Vector3, fog: bool = true) -> void:
	_wave_center = center
	_wave_radius = 0.0
	_wave_fog = fog


## Monde muet (première minute) : les couleurs se retirent ; faux : elles reviennent.
func silence(on: bool) -> void:
	_silenced = on


func is_silenced() -> bool:
	return _silenced


func is_waving() -> bool:
	return _wave_radius >= 0.0


## Brume du moment (fois la normale : plus de 1 pendant un passage).
func fog_boost() -> float:
	return _fog_boost


## Vague au rayon `radius` (m) : sa force (0 à 1) et combien la brume est plus épaisse (1 : normale).
## Pure, testée.
static func wave_state(radius: float, tuning: TuningData) -> Vector2:
	var reach: float = tuning.passage_wave_reach
	var strength: float = 1.0 - smoothstep(reach * 0.6, reach, radius)
	var fog: float = lerpf(tuning.passage_fog_boost, 1.0, smoothstep(0.0, reach * 0.8, radius))
	return Vector2(strength, fog)


## Bande dorée sur le sol, du village vers `point` (u) ; `outward` faux : elle défile vers le village.
func set_target(point: Vector2, outward: bool) -> void:
	RenderingServer.global_shader_parameter_set(&"salto_target", Vector4(point.x, point.y, 1.0, 1.0 if outward else -1.0))


func clear_target() -> void:
	RenderingServer.global_shader_parameter_set(&"salto_target", Vector4(0.0, 0.0, 0.0, 1.0))


## Saturation visée pour `drums` tambours rapportés.
static func saturation_target(drums: int, won: bool, tuning: TuningData) -> float:
	if won:
		return tuning.world_saturation_won
	return tuning.world_saturation_levels[mini(drums, tuning.world_saturation_levels.size() - 1)]


## Vie de la jungle visée (0 à 1) : une part par tambour rapporté, tout à la nuit gagnée.
static func life_target(drums: int, required: int, won: bool) -> float:
	if won:
		return 1.0
	return clampf(float(drums) / maxf(1.0, float(required)), 0.0, 1.0) * Tuning.data.world_life_before_won


## Rayon actuel du cercle du groove (m).
func groove_radius() -> float:
	return maxf(_halo, _burst)


## Rayon du cercle du groove (m) pour une jauge remplie à `fraction` (0 à 1).
static func halo_radius(fraction: float, tuning: TuningData) -> float:
	return lerpf(tuning.groove_halo_min, tuning.groove_halo_max, clampf(fraction, 0.0, 1.0))


## Couleur d'une teinte, saturation, luminosité (0 à 1), comme THREE.Color.setHSL.
static func hsl(h: float, s: float, l: float) -> Color:
	var k := Vector3(
		clampf(absf(fposmod(h * 6.0, 6.0) - 3.0) - 1.0, 0.0, 1.0),
		clampf(absf(fposmod(h * 6.0 + 4.0, 6.0) - 3.0) - 1.0, 0.0, 1.0),
		clampf(absf(fposmod(h * 6.0 + 2.0, 6.0) - 3.0) - 1.0, 0.0, 1.0))
	var c: float = s * (1.0 - absf(2.0 * l - 1.0))
	return Color(l + c * (k.x - 0.5), l + c * (k.y - 0.5), l + c * (k.z - 0.5))


func _process(delta: float) -> void:
	var tuning: TuningData = Tuning.data
	_time += delta * (tuning.world_time_speed_won if _won else 1.0)
	RenderingServer.global_shader_parameter_set(&"salto_time", fmod(_time, 2000.0))
	var beat: float = 0.0
	if Rhythm.is_playing():
		# Une respiration discrète sur les temps (version 3.1), pas un clignotement.
		beat = exp(-fposmod(Rhythm.song_time() / Rhythm.beat_length(), 1.0) * tuning.world_beat_decay) * tuning.world_beat_amount
	RenderingServer.global_shader_parameter_set(&"salto_beat", beat)
	_pulse = maxf(0.0, _pulse - delta * tuning.world_saturation_pulse_decay)
	var levels: PackedFloat32Array = tuning.world_saturation_levels
	var base: float = lerpf(levels[0], levels[levels.size() - 1], _progress) if _progress >= 0.0 else saturation_target(Game.progress.drums_returned, _won, tuning)
	var target: float = (tuning.silence_saturation if _silenced else base) + _pulse
	var rate: float = tuning.world_saturation_pulse_rate if _pulse > 0.0 else tuning.world_saturation_rate
	_saturation += (target - _saturation) * Smoothing.weight(rate, delta)
	RenderingServer.global_shader_parameter_set(&"salto_sat", _saturation)
	var life: float = _progress * tuning.world_life_before_won if _progress >= 0.0 else life_target(Game.progress.drums_returned, Game.progress.drums_required, _won)
	if _silenced:
		life = 0.0
	_life += (life - _life) * Smoothing.weight(tuning.world_saturation_rate, delta)
	RenderingServer.global_shader_parameter_set(&"salto_life", _life)
	for i: int in _sanctuaries.size():
		_freed[i] += (_freed_target[i] - _freed[i]) * Smoothing.weight(tuning.world_freed_rate, delta)
	_push_sanctuaries()
	var hue: float = _fog_hue if _fog_hue >= 0.0 else fmod(_time * tuning.fog_hue_speed, 1.0)
	var fog: Color = hsl(hue, tuning.fog_saturation * minf(1.0, _saturation), tuning.fog_lightness)
	RenderingServer.global_shader_parameter_set(&"salto_fog_color", Vector4(fog.r, fog.g, fog.b, 1.0))
	if is_instance_valid(hero):
		RenderingServer.global_shader_parameter_set(&"salto_player", hero.global_position + Vector3.UP * tuning.cutaway_height)
	var gauge: GrooveGauge = (hero as Hero).groove if hero is Hero else null
	var halo: float = halo_radius(gauge.fraction() if gauge else 0.0, tuning)
	_halo += (halo - _halo) * Smoothing.weight(tuning.groove_halo_rate, delta)
	_burst = maxf(0.0, _burst - tuning.groove_halo_burst_decay * delta)
	RenderingServer.global_shader_parameter_set(&"salto_groove", groove_radius())
	if _wave_radius >= 0.0:
		_wave_radius += tuning.passage_wave_speed * delta
		var state: Vector2 = wave_state(_wave_radius, tuning)
		if not _wave_fog:
			state.y = 1.0
		_fog_boost = state.y
		RenderingServer.global_shader_parameter_set(&"salto_wave", Vector4(_wave_center.x, _wave_center.z, _wave_radius, state.x))
		RenderingServer.global_shader_parameter_set(&"salto_fog_density", tuning.fog_density * state.y)
		if _wave_radius >= tuning.passage_wave_reach:
			_wave_radius = -1.0
			_fog_boost = 1.0
			RenderingServer.global_shader_parameter_set(&"salto_wave", Vector4.ZERO)
			RenderingServer.global_shader_parameter_set(&"salto_fog_density", tuning.fog_density)


func _push_sanctuaries() -> void:
	for i: int in _sanctuaries.size():
		var p: Vector2 = _sanctuaries[i]
		RenderingServer.global_shader_parameter_set(SANCTUARY_PARAMS[i], Vector4(p.x, p.y, _freed[i], 0.0))
