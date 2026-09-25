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
	voxels.append_array(PackedFloat32Array([x, y, z, hue, saturation, lightness, size]))


func _add_solid(x: float, z: float, r: float, h: float = WALL, kind: StringName = &"") -> void:
	solids.append(Solid.new(x, z, r, h, kind))


func _shadow(x: float, z: float, r: float, alpha: float) -> void:
	shadows.append_array(PackedFloat32Array([x, z, r, alpha]))


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
	pickups.append(Vector3(top.x, top.y + 1.2, top.z))


## lerpAng(a, b, 1) du prototype : b ramené à moins d'un demi-tour de a.
static func _lerp_angle_full(a: float, b: float) -> float:
	var d: float = fmod(fmod(b - a + PI, TAU) + TAU, TAU) - PI
	return a + d
