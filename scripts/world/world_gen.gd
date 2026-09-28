class_name WorldGen
extends RefCounted
## Génération du monde d'une nuit, portée du prototype (docs/prototype/salto-rpg.html, buildWorld) :
## mêmes formes et même tirage, donc le même monde pour une même graine. Tout est en unités du
## prototype (u, le héros mesure 7 u) ; la scène convertit en mètres (Tuning.voxel_unit).
##
## Chaque voxel est rangé dans `voxels` sous la forme x, y, z, teinte (+ mode), saturation,
## luminosité, taille. Le mode, partie entière de la teinte, dit comment le matériau voxel l'anime
## (voir scenes/world/voxel.gdshader).

## Hauteur des solides qu'on ne peut pas franchir (troncs, cases, piliers).
const WALL := 99.0
const VILLAGE_R := 14.0
const WORLD_R := 84.0
const SANCTUARY_COUNT := 3
const DIRS: PackedStringArray = [
	"du Nord", "du Nord-Est", "de l'Est", "du Sud-Est", "du Sud", "du Sud-Ouest", "de l'Ouest", "du Nord-Ouest",
]
## Estrades des trois tambours, autour du Chef.
const SLOTS: PackedVector2Array = [Vector2(-4.5, -5.5), Vector2(0.0, -8.0), Vector2(4.5, -5.5)]
const CHIEF := Vector2(0.0, -1.0)
const CHIEF_R := 1.6
## Villageois qui dansent autour de la place.
const DANCERS: PackedVector2Array = [
	Vector2(-10.0, 3.0), Vector2(-11.5, -4.0), Vector2(-7.0, -10.5), Vector2(7.0, -10.5), Vector2(11.5, -4.0), Vector2(10.0, 3.0),
]
const DANCER_R := 1.0
const SLOT_R := 1.6
## Clairière d'expédition (u) : écart entre le bord et la première rangée d'arbres, entre les
## rangées, espacement des arbres (première rangée, seconde), dispersion ; le mur invisible est à
## cette distance derrière le bord ; demi-ouverture d'un passage (rad) ; buissons (rayon, en plus
## au hasard) ; décor de chaque forme de clairière ; fleurs, essais de placement ; centre dégagé
## (rayon), demi-largeur de l'axe des passages.
const ROOM_RING_GAP := 1.5
const ROOM_RING_STEP := 7.0
const ROOM_TREE_SPACING := 4.2
const ROOM_TREE_SPACING_OUTER := 7.0
const ROOM_RING_JITTER := 1.0
const ROOM_WALL_BEHIND := 3.5
const ROOM_GAP_ANGLE := 0.17
const ROOM_BUSH_R := 2.2
const ROOM_BUSH_R_JITTER := 0.8
const ROOM_ROCKS := 3
const ROOM_STUMPS := 2
const ROOM_GROVE_TREES := 3
const ROOM_GROVE_BUSHES := 2
const ROOM_LOGS := 3
const ROOM_MUSHROOMS := 4
const ROOM_BOUNCERS := 2
const ROOM_RUIN_RING := 0.58
const ROOM_RUIN_PILLARS := 8
const ROOM_ARENA_RING := 0.75
const ROOM_ARENA_PILLARS := 10
const ROOM_BROKEN_CHANCE := 0.35
const ROOM_FLOWERS := 90
const ROOM_TRIES := 400
const ROOM_CENTER_CLEAR := 9.0
const ROOM_LANE := 3.0
## Formes de clairière d'expédition (hors celle du Grand Muet).
const ROOM_KINDS: Array[StringName] = [&"clearing", &"ruins", &"grove", &"logs", &"mushrooms"]
## Végétation (version 2.5) : part de palmiers au premier rang du bord, de fromagers au second,
## lianes qui pendent devant (et leur hauteur, u), palmiers et fougères dans la clairière, touffes
## d'herbe, cailloux ; courbure des palmiers ; bas des lianes ; rayon des mares (u).
const ROOM_PALM_SHARE := 0.35
const ROOM_KAPOK_SHARE := 0.3
const ROOM_LIANAS := 12
const ROOM_LIANA_TOP := 9.0
const ROOM_PALMS := 2
const ROOM_FERNS := 6
const ROOM_GRASS := 160
const ROOM_PEBBLES := 26
const PALM_BEND := 0.008
const LIANA_BOTTOM := 2.4
const POND_RADIUS_MIN := 3.0
const POND_RADIUS_MAX := 4.5
## Modules (version 2.6, u) : rivière (largeur), ponts (largeur, place en part du rayon), estrades
## (demi-côté, hauteur, profondeur de la marche), plateformes de la Canopée (demi-côté, hauteur) ;
## jarres (au moins, au plus), chances d'un tambour de guerre et d'un rocher fêlé ; tambour (rayon,
## hauteur).
const RIVER_WIDTH := 7.0
const BRIDGE_WIDTH := 4.0
const BRIDGE_OFFSET := 0.45
const DAIS_HALF := 3.0
const DAIS_HEIGHT := 2.0
const DAIS_STEP_DEPTH := 2.0
const PLATFORM_HALF := 3.5
const PLATFORM_HEIGHT := 3.0
const JARS_MIN := 2
const JARS_MAX := 4
const DRUM_CHANCE := 0.55
const SECRET_CHANCE := 0.25
const DRUM_RADIUS := 1.6
const DRUM_HEIGHT := 4.0
## Hauteur de la plume (ou du coffre) au-dessus du dernier rocher d'un perchoir (u).
const PERCH_ABOVE := 1.2
## Clairière du cercle des gongs (u) : rayon libre, entre ces distances du village, à cette distance
## au plus d'un chemin (qu'on la trouve en passant), loin des sanctuaires ; tirage à part (le monde
## du prototype ne change pas).
const CLEARING_R := 6.0
const CLEARING_MIN := 26.0
const CLEARING_MAX := 60.0
const CLEARING_PATH := 7.0
const CLEARING_SANCTUARY := 20.0
const CLEARING_TRIES := 600
const CLEARING_SALT := 0x5A170
const SLOT_H := 1.0
const TOTEM := Vector2(0.0, -12.5)
## Hauteur de l'autel d'un sanctuaire, où attend le tambour.
const ALTAR_HEIGHT := 2.0
const TOTEM_R := 1.3
const BOUNCE := &"bounce"
## Hauteur d'un tronc couché (u) : de quoi apprendre à sauter.
const LOG_HEIGHT := 1.35
## Valeurs d'une ligne de `voxels`.
const STRIDE := 7

## Un obstacle rond : on s'y pose si on saute plus haut que `h` (WALL : infranchissable).
class Solid:
	var x: float
	var z: float
	var r: float
	var h: float
	var kind: StringName

	func _init(px: float, pz: float, radius: float, height: float, solid_kind: StringName) -> void:
		x = px
		z = pz
		r = radius
		h = height
		kind = solid_kind


var voxels := PackedFloat32Array()
## Ombres rondes au sol : x, z, rayon, opacité.
var shadows := PackedFloat32Array()
var solids: Array[Solid] = []
## Plumes dorées au sommet des perchoirs.
var pickups := PackedVector3Array()
var sanctuaries := PackedVector2Array()
var sanctuary_names := PackedStringArray()
var huts := PackedVector2Array()
var totem_height: int = 0
## Centre de la clairière du cercle des gongs (u) ; Vector2.INF si aucune n'est libre.
var gong_clearing := Vector2.INF
## Rayon des murs invisibles du bord (u).
var border_radius: float = WORLD_R
## Mares : x, z, rayon (u), à la suite (version 2.5).
var ponds := PackedFloat32Array()
## Version 2.6 (modules faits main) : estrades, plateformes et passerelles (boîtes pleines depuis le
## sol : centre x, z, demi-largeurs, hauteur, en u) ; rivières (rectangles d'eau : centre, demi-
## largeurs) ; ponts (rectangles où l'eau ne ralentit pas) ; pièges au tempo (kind : spikes ou whip,
## x, z, angle, phase) ; tambours de guerre, jarres (positions) ; rocher fêlé du secret
## (Vector2.INF : aucun).
var boxes: Array[Rect2] = []
var box_heights := PackedFloat32Array()
var waters: Array[Rect2] = []
var bridges: Array[Rect2] = []
var traps: Array[Dictionary] = []
var drums := PackedVector2Array()
var jars := PackedVector2Array()
var secret := Vector2.INF
## Décalage de teinte des feuillages et des herbes (région de l'expédition).
var foliage_shift: float = 0.0
## Village (version 2.7) : rang de chaque case rebâtie (voir Village) ; le lire avant
## generate_room(…, &"village").
var village_built: Dictionary[StringName, int] = {}

var _rng: ProtoRandom


## Construit le monde de la graine `seed_value` ; `nights_done` fait grandir le totem.
func generate(seed_value: int, nights_done: int) -> void:
	_rng = ProtoRandom.new(seed_value)
	voxels.clear()
	shadows.clear()
	solids.clear()
	pickups.clear()
	sanctuaries.clear()
	sanctuary_names.clear()
	huts.clear()
	ponds.clear()
	_clear_modules()
	gong_clearing = Vector2.INF
	border_radius = WORLD_R
	_add_village_solids()
	var base: float = _rnd() * TAU
	for i: int in SANCTUARY_COUNT:
		var a: float = base + i * TAU / SANCTUARY_COUNT + (_rnd() - 0.5) * 0.5
		var r: float = 52.0 + _rnd() * 14.0
		var p := Vector2(sin(a) * r, -cos(a) * r)
		sanctuaries.append(p)
		sanctuary_names.append(direction_name(p))
	var t: int = 0
	while huts.size() < 3 and t < 400:
		t += 1
		var a: float = _rnd() * TAU
		var r: float = 17.5 + _rnd() * 3.0
		var p := Vector2(cos(a) * r, sin(a) * r)
		if p.y > 8.0 or near_path(p, 7.0) or _near_any(p, huts, 10.0):
			continue
		huts.append(p)
	for p: Vector2 in huts:
		_hut(p.x, p.y)
	for s: Vector2 in sanctuaries:
		_sanctuary(s)
	for slot: Vector2 in SLOTS:
		for a: int in range(-1, 2):
			for b: int in range(-1, 2):
				_sv(slot.x + a, 0.5, slot.y + b, 1.0, 4.1, 0.3, 0.45)
	_totem(nights_done)
	_forest()
	for i: int in 26:
		var a: float = float(i) / 26.0 * TAU + _rnd() * 0.1
		var r: float = 93.0 + _rnd() * 8.0
		_tree(cos(a) * r, sin(a) * r, 1.7, false, 3)
	_place(4.5, _perch, 4 + floori(_rnd() * 2.0), 26.0, 74.0, 2000)
	_place(2.2, _random_rock, 16 + floori(_rnd() * 6.0), 20.0, 80.0, 3000)
	_place(1.6, _stump, 14, 18.0, 80.0, 2000)
	_place(2.0, _bouncer, 7, 22.0, 78.0, 2000)
	_place(3.0, _mushroom, 8 + floori(_rnd() * 6.0), 20.0, 80.0, 3000)
	for i: int in 500:
		var a: float = _rnd() * TAU
		var r: float = 16.0 + _rnd() * 70.0
		var p := Vector2(cos(a) * r, sin(a) * r)
		if near_path(p, 3.5):
			continue
		_sv(p.x, 0.25, p.y, 0.5, 1.0 + _rnd() * 0.99, 0.9, 0.6)
	gong_clearing = _find_clearing(ProtoRandom.new(seed_value ^ CLEARING_SALT))


## Clairière d'une expédition, centrée en 0 (rayon `radius` u), de la forme `kind` (voir
## ROOM_KINDS ; &"arena" : celle du Grand Muet) : un mur d'arbres et de buissons au bord (le mur
## invisible est derrière), sauf aux passages (angles `gaps`, en radians depuis le nord, dans le
## sens des aiguilles d'une montre), puis le décor de sa forme (le centre et l'axe des passages
## restent dégagés), des fleurs.
func generate_room(seed_value: int, radius: float, gaps: PackedFloat32Array, kind: StringName = &"clearing") -> void:
	_rng = ProtoRandom.new(seed_value)
	voxels.clear()
	shadows.clear()
	solids.clear()
	pickups.clear()
	sanctuaries.clear()
	sanctuary_names.clear()
	huts.clear()
	ponds.clear()
	_clear_modules()
	gong_clearing = Vector2.INF
	border_radius = radius + ROOM_WALL_BEHIND
	_room_border(radius, gaps)
	match kind:
		&"ruins":
			_room_ruins(radius, gaps, ROOM_RUIN_RING, ROOM_RUIN_PILLARS, true)
		&"arena":
			_room_ruins(radius, gaps, ROOM_ARENA_RING, ROOM_ARENA_PILLARS, false)
		&"grove":
			_room_place(_inner_tree, ROOM_GROVE_TREES + floori(_rnd() * 2.0), radius, gaps, 3.5)
			_room_place(_bush, ROOM_GROVE_BUSHES, radius, gaps, 3.0)
			_room_place(_fern, ROOM_FERNS, radius, gaps, 2.0)
		&"logs":
			_room_place(_room_log, ROOM_LOGS + floori(_rnd() * 2.0), radius, gaps, 4.5)
			_room_place(_stump, ROOM_STUMPS + 1, radius, gaps, 2.0)
			_room_place(_fern, ROOM_FERNS - 2, radius, gaps, 2.0)
		&"flooded":
			_room_flooded(radius, gaps)
		&"heights":
			_room_heights(radius, gaps)
		&"village":
			_room_village(radius, gaps)
		&"mushrooms":
			_room_place(_mushroom, ROOM_MUSHROOMS + floori(_rnd() * 2.0), radius, gaps, 3.5)
			_room_place(_bouncer, ROOM_BOUNCERS, radius, gaps, 2.5)
			_room_place(_perch, 1, radius, gaps, 5.5)
			_room_place(_room_pond, 1, radius, gaps, 5.0)
		_:
			_room_place(_random_rock, ROOM_ROCKS + floori(_rnd() * 3.0), radius, gaps, 3.0)
			_room_place(_stump, ROOM_STUMPS + floori(_rnd() * 2.0), radius, gaps, 2.0)
			_room_place(_bouncer, 1, radius, gaps, 2.5)
			_room_place(_palm, ROOM_PALMS, radius, gaps, 3.0)
			_room_place(_room_pond, 1, radius, gaps, 5.0)
			_room_place(_fern, ROOM_FERNS - 2, radius, gaps, 2.0)
	for i: int in ROOM_FLOWERS:
		var a: float = _rnd() * TAU
		var r: float = _rnd() * radius
		_sv(sin(a) * r, 0.25, -cos(a) * r, 0.5, 1.0 + _rnd() * 0.99, 0.9, 0.6)
	_grass(radius, ROOM_GRASS)
	_pebbles(radius, ROOM_PEBBLES)
	if kind != &"arena" and kind != &"village":
		_room_props(radius, gaps, kind)


## Le bord de la clairière : arbres et buissons serrés, en deux rangées (la première s'ouvre aux
## passages). Version 2.5 : des palmiers dans la première, des fromagers dans la seconde (leurs
## couronnes plates dessinent l'horizon), des lianes qui pendent devant.
func _room_border(radius: float, gaps: PackedFloat32Array) -> void:
	for row: int in 2:
		var ring: float = radius + ROOM_RING_GAP + row * ROOM_RING_STEP
		var count: int = floori(TAU * ring / (ROOM_TREE_SPACING if row == 0 else ROOM_TREE_SPACING_OUTER))
		for i: int in count:
			var a: float = (i + row * 0.5) / count * TAU
			if _near_gap(a, gaps):
				continue
			var p := Vector2(sin(a), -cos(a)) * (ring + _rnd() * ROOM_RING_JITTER)
			var pick: float = _rnd()
			if row == 0 and i % 2 == 1:
				_bush(p.x, p.y)
			elif row == 0 and pick < ROOM_PALM_SHARE:
				_palm(p.x, p.y)
			elif row == 1 and pick < ROOM_KAPOK_SHARE:
				_kapok(p.x, p.y)
			else:
				_tree(p.x, p.y, 1.0, true, 0)
	for i: int in ROOM_LIANAS:
		var a: float = (i + _rnd() * 0.6) / ROOM_LIANAS * TAU
		if _near_gap(a, gaps):
			continue
		var p := Vector2(sin(a), -cos(a)) * (radius + ROOM_RING_GAP * 0.5)
		_liana(p.x, p.y, ROOM_LIANA_TOP + _rnd() * 3.0)


## Ruines : un cercle de piliers (certains brisés, assez bas pour sauter dessus) et, au centre,
## un autel où l'on peut monter.
func _room_ruins(radius: float, gaps: PackedFloat32Array, ring_part: float, count: int, altar: bool) -> void:
	var ring: float = radius * ring_part
	for i: int in count:
		var a: float = (i + 0.5) / count * TAU
		var p := Vector2(sin(a), -cos(a)) * ring
		var lane: bool = false
		for gap: float in gaps:
			if segment_distance(p, Vector2.ZERO, gap_point(gap, radius)) < ROOM_LANE + 1.5:
				lane = true
		if lane:
			continue
		var broken: bool = _rnd() < ROOM_BROKEN_CHANCE
		var h: int = 2 if broken else 4 + floori(_rnd() * 3.0)
		for y: int in h:
			_sv(p.x, y * 1.1 + 0.55, p.y, 1.1, 4.74, 0.15, 0.28 + _rnd() * 0.06)
			_sv(p.x + 0.9, y * 1.1 + 0.55, p.y, 1.1, 4.74, 0.15, 0.3 + _rnd() * 0.06)
		_add_solid(p.x + 0.45, p.y, 1.3, h * 1.1)
		_shadow(p.x, p.y, 1.8, 0.28)
	if altar:
		for x: int in range(-2, 3):
			for z: int in range(-2, 3):
				for y: int in 2:
					_sv(x, y + 0.5, z, 1.0, 4.72, 0.18, 0.3 + _rnd() * 0.06)
		_add_solid(0.0, 0.0, 2.6, ALTAR_HEIGHT)
		_shadow(0.0, 0.0, 3.5, 0.3)


## Buisson : une boule de feuillage basse, infranchissable.
func _bush(x: float, z: float) -> void:
	var r: float = ROOM_BUSH_R + _rnd() * ROOM_BUSH_R_JITTER
	var hue: float = 0.26 + _rnd() * 0.14
	var n: int = ceili(r)
	for a: int in range(-n, n + 1):
		for b: int in range(-n, n + 1):
			for y: int in 3:
				var d: float = Vector3(a, y * 1.2, b).length()
				if d > r or d < r - 1.6:
					continue
				_sv(x + a * 0.9, y * 0.9 + 0.45, z + b * 0.9, 0.95, fmod(hue + d * 0.015, 1.0), 0.75, 0.3 + _rnd() * 0.1)
	_add_solid(x, z, r * 0.85)
	_shadow(x, z, r + 0.6, 0.3)


func _inner_tree(x: float, z: float) -> void:
	_tree(x, z, 1.0, true, 0)


## Palmier : un tronc qui s'incline en courbe, des palmes qui retombent, trois noix de coco.
func _palm(px: float, pz: float) -> void:
	var h: int = 11 + floori(_rnd() * 5.0)
	var bend_angle: float = _rnd() * TAU
	var bend := Vector2(cos(bend_angle), sin(bend_angle)) * PALM_BEND
	for y: int in h:
		var off: Vector2 = bend * y * y
		_sv(px + off.x, (y + 0.5) * 0.9, pz + off.y, 0.9, 4.07, 0.42, 0.3 + (y % 2) * 0.04)
	var top := Vector2(px, pz) + bend * h * h
	var ty: float = h * 0.9
	var hue: float = 0.27 + _rnd() * 0.08
	for f: int in 7:
		var a: float = f / 7.0 * TAU + _rnd() * 0.3
		var d := Vector2(cos(a), sin(a))
		for k: int in 6:
			var reach: float = 0.8 + k * 0.85
			_sv(top.x + d.x * reach, ty + 0.4 - k * k * 0.12, top.y + d.y * reach, 0.85 - k * 0.06, hue + k * 0.01, 0.75, 0.36 + (k % 2) * 0.05)
	for c: int in 3:
		var a: float = c / 3.0 * TAU
		_sv(top.x + cos(a) * 0.6, ty - 0.4, top.y + sin(a) * 0.6, 0.55, 4.08, 0.6, 0.28)
	_add_solid(px, pz, 0.9)
	_shadow(top.x, top.y, 3.2, 0.25)


## Fromager : un tronc large aux contreforts, une couronne plate et immense (second rang du bord).
func _kapok(kx: float, kz: float) -> void:
	var h: int = 12 + floori(_rnd() * 4.0)
	for y: int in h:
		for a: int in 2:
			for b: int in 2:
				_sv(kx + (a - 0.5) * 1.2, (y + 0.5) * 1.1, kz + (b - 0.5) * 1.2, 1.2, 4.07, 0.32, 0.3 + _rnd() * 0.03)
	for i: int in 4:
		var angle: float = i / 4.0 * TAU + 0.4
		var d := Vector2(cos(angle), sin(angle))
		for k: int in 4:
			for y: int in 4 - k:
				_sv(kx + d.x * (1.2 + k * 0.9), (y + 0.5) * 1.0, kz + d.y * (1.2 + k * 0.9), 0.9, 4.07, 0.32, 0.27)
	var cr: float = 6.0 + _rnd() * 2.0
	var cy: float = h * 1.1 + 1.0
	var hue: float = 0.24 + _rnd() * 0.1
	var n: int = ceili(cr)
	for x: int in range(-n, n + 1):
		for z: int in range(-n, n + 1):
			var d: float = Vector2(x, z).length()
			if d > cr:
				continue
			_sv(kx + x * 1.1, cy, kz + z * 1.1, 1.1, fmod(hue + d * 0.01, 1.0), 0.7, 0.3 + _rnd() * 0.06)
			if d < cr - 1.2:
				_sv(kx + x * 1.1, cy + 1.1, kz + z * 1.1, 1.1, fmod(hue + d * 0.01, 1.0), 0.75, 0.38 + _rnd() * 0.1)
	_add_solid(kx, kz, 2.0)
	_shadow(kx, kz, cr * 1.1, 0.32)


## Fougère : quelques frondes basses et arquées (on marche au travers).
func _fern(fx: float, fz: float) -> void:
	var hue: float = 0.3 + _rnd() * 0.08
	for f: int in 6:
		var a: float = f / 6.0 * TAU + _rnd() * 0.4
		var d := Vector2(cos(a), sin(a))
		for k: int in 4:
			_sv(fx + d.x * (0.5 + k * 0.6), 0.4 + sin(k / 3.0 * PI) * 0.9, fz + d.y * (0.5 + k * 0.6), 0.55, hue + k * 0.01, 0.8, 0.34 + k * 0.03)
	_shadow(fx, fz, 2.0, 0.2)


## Liane : une tige qui pend de la canopée jusqu'à hauteur d'épaule, des feuilles de loin en loin.
func _liana(lx: float, lz: float, top: float) -> void:
	var hue: float = 0.28 + _rnd() * 0.1
	var y: float = top
	var i: int = 0
	while y > LIANA_BOTTOM:
		_sv(lx + sin(i * 0.7) * 0.25, y, lz + cos(i * 0.9) * 0.25, 0.4, 4.3, 0.5, 0.25)
		if i % 3 == 0:
			_sv(lx + 0.45, y - 0.2, lz, 0.6, hue, 0.75, 0.36)
		y -= 0.55
		i += 1


func _clear_modules() -> void:
	boxes.clear()
	box_heights.clear()
	waters.clear()
	bridges.clear()
	traps.clear()
	drums.clear()
	jars.clear()
	secret = Vector2.INF


## Vrai si le point `p` (u) est dans l'eau (rivière ou mare) et pas sur un pont.
func water_at(p: Vector2) -> bool:
	for bridge: Rect2 in bridges:
		if bridge.has_point(p):
			return false
	for water: Rect2 in waters:
		if water.has_point(p):
			return true
	for i: int in ponds.size() / 3:
		if p.distance_to(Vector2(ponds[i * 3], ponds[i * 3 + 1])) < ponds[i * 3 + 2]:
			return true
	return false


## Boîte pleine posée au sol (estrade, plateforme, passerelle) : cubes de pierre ou de bois
## (`wood`), dessus plus clair, et son obstacle. Rectangle et hauteur en u.
func _box(rect: Rect2, height: float, wood: bool) -> void:
	boxes.append(rect)
	box_heights.append(height)
	var hue: float = 4.07 if wood else 4.72
	var sat: float = 0.4 if wood else 0.15
	var cols: int = ceili(rect.size.x)
	var rows: int = ceili(rect.size.y)
	var layers: int = ceili(height)
	for i: int in cols:
		for j: int in rows:
			var x: float = rect.position.x + (i + 0.5) * rect.size.x / cols
			var z: float = rect.position.y + (j + 0.5) * rect.size.y / rows
			var edge: bool = i == 0 or j == 0 or i == cols - 1 or j == rows - 1
			for y: int in layers:
				var top: bool = y == layers - 1
				if not edge and not top:
					continue
				var plank: float = 0.04 * float((i + (j if wood else 0)) % 2)
				_sv(x, (y + 0.5) * height / layers, z, maxf(rect.size.x / cols, rect.size.y / rows) * 1.02, hue, sat, (0.4 if top else 0.3) + plank + _rnd() * 0.04)


## Estrade avec une marche d'un côté (on y monte sans sauter).
func _dais(center: Vector2, half: float, height: float, facing: Vector2, wood: bool) -> void:
	_box(Rect2(center - Vector2.ONE * half, Vector2.ONE * half * 2.0), height, wood)
	var step_center: Vector2 = center + facing * (half + DAIS_STEP_DEPTH / 2.0)
	var across := Vector2(absf(facing.y), absf(facing.x))
	var step_size: Vector2 = across * half * 1.2 + Vector2(absf(facing.x), absf(facing.y)) * DAIS_STEP_DEPTH
	_box(Rect2(step_center - step_size, step_size * 2.0), height / 2.0, wood)
	_shadow(center.x, center.y, half * 1.6, 0.25)


## Rivière des Ruines englouties : une bande d'eau d'est en ouest à franchir sur deux ponts de
## planches (ou en pataugeant, lentement) ; une estrade de chaque côté ; des épines rythmiques au
## bout des ponts ; des piliers.
func _room_flooded(radius: float, gaps: PackedFloat32Array) -> void:
	var z: float = (_rnd() - 0.6) * radius * 0.4
	var half_width: float = RIVER_WIDTH / 2.0
	var river := Rect2(-radius - ROOM_RING_GAP, z - half_width, (radius + ROOM_RING_GAP) * 2.0, RIVER_WIDTH)
	waters.append(river)
	for side: float in [-1.0, 1.0]:
		var bx: float = side * radius * BRIDGE_OFFSET
		var bridge := Rect2(bx - BRIDGE_WIDTH / 2.0, z - half_width - 1.0, BRIDGE_WIDTH, RIVER_WIDTH + 2.0)
		bridges.append(bridge)
		for j: int in ceili(bridge.size.y):
			for i: int in ceili(BRIDGE_WIDTH):
				_sv(bridge.position.x + i + 0.5, 0.35, bridge.position.y + j + 0.5, 1.0, 4.07, 0.45, 0.36 + (j % 2) * 0.05)
		traps.append({&"kind": &"spikes", &"x": bx, &"z": z - side * (half_width + 2.5), &"angle": 0.0, &"phase": 0 if side < 0.0 else 1})
	for side: float in [-1.0, 1.0]:
		var dz: float = z + side * (half_width + DAIS_HALF + 5.0)
		var dx: float = -side * radius * 0.35
		if absf(dz) < radius - DAIS_HALF * 2.0 and _free_spot(Vector2(dx, dz), DAIS_HALF + 2.0):
			_dais(Vector2(dx, dz), DAIS_HALF, DAIS_HEIGHT, Vector2(0.0, side), false)
	_room_ruins(radius, gaps, ROOM_RUIN_RING, 6, false)


## Hauteurs de la Canopée : deux plateformes de bois à marches, reliées par une passerelle, une
## plume arc-en-ciel sur la plus haute ; des lianes qui fouettent au temps.
func _room_heights(radius: float, gaps: PackedFloat32Array) -> void:
	var a: float = _rnd() * TAU
	var spots: Array[Vector2] = []
	for k: int in 2:
		var angle: float = a + k * PI + (_rnd() - 0.5) * 0.6
		var p := Vector2(sin(angle), -cos(angle)) * radius * 0.5
		var lane: bool = false
		for gap: float in gaps:
			if segment_distance(p, Vector2.ZERO, gap_point(gap, radius)) < ROOM_LANE + PLATFORM_HALF + 1.5:
				lane = true
		if lane:
			p = p.rotated(PI / 2.0)
		spots.append(p)
		# La marche regarde vers le centre de la clairière.
		var facing: Vector2 = Vector2(-signf(p.x), 0.0) if absf(p.x) > absf(p.y) else Vector2(0.0, -signf(p.y))
		_dais(p, PLATFORM_HALF, PLATFORM_HEIGHT + k, facing, true)
		for i: int in 4:
			var corner: Vector2 = p + Vector2(1.0 if i % 2 == 0 else -1.0, 1.0 if i < 2 else -1.0) * PLATFORM_HALF
			_liana(corner.x, corner.y, ROOM_LIANA_TOP)
	var high: Vector2 = spots[1]
	pickups.append(Vector3(high.x, PLATFORM_HEIGHT + 1.0 + PERCH_ABOVE, high.y))
	for k: int in 2:
		var angle: float = a + PI / 2.0 + k * PI
		var p := Vector2(sin(angle), -cos(angle)) * radius * 0.45
		traps.append({&"kind": &"whip", &"x": p.x, &"z": p.y, &"angle": angle + PI / 2.0, &"phase": k * 2})


## Décor de jeu de toute clairière de combat : jarres à casser au pied des arbres, parfois un tambour
## de guerre, parfois un rocher fêlé qui cache un passage secret ; des épines rythmiques dans
## les Ruines et la Canopée.
func _room_props(radius: float, gaps: PackedFloat32Array, kind: StringName) -> void:
	for i: int in JARS_MIN + floori(_rnd() * (JARS_MAX - JARS_MIN + 1)):
		var a: float = _rnd() * TAU
		var p := Vector2(sin(a), -cos(a)) * (radius - 2.0 - _rnd() * 3.0)
		if not _near_gap(a, gaps) and _free_spot(p, 1.5):
			jars.append(p)
	if _rnd() < DRUM_CHANCE:
		var placed: bool = false
		for t: int in ROOM_TRIES:
			if placed:
				break
			var a: float = _rnd() * TAU
			var p := Vector2(sin(a), -cos(a)) * (ROOM_CENTER_CLEAR + _rnd() * (radius * 0.5))
			if _free_spot(p, 3.0) and not water_at(p):
				drums.append(p)
				_add_solid(p.x, p.y, DRUM_RADIUS, DRUM_HEIGHT)
				placed = true
	if _rnd() < SECRET_CHANCE:
		for t: int in ROOM_TRIES:
			var a: float = _rnd() * TAU
			if _near_gap(a, gaps):
				continue
			var p := Vector2(sin(a), -cos(a)) * (radius - 1.5)
			if _free_spot(p, 2.5):
				secret = p
				break
	if kind == &"ruins" or kind == &"grove":
		for i: int in 1 + floori(_rnd() * 2.0):
			var a: float = _rnd() * TAU
			var p := Vector2(sin(a), -cos(a)) * (ROOM_CENTER_CLEAR + _rnd() * radius * 0.4)
			if _free_spot(p, 2.0):
				traps.append({&"kind": &"spikes", &"x": p.x, &"z": p.y, &"angle": 0.0, &"phase": i})


## Place des cases du village (u, depuis le feu au centre) et du Chef.
const VILLAGE_PLOTS: Dictionary[StringName, Vector2] = {
	&"altar": Vector2(-13.0, -8.0), &"drum_hut": Vector2(13.0, -8.0),
	&"spring": Vector2(-13.0, 9.0), &"stage": Vector2(13.0, 9.0),
}
const VILLAGE_CHIEF := Vector2(0.0, -6.0)
## Râtelier des instruments (version 2.8), près du passage du nord.
const VILLAGE_RACK := Vector2(-8.0, -23.0)
## Pierre des pactes (version 2.9), de l'autre côté du passage.
const VILLAGE_PACTS := Vector2(8.0, -23.0)
const VILLAGE_FIRE_CLEAR := 3.0
## Couleurs codées du village rebâti (mode 2 : fixes, vives) et des chantiers (mode 4 : bues par le
## silence).
const V_WOOD := Vector3(2.07, 0.55, 0.36)
const V_ROOF := Vector3(2.11, 0.7, 0.5)
const V_STONE := Vector3(2.72, 0.12, 0.55)
const V_GOLD := Vector3(2.12, 0.9, 0.55)
const V_FLAME := Vector3(2.06, 1.0, 0.58)
const V_WATER := Vector3(1.53, 0.8, 0.6)
const V_BANNER: Array[Vector3] = [Vector3(2.95, 0.85, 0.6), Vector3(2.13, 0.9, 0.58), Vector3(2.5, 0.8, 0.55), Vector3(2.33, 0.8, 0.5)]
const V_RUIN := Vector3(4.08, 0.2, 0.3)
const V_RUIN_STONE := Vector3(4.6, 0.08, 0.38)


## Le village : un feu au centre, quatre cases (rebâties ou en chantier), quelques palmiers.
func _room_village(radius: float, gaps: PackedFloat32Array) -> void:
	_add_solid(0.0, 0.0, VILLAGE_FIRE_CLEAR)
	for id: StringName in VILLAGE_PLOTS:
		var p: Vector2 = VILLAGE_PLOTS[id]
		var level: int = village_built.get(id, 0)
		if level <= 0:
			_plot_ruin(p)
			continue
		match id:
			&"altar":
				_village_altar(p)
			&"drum_hut":
				_village_hut(p)
			&"spring":
				_village_spring(p, level)
			&"stage":
				_village_stage(p)
	_village_rack(VILLAGE_RACK)
	_pact_stone(VILLAGE_PACTS)
	_room_place(_palm, ROOM_PALMS, radius, gaps, 3.0)
	_room_place(_fern, ROOM_FERNS, radius, gaps, 2.0)


## Râtelier : deux montants, une traverse, quatre instruments suspendus aux couleurs vives.
func _village_rack(p: Vector2) -> void:
	for side: int in [-3, 3]:
		for y: int in 5:
			_sv(p.x + side, y + 0.5, p.y, 0.8, V_WOOD.x, V_WOOD.y, V_WOOD.z)
	for x: int in range(-3, 4):
		_sv(p.x + x, 5.3, p.y, 0.7, V_WOOD.x, V_WOOD.y, V_WOOD.z + 0.05)
	var colors: Array[Vector3] = [Vector3(2.5, 0.8, 0.55), Vector3(2.04, 0.85, 0.55), Vector3(2.98, 0.75, 0.45), Vector3(2.28, 0.6, 0.42)]
	for i: int in 4:
		var x: float = p.x - 1.5 + i
		for y: int in 3:
			_sv(x, 4.2 - y * 0.8, p.y + 0.2, 0.6, colors[i].x, colors[i].y, colors[i].z + (0.1 if y == 2 else 0.0))
	_add_solid(p.x, p.y, 1.2, 2.0)
	_shadow(p.x, p.y, 3.5, 0.2)


## Pierre des pactes : un monolithe sombre aux runes violettes.
func _pact_stone(p: Vector2) -> void:
	for y: int in 7:
		var w: int = 1 if y < 5 else 0
		for x: int in range(-w, w + 1):
			for z: int in range(-1, 2):
				var rune: bool = z == 1 and posmod(x + y, 3) == 0
				_sv(p.x + x, y + 0.5, p.y + z, 1.0, 2.78 if rune else V_RUIN_STONE.x, 0.8 if rune else 0.1, 0.6 if rune else 0.25)
	_add_solid(p.x, p.y, 1.8, 3.0)
	_shadow(p.x, p.y, 3.0, 0.25)


## Chantier : quatre piquets, une pile de planches, des pierres renversées.
func _plot_ruin(p: Vector2) -> void:
	for corner: Vector2 in [Vector2(-3, -3), Vector2(3, -3), Vector2(-3, 3), Vector2(3, 3)]:
		for y: int in 2 + floori(_rnd() * 2.0):
			_sv(p.x + corner.x, y + 0.5, p.y + corner.y, 0.7, V_RUIN.x, V_RUIN.y, V_RUIN.z + _rnd() * 0.05)
	for i: int in 3:
		for k: int in 3:
			_sv(p.x - 1.0 + k, 0.4 + i * 0.5, p.y + (i % 2) * 0.4, 0.9, V_RUIN.x, V_RUIN.y, V_RUIN.z + 0.05)
	for i: int in 5:
		var a: float = _rnd() * TAU
		_sv(p.x + cos(a) * 2.2, 0.3, p.y + sin(a) * 2.2, 0.7, V_RUIN_STONE.x, V_RUIN_STONE.y, V_RUIN_STONE.z)
	_add_solid(p.x, p.y, 1.8, 1.5)
	_shadow(p.x, p.y, 3.0, 0.15)


## L'autel des esprits : une estrade de pierre, l'autel, une plume arc-en-ciel, quatre torches.
func _village_altar(p: Vector2) -> void:
	for x: int in range(-3, 4):
		for z: int in range(-3, 4):
			_sv(p.x + x, 0.5, p.y + z, 1.0, V_STONE.x, V_STONE.y, V_STONE.z - 0.08 + _rnd() * 0.05)
	for x: int in range(-1, 2):
		for z: int in range(-1, 2):
			for y: int in 2:
				_sv(p.x + x, 1.5 + y, p.y + z, 1.0, V_STONE.x, V_STONE.y, V_STONE.z)
	for y: int in 3:
		_sv(p.x, 3.6 + y * 0.8, p.y, 0.7 - y * 0.12, 3.0 + y * 0.2, 0.9, 0.6)
	for corner: Vector2 in [Vector2(-3, -3), Vector2(3, -3), Vector2(-3, 3), Vector2(3, 3)]:
		for y: int in 3:
			_sv(p.x + corner.x, 1.5 + y, p.y + corner.y, 0.6, V_WOOD.x, V_WOOD.y, V_WOOD.z)
		_sv(p.x + corner.x, 4.5, p.y + corner.y, 0.7, V_FLAME.x, V_FLAME.y, V_FLAME.z)
	_add_solid(p.x, p.y, 3.8, 2.0)
	_shadow(p.x, p.y, 5.0, 0.25)


## La case du tambourinaire : murs de bois, toit de paille dorée, un grand tambour à côté.
func _village_hut(p: Vector2) -> void:
	var r: float = 3.2
	var door: float = atan2(-p.y, -p.x)
	for x: int in range(-4, 5):
		for z: int in range(-4, 5):
			var d: float = Vector2(x, z).length()
			if d > r or d <= r - 1.1:
				continue
			var is_door: bool = absf(angle_difference(atan2(z, x), door)) < 0.45
			for y: int in 3:
				if is_door and y < 2:
					continue
				_sv(p.x + x, y + 0.5, p.y + z, 1.0, V_WOOD.x, V_WOOD.y, V_WOOD.z + _rnd() * 0.06)
	for l: int in 4:
		var lr: float = r + 0.8 - l * 1.1
		for x: int in range(-5, 6):
			for z: int in range(-5, 6):
				if Vector2(x, z).length() <= lr:
					_sv(p.x + x, 3.5 + l, p.y + z, 1.0, V_ROOF.x, V_ROOF.y, V_ROOF.z + _rnd() * 0.08)
	var drum := p + Vector2(cos(door + 1.2), sin(door + 1.2)) * 5.0
	for y: int in 3:
		for a: int in 8:
			var ang: float = a * TAU / 8.0
			_sv(drum.x + cos(ang) * 1.1, y * 0.8 + 0.4, drum.y + sin(ang) * 1.1, 0.8, 2.98, 0.8, 0.45 if y != 1 else 0.3)
	_sv(drum.x, 2.3, drum.y, 1.6, V_GOLD.x, 0.4, 0.8)
	_add_solid(p.x, p.y, r + 0.3)
	_add_solid(drum.x, drum.y, 1.4, 2.5)
	_shadow(p.x, p.y, r + 1.5, 0.3)


## La source : un bassin d'eau bordé de pierres ; plus haut à chaque rang, une fontaine au dernier.
func _village_spring(p: Vector2, level: int) -> void:
	var r: int = 3
	for x: int in range(-r - 1, r + 2):
		for z: int in range(-r - 1, r + 2):
			var d: float = Vector2(x, z).length()
			if d <= r:
				_sv(p.x + x, 0.2, p.y + z, 1.0, V_WATER.x, V_WATER.y, V_WATER.z)
			elif d <= r + 1.2:
				for y: int in level:
					_sv(p.x + x, 0.5 + y * 0.8, p.y + z, 0.9, V_STONE.x, V_STONE.y, V_STONE.z + _rnd() * 0.05)
	if level >= 3:
		for y: int in 4:
			_sv(p.x, 1.0 + y * 0.9, p.y, 0.6 - y * 0.1, V_WATER.x, V_WATER.y, V_WATER.z + 0.1)
	_add_solid(p.x, p.y, r + 1.0, 1.0 + level * 0.8)
	_shadow(p.x, p.y, r + 1.5, 0.2)


## La scène : un plancher, deux mâts et un bandeau tissé aux couleurs volées.
func _village_stage(p: Vector2) -> void:
	for x: int in range(-4, 5):
		for z: int in range(-3, 4):
			_sv(p.x + x, 0.5, p.y + z, 1.0, V_WOOD.x, V_WOOD.y, V_WOOD.z + (0.06 if (x + z) % 2 == 0 else 0.0))
	var back: float = 3.0 if p.y > 0.0 else -3.0
	for side: int in [-4, 4]:
		for y: int in 7:
			_sv(p.x + side, 1.5 + y, p.y + back, 0.7, V_WOOD.x, V_WOOD.y, V_WOOD.z - 0.06)
	for x: int in range(-3, 4):
		for y: int in 2:
			var c: Vector3 = V_BANNER[posmod(x + y, V_BANNER.size())]
			_sv(p.x + x, 6.5 + y, p.y + back, 0.9, c.x, c.y, c.z)
	_add_solid(p.x, p.y, 4.2, 1.5)
	_shadow(p.x, p.y, 5.0, 0.25)


## Mare : un bassin d'eau (dessiné par WorldBuilder), bordé de pierres.
func _room_pond(x: float, z: float) -> void:
	var r: float = POND_RADIUS_MIN + _rnd() * (POND_RADIUS_MAX - POND_RADIUS_MIN)
	ponds.append_array(PackedFloat32Array([x, z, r]))
	var stones: int = floori(TAU * r / 1.2)
	for i: int in stones:
		var a: float = i / float(stones) * TAU + _rnd() * 0.2
		_sv(x + cos(a) * (r + 0.3), 0.2, z + sin(a) * (r + 0.3), 0.6 + _rnd() * 0.4, 4.6, 0.1, 0.4 + _rnd() * 0.12)


## Touffes d'herbe haute un peu partout dans la clairière et jusqu'au pied des arbres (on marche au
## travers).
func _grass(radius: float, count: int) -> void:
	for i: int in count:
		var a: float = _rnd() * TAU
		var r: float = sqrt(_rnd()) * (radius + ROOM_RING_GAP)
		var x: float = sin(a) * r
		var z: float = -cos(a) * r
		var hue: float = 0.27 + _rnd() * 0.12
		for b: int in 2 + floori(_rnd() * 3.0):
			var bx: float = x + (_rnd() - 0.5) * 0.9
			var bz: float = z + (_rnd() - 0.5) * 0.9
			for y: int in 1 + floori(_rnd() * 2.0):
				_sv(bx, 0.2 + y * 0.4, bz, 0.35, hue, 0.7, 0.3 + y * 0.06 + _rnd() * 0.05)


## Cailloux épars.
func _pebbles(radius: float, count: int) -> void:
	for i: int in count:
		var a: float = _rnd() * TAU
		var r: float = sqrt(_rnd()) * radius
		_sv(sin(a) * r, 0.15, -cos(a) * r, 0.3 + _rnd() * 0.3, 4.6, 0.08, 0.42 + _rnd() * 0.12)


func _room_log(x: float, z: float) -> void:
	_log(x, z, _rnd() * TAU)


## Point d'un passage de la clairière (u) : sur le bord, à l'angle `angle` (depuis le nord).
static func gap_point(angle: float, radius: float) -> Vector2:
	return Vector2(sin(angle), -cos(angle)) * radius


func _near_gap(angle: float, gaps: PackedFloat32Array) -> bool:
	for gap: float in gaps:
		if absf(angle_difference(angle, gap)) < ROOM_GAP_ANGLE:
			return true
	return false


## Pose `count` obstacles avec `builder` dans la clairière, loin du centre, des passages et des
## autres solides (marge `margin`).
func _room_place(builder: Callable, count: int, radius: float, gaps: PackedFloat32Array, margin: float) -> void:
	var placed: int = 0
	for t: int in ROOM_TRIES:
		if placed >= count:
			return
		var a: float = _rnd() * TAU
		var r: float = ROOM_CENTER_CLEAR + _rnd() * (radius - ROOM_CENTER_CLEAR - margin)
		var p := Vector2(sin(a), -cos(a)) * r
		var lane: bool = false
		for gap: float in gaps:
			if segment_distance(p, Vector2.ZERO, gap_point(gap, radius)) < ROOM_LANE + margin:
				lane = true
		if lane or not _free_spot(p, margin + 1.5):
			continue
		builder.call(p.x, p.y)
		placed += 1


func voxel_count() -> int:
	return voxels.size() / STRIDE


## Nom de la direction d'un point vu du village : « du Nord », « de l'Est »…
static func direction_name(p: Vector2) -> String:
	var sector: int = floori(atan2(p.x, -p.y) / (PI / 4.0) + 0.5)
	return DIRS[posmod(sector, DIRS.size())]


## Vrai si `p` est à moins de `margin` d'un chemin (du village à chaque sanctuaire).
func near_path(p: Vector2, margin: float) -> bool:
	for s: Vector2 in sanctuaries:
		if segment_distance(p, Vector2.ZERO, s) < margin:
			return true
	return false


## Distance de `p` au segment [a, b] (même calcul que le prototype).
static func segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var k: float = clampf(((p.x - a.x) * ab.x + (p.y - a.y) * ab.y) / (ab.x * ab.x + ab.y * ab.y), 0.0, 1.0)
	return Vector2(p.x - a.x - ab.x * k, p.y - a.y - ab.y * k).length()


## Hauteur du sol sous (x, z) pour des pieds à la hauteur `y` (dessus des solides franchissables).
func ground_at(x: float, z: float, y: float) -> float:
	var ground: float = 0.0
	for s: Solid in solids:
		if s.h >= WALL or s.h > y + 0.45 or s.h <= ground:
			continue
		if Vector2(x - s.x, z - s.z).length() < s.r:
			ground = s.h
	return ground


func _rnd() -> float:
	return _rng.next()


func _sv(x: float, y: float, z: float, size: float, hue: float, saturation: float, lightness: float) -> void:
	# Couleurs du monde (mode 0 : feuillages, herbes) : la région décale leur teinte.
	if hue < 1.0 and foliage_shift != 0.0:
		hue = fposmod(hue + foliage_shift, 1.0)
	voxels.append_array(PackedFloat32Array([x, y, z, hue, saturation, lightness, size]))


func _add_solid(x: float, z: float, r: float, h: float = WALL, kind: StringName = &"") -> void:
	solids.append(Solid.new(x, z, r, h, kind))


func _shadow(x: float, z: float, r: float, alpha: float) -> void:
	shadows.append_array(PackedFloat32Array([x, z, r, alpha]))


## Une clairière libre pour le cercle des gongs, près d'un chemin (Vector2.INF si aucune).
func _find_clearing(rng: ProtoRandom) -> Vector2:
	for t: int in CLEARING_TRIES:
		var a: float = rng.next() * TAU
		var r: float = CLEARING_MIN + rng.next() * (CLEARING_MAX - CLEARING_MIN)
		var p := Vector2(cos(a) * r, sin(a) * r)
		if near_path(p, CLEARING_R) or not near_path(p, CLEARING_R + CLEARING_PATH):
			continue
		if near_sanctuary(p, CLEARING_SANCTUARY) or not _free_spot(p, CLEARING_R):
			continue
		return p
	return Vector2.INF


func _free_spot(p: Vector2, margin: float) -> bool:
	for s: Solid in solids:
		if Vector2(p.x - s.x, p.y - s.z).length() < s.r + margin:
			return false
	return true


func _near_any(p: Vector2, points: PackedVector2Array, distance: float) -> bool:
	for q: Vector2 in points:
		if p.distance_to(q) < distance:
			return true
	return false


## Vrai si `p` est à moins de `distance` d'un sanctuaire.
func near_sanctuary(p: Vector2, distance: float) -> bool:
	return _near_any(p, sanctuaries, distance)


func _add_village_solids() -> void:
	_add_solid(CHIEF.x, CHIEF.y, CHIEF_R)
	for p: Vector2 in DANCERS:
		_add_solid(p.x, p.y, DANCER_R)
	for p: Vector2 in SLOTS:
		_add_solid(p.x, p.y, SLOT_R, SLOT_H)


## Autel du sanctuaire, cercle de huit piliers, et tronc couché en travers du chemin.
func _sanctuary(s: Vector2) -> void:
	for x: int in range(-2, 3):
		for z: int in range(-2, 3):
			for y: int in 2:
				_sv(s.x + x, y + 0.5, s.y + z, 1.0, 4.72, 0.18, 0.3 + _rnd() * 0.06)
	_add_solid(s.x, s.y, 2.6, ALTAR_HEIGHT)
	for i: int in 8:
		var a: float = float(i) / 8.0 * TAU + 0.2
		var px: float = s.x + cos(a) * 9.0
		var pz: float = s.y + sin(a) * 9.0
		var h: int = 3 + floori(_rnd() * 3.0)
		for y: int in h:
			_sv(px, y * 1.1 + 0.55, pz, 1.1, 4.74, 0.15, 0.28 + _rnd() * 0.06)
		_add_solid(px, pz, 0.9, h * 1.1)
	var d: float = s.length()
	_log(s.x / d * 22.0, s.y / d * 22.0, atan2(s.x, -s.y))


## Totem du village : il grandit avec les nuits accomplies.
func _totem(nights_done: int) -> void:
	totem_height = 3 + 2 * mini(6, nights_done)
	for y: int in totem_height:
		for a: int in 2:
			for b: int in 2:
				_sv(a - 0.5, y + 0.5, TOTEM.y + b - 0.5, 1.0, 1.0 + fmod(y * 0.13, 1.0), 0.85, 0.5 + (y % 2) * 0.08)
	_sv(0.0, totem_height + 0.8, TOTEM.y, 1.3, 3.1, 1.0, 0.62)
	_add_solid(TOTEM.x, TOTEM.y, TOTEM_R)


func _forest() -> void:
	var spots := PackedVector2Array()
	var count: int = 34 + floori(_rnd() * 14.0)
	var tries: int = 0
	while spots.size() < count and tries < 5000:
		tries += 1
		var a: float = _rnd() * TAU
		var r: float = 18.0 + _rnd() * 64.0
		var p := Vector2(cos(a) * r, sin(a) * r)
		if near_path(p, 5.5) or near_sanctuary(p, 14.0) or _near_any(p, huts, 8.0):
			continue
		if _near_any(p, spots, 7.5):
			continue
		spots.append(p)
		_tree(p.x, p.y, 1.0, true, 0)


## Pose `count` éléments avec `builder` entre les rayons `r_min` et `r_max`, loin des chemins,
## des sanctuaires et des autres solides (marge `margin`).
func _place(margin: float, builder: Callable, count: int, r_min: float, r_max: float, tries: int) -> void:
	var k: int = 0
	var t: int = 0
	while k < count and t < tries:
		t += 1
		var a: float = _rnd() * TAU
		var r: float = r_min + _rnd() * (r_max - r_min)
		var p := Vector2(cos(a) * r, sin(a) * r)
		if near_path(p, 3.2 + margin) or near_sanctuary(p, 11.0 + margin) or not _free_spot(p, margin + 1.5):
			continue
		builder.call(p.x, p.y)
		k += 1


func _tree(tx: float, tz: float, k: float, solid: bool, fixed_r: int) -> void:
	var vs: float = 1.1 * k
	var h: int = 8 + floori(_rnd() * 6.0)
	var big_r: int = fixed_r if fixed_r > 0 else 3 + floori(_rnd() * 2.0)
	var hue: float = 0.22 + _rnd() * 0.25
	for y: int in h:
		for a: int in 2:
			for b: int in 2:
				_sv(tx + (a - 0.5) * vs, (y + 0.5) * vs, tz + (b - 0.5) * vs, vs, 4.07, 0.5, 0.26)
	var n: int = big_r + 1
	for x: int in range(-n, n + 1):
		for y: int in range(-n, n + 1):
			for z: int in range(-n, n + 1):
				var d: float = Vector3(x, y, z).length()
				if d > big_r + 0.35 or d <= big_r - 1.3:
					continue
				_sv(tx + x * vs, (h + y + 0.5 + big_r * 0.6) * vs, tz + z * vs, vs, fmod(hue + d * 0.02 + y * 0.012, 1.0), 0.8, 0.42 + _rnd() * 0.12)
	if solid:
		_add_solid(tx, tz, 1.3 * vs)
	_shadow(tx, tz, (big_r + 0.5) * vs, 0.3)


func _mushroom(mx: float, mz: float) -> void:
	var vs: float = 0.9
	var h: int = 3 + floori(_rnd() * 3.0)
	var r: float = 2.5 + _rnd() * 1.5
	var hue: float = _rnd() * 0.99
	for y: int in h:
		for a: int in 2:
			for b: int in 2:
				_sv(mx + (a - 0.5) * vs, (y + 0.5) * vs, mz + (b - 0.5) * vs, vs, 4.12, 0.25, 0.82)
	var n: int = ceili(r)
	for x: int in range(-n, n + 1):
		for z: int in range(-n, n + 1):
			var d: float = Vector2(x, z).length()
			if d > r:
				continue
			var top: int = 2 if d < r * 0.55 else (1 if d < r * 0.85 else 0)
			for y: int in top + 1:
				var dot: bool = y == top and (x * 7 + z * 13) % 5 == 0
				if dot:
					_sv(mx + x * vs, (h + y + 0.5) * vs, mz + z * vs, vs, 1.0 + fmod(hue + 0.5, 1.0) * 0.99, 0.5, 0.85)
				else:
					_sv(mx + x * vs, (h + y + 0.5) * vs, mz + z * vs, vs, 1.0 + hue, 0.95, 0.55)
	_add_solid(mx, mz, 1.1)
	_shadow(mx, mz, r * vs, 0.22)


func _hut(hx: float, hz: float) -> void:
	var r: float = 3.2
	var door: float = atan2(-hz, -hx)
	for x: int in range(-4, 5):
		for z: int in range(-4, 5):
			var d: float = Vector2(x, z).length()
			if d > r or d <= r - 1.1:
				continue
			var angle: float = atan2(z, x)
			var is_door: bool = absf(_lerp_angle_full(angle, door) - angle) < 0.45
			for y: int in 3:
				if is_door and y < 2:
					continue
				_sv(hx + x, y + 0.5, hz + z, 1.0, 4.08, 0.35, 0.33 + _rnd() * 0.06)
	for l: int in 4:
		var lr: float = r + 0.8 - l * 1.1
		for x: int in range(-5, 6):
			for z: int in range(-5, 6):
				if Vector2(x, z).length() <= lr:
					_sv(hx + x, 3.5 + l, hz + z, 1.0, 4.12, 0.55, 0.42 + _rnd() * 0.08)
	_add_solid(hx, hz, r + 0.3)
	_shadow(hx, hz, r + 1.5, 0.3)


## Champignon-trampoline : bas et large, il renvoie très haut.
func _bouncer(mx: float, mz: float) -> void:
	var hue: float = _rnd() * 0.99
	_sv(mx, 0.45, mz, 0.9, 4.12, 0.2, 0.85)
	for x: int in range(-2, 3):
		for z: int in range(-2, 3):
			if Vector2(x, z).length() > 2.3:
				continue
			if (x + z) % 2 != 0:
				_sv(mx + x * 0.8, 1.05, mz + z * 0.8, 0.8, 1.0 + hue, 0.95, 0.6)
			else:
				_sv(mx + x * 0.8, 1.05, mz + z * 0.8, 0.8, 1.0 + fmod(hue + 0.5, 1.0), 0.7, 0.82)
	_add_solid(mx, mz, 1.8, 1.45, BOUNCE)
	_shadow(mx, mz, 2.3, 0.22)


func _random_rock(x: float, z: float) -> void:
	var r: float = 1.6 + _rnd() * 1.4
	var h: float = 1.4 + floori(_rnd() * 3.0) * 0.8
	_rock(x, z, r, h)


func _rock(x: float, z: float, r: float, h: float) -> void:
	var n: int = ceili(r)
	var layers: int = floori(h / 0.9 + 0.5)
	for l: int in layers:
		var rl: float = r * (1.0 - float(l) / layers * 0.28)
		for a: int in range(-n, n + 1):
			for b: int in range(-n, n + 1):
				var d: float = Vector2(a, b).length()
				if d > rl:
					continue
				var y: float = (l + 0.5) * (h / layers)
				if l == layers - 1:
					var hue: float = 4.3 + _rnd() * 0.05
					_sv(x + a * 0.9, y, z + b * 0.9, 0.92, hue, 0.45, 0.42 + _rnd() * 0.06)
				else:
					_sv(x + a * 0.9, y, z + b * 0.9, 0.92, 4.72, 0.14, 0.34 + _rnd() * 0.07)
	_add_solid(x, z, r * 0.9 + 0.2, h)
	_shadow(x, z, r + 0.9, 0.28)


func _stump(x: float, z: float) -> void:
	var h: float = 1.3 + floori(_rnd() * 3.0) * 0.45
	var r: float = 1.4
	var layers: int = floori(h / 0.7 + 0.5)
	for a: int in range(-2, 3):
		for b: int in range(-2, 3):
			var d: float = Vector2(a, b).length()
			if d > 1.9:
				continue
			for y: int in layers:
				var px: float = x + a * 0.7
				var py: float = (y + 0.5) * 0.7
				var pz: float = z + b * 0.7
				if y == layers - 1:
					if d < 1.0:
						_sv(px, py, pz, 0.72, 2.09, 0.45, 0.62)
					else:
						_sv(px, py, pz, 0.72, 2.08, 0.5, 0.45)
				else:
					_sv(px, py, pz, 0.72, 4.07, 0.5, 0.25)
	_add_solid(x, z, r, h)
	_shadow(x, z, 2.0, 0.26)


## Tronc couché en travers d'un chemin : à sauter.
func _log(cx: float, cz: float, angle: float) -> void:
	var dx: float = cos(angle)
	var dz: float = sin(angle)
	for i: int in range(-4, 5):
		var x: float = cx + dx * i * 0.8
		var z: float = cz + dz * i * 0.8
		for y: int in 2:
			for k: int in range(-1, 1):
				_sv(x - dz * k * 0.8, (y + 0.5) * 0.7, z + dx * k * 0.8, 0.8, 4.07, 0.5, 0.27 + (0.03 if i % 2 != 0 else 0.0))
		if i % 2 == 0:
			_add_solid(x, z, 0.85, LOG_HEIGHT)
	_sv(cx + dx * 3.6, 1.7, cz + dz * 3.6, 0.5, 1.3, 0.8, 0.5)


## Perchoir : trois rochers en escalier, une plume dorée au sommet.
func _perch(x: float, z: float) -> void:
	var a: float = _rnd() * TAU
	var top := Vector3.ZERO
	for step: Vector3 in [Vector3(0.0, 1.5, 1.4), Vector3(2.6, 1.4, 2.8), Vector3(5.0, 1.6, 4.3)]:
		var px: float = x + cos(a) * step.x
		var pz: float = z + sin(a) * step.x
		_rock(px, pz, step.y, step.z)
		top = Vector3(px, step.z, pz)
	pickups.append(Vector3(top.x, top.y + PERCH_ABOVE, top.z))


## lerpAng(a, b, 1) du prototype : b ramené à moins d'un demi-tour de a.
static func _lerp_angle_full(a: float, b: float) -> float:
	var d: float = fmod(fmod(b - a + PI, TAU) + TAU, TAU) - PI
	return a + d
