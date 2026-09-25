class_name MuetShapes
## Formes voxel des Muets du prototype (makeMuet) : une boule creuse de cubes (ventre plus clair),
## deux petits pieds, de grands yeux, la bouche cousue (ou le bec du cracheur), des antennes aux
## couleurs volées ; les cornes du cornu, les ailes du volant, le bouclier du porte-bouclier, la
## couronne des Grands Muets (et la flèche du Roi Muet). Tout est en cases ; le corps est mis à
## l'échelle par l'espèce (Tuning.<espèce>_scale).

## Rayon de la boule (cases) et teinte de chaque forme.
const RADIUS := {&"hop": 2.2, &"fly": 1.7, &"shield": 2.1, &"charge": 2.6, &"spit": 2.3}
const HUE := {&"hop": 0.74, &"fly": 0.56, &"shield": 0.8, &"charge": 0.95, &"spit": 0.86}
const BOSS_RADIUS := 3.3
const KING_RADIUS := 3.8
const BOSS_HUE := 0.7
const KING_HUE := 0.8
## Épaisseur de la coquille de cubes (cases).
const SHELL := 1.45
## Les couleurs sont fixes (mode 2) : le silence ne les boit pas.
const FIXED := 2.0
const RAINBOW := 3.0


## Forme `kind` (hop, fly, shield, charge, spit), Grand Muet ou Roi Muet. `tip_hue` (0 à 1) :
## couleur des bouts d'antennes. Renvoie les cellules de chaque partie (body, eyes, wing_left,
## wing_right, shield) et leurs points d'attache (wing_left_at…), le rayon de la boule (radius).
static func build(kind: StringName, boss: bool, king: bool, tip_hue: float) -> Dictionary:
	var r: float = KING_RADIUS if king else (BOSS_RADIUS if boss else float(RADIUS[kind]))
	var hue: float = (KING_HUE if king else BOSS_HUE) if boss else float(HUE[kind])
	var body := PackedFloat32Array()
	var eyes := PackedFloat32Array()
	var n: int = ceili(r) + 1
	for x: int in range(-n, n + 1):
		for y: int in range(-n, n + 1):
			for z: int in range(-n, n + 1):
				var d: float = Vector3(x, y * 1.1, z).length()
				if d > r or d < r - SHELL:
					continue
				var belly: bool = z > r * 0.3 and y < r * 0.15 and absf(x) < r * 0.75
				var shade: float = posmod(x * 3 + y * 5 + z * 7, 4) * 0.035
				VoxelMesh.add(body, x, y, z, Vector3(FIXED + hue, 0.35 if belly else 0.55, 0.62 if belly else 0.33 + shade))
	if kind != &"fly" or boss:
		for sx: float in [-1.0, 1.0]:
			VoxelMesh.add(body, sx, -r - 0.1, 0.3, Vector3(FIXED + hue, 0.35, 0.18), 0.8)
	var front: float = floorf(r)
	var ex: float = 1.25 if boss else 0.95
	var ey: float = 0.5
	for sx: float in [-1.0, 1.0]:
		VoxelMesh.add(eyes, sx * ex, ey, front + 0.3, Vector3(FIXED, 0.0, 0.97), 1.25 if boss else 1.05)
		VoxelMesh.add(eyes, sx * ex + sx * 0.05, ey - 0.05, front + 0.82, Vector3(FIXED, 0.0, 0.05), 0.62 if boss else 0.55)
		VoxelMesh.add(eyes, sx * ex + sx * 0.18 + 0.1, ey + 0.26, front + 1.04, Vector3(FIXED, 0.0, 1.0), 0.22)
		if boss or kind == &"charge":
			VoxelMesh.add(body, sx * (ex - 0.45), ey + 0.9, front + 0.1, Vector3(FIXED, 0.0, 0.06), 0.6)
			VoxelMesh.add(body, sx * (ex + 0.4), ey + 1.18, front, Vector3(FIXED, 0.0, 0.06), 0.6)
	if kind == &"spit" and not boss:
		VoxelMesh.add(body, 0.0, -0.4, front + 0.6, Vector3(FIXED + hue, 0.35, 0.32), 0.85)
		VoxelMesh.add(body, 0.0, -0.4, front + 1.3, Vector3(FIXED + hue, 0.35, 0.36), 0.75)
		VoxelMesh.add(body, 0.0, -0.4, front + 1.95, Vector3(FIXED + 0.08, 0.6, 0.42), 0.72)
	else:
		var w: int = 3 if boss else 1
		for i: int in range(-w, w + 1):
			VoxelMesh.add(body, i * 0.38, -0.45, front + 0.5, Vector3(FIXED, 0.0, 0.95 if posmod(i + 4, 2) == 1 else 0.06), 0.36)
	if not boss and kind != &"charge":
		for sx: float in [-1.0, 1.0]:
			for i: int in 3:
				VoxelMesh.add(body, sx * (0.8 + i * 0.14), r + 0.15 + i * 0.42, -0.2, Vector3(FIXED + hue, 0.3, 0.22), 0.32)
			VoxelMesh.add(body, sx * 1.22, r + 1.45, -0.2, Vector3(RAINBOW + tip_hue * 0.99, 1.0, 0.6), 0.62)
	if kind == &"charge" and not boss:
		for sx: float in [-1.0, 1.0]:
			VoxelMesh.add(body, sx * 1.8, r - 0.5, 0.6, Vector3(FIXED + 0.12, 0.25, 0.86), 0.9)
			VoxelMesh.add(body, sx * 2.4, r, 0.9, Vector3(FIXED + 0.12, 0.25, 0.88), 0.8)
			VoxelMesh.add(body, sx * 2.7, r + 0.7, 1.1, Vector3(FIXED + 0.12, 0.2, 0.92), 0.7)
	if boss:
		var cr: float = r * 0.55
		var top: float = r - 0.35
		for i: int in 10:
			var a: float = i / 10.0 * TAU
			var cx: float = cos(a) * cr
			var cz: float = sin(a) * cr
			VoxelMesh.add(body, cx, top, cz, Vector3(FIXED + 0.13, 0.9, 0.55), 0.9)
			if i % 2 == 0:
				VoxelMesh.add(body, cx, top + 0.8, cz, Vector3(FIXED + 0.13, 0.9, 0.6), 0.7)
			else:
				VoxelMesh.add(body, cx, top + 0.6, cz, Vector3(RAINBOW + i / 10.0, 1.0, 0.6), 0.5)
		if king:
			for i: int in 5:
				VoxelMesh.add(body, 0.0, top + 1.2 + i * 0.6, 0.0, Vector3(RAINBOW + 0.5 if i == 4 else FIXED + 0.13, 0.9, 0.6), 0.8 - i * 0.08)
	var shape: Dictionary = {&"body": body, &"eyes": eyes, &"radius": r}
	if kind == &"fly" and not boss:
		for sx: float in [-1.0, 1.0]:
			var wing := PackedFloat32Array()
			for i: int in 4:
				for j: int in 3 - (1 if i > 1 else 0):
					VoxelMesh.add(wing, sx * (i + 0.5), j * 0.8 - 0.2, -0.3, Vector3(RAINBOW + i * 0.12, 0.9, 0.6), 0.85)
			var side: String = "left" if sx < 0.0 else "right"
			shape[StringName("wing_" + side)] = wing
			shape[StringName("wing_%s_at" % side)] = Vector3(sx * (r - 0.4), 0.6, 0.0)
	if kind == &"shield" and not boss:
		var plate := PackedFloat32Array()
		for x: int in range(-2, 3):
			for y: int in range(-2, 3):
				var d: float = Vector2(x, y).length()
				if d > 2.4:
					continue
				VoxelMesh.add(plate, x, y, 0.0, Vector3(FIXED + 0.08, 0.5, 0.3 if d > 1.6 else 0.42))
		VoxelMesh.add(plate, -0.4, 0.0, 0.5, Vector3(FIXED, 0.0, 0.9), 0.4)
		VoxelMesh.add(plate, 0.0, 0.0, 0.5, Vector3(FIXED, 0.0, 0.1), 0.4)
		VoxelMesh.add(plate, 0.4, 0.0, 0.5, Vector3(FIXED, 0.0, 0.9), 0.4)
		shape[&"shield"] = plate
		shape[&"shield_at"] = Vector3(0.0, -0.2, front + 1.3)
	return shape


## Hauteur du corps (cases, avant mise à l'échelle) : le diamètre de la boule.
static func height(radius: float) -> float:
	return 2.0 * radius


## Hauteur du centre de la boule au-dessus du sol (cases) : les pieds touchent terre.
static func center_height(radius: float) -> float:
	return radius + 0.5
