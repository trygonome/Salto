class_name VoxelStyles
## Styles et formes des personnages voxel du prototype (makeChar) : couleurs des parties
## (teinte + mode, saturation, luminosité) et cellules de chaque partie du corps.

## Peau des villageois (teinte fixe, bue par le silence).
const SKIN := Vector3(4.07, 0.42, 0.5)
const DANCER_HAIR := Vector3(4.05, 0.3, 0.14)
## Assombrissement de la peau des mains et des pieds.
const DARKEN := 0.12


## Style du Chef Taroum : cheveux blancs, collier, trois plumes.
static func chief() -> Dictionary:
	return {
		&"skin": SKIN, &"cloth": Vector3(0.95, 0.8, 0.45), &"trim": Vector3(0.12, 0.9, 0.55),
		&"hair": Vector3(4.0, 0.0, 0.85), &"necklace": true,
		&"feathers": [[3.0, Vector3(0.02, 0.9, 0.55)], [4.0, Vector3(0.3, 0.9, 0.55)], [3.0, Vector3(0.6, 0.9, 0.55)]],
	}


## Style du villageois `index` : vêtements de couleurs différentes, un bandeau sur deux.
static func dancer(index: int) -> Dictionary:
	var h: float = fmod(index * 0.17, 1.0)
	var style: Dictionary = {
		&"skin": SKIN, &"cloth": Vector3(h, 0.85, 0.5), &"trim": Vector3(fmod(h + 0.5, 1.0), 0.85, 0.55),
		&"hair": DANCER_HAIR,
	}
	if index % 2 == 1:
		style[&"band"] = Vector3(fmod(h + 0.25, 1.0), 0.9, 0.55)
	return style


## Cellules de chaque partie : pelvis, torso, head, eyes, thigh, shin, foot, upper, fore (et plume).
static func character_parts(o: Dictionary) -> Dictionary:
	var skin: Vector3 = o[&"skin"]
	var cloth: Vector3 = o[&"cloth"]
	var trim: Vector3 = o[&"trim"]
	var hair: Vector3 = o[&"hair"]
	var paint: Vector3 = o.get(&"paint", trim)
	var shoulder: Variant = o.get(&"shoulder")
	var band: Variant = o.get(&"band")
	var dark := Vector3(skin.x, skin.y, maxf(0.0, skin.z - DARKEN))
	var pelvis := PackedFloat32Array()
	var torso := PackedFloat32Array()
	var head := PackedFloat32Array()
	var eyes := PackedFloat32Array()
	var thigh := PackedFloat32Array()
	var shin := PackedFloat32Array()
	var foot := PackedFloat32Array()
	var upper := PackedFloat32Array()
	var fore := PackedFloat32Array()
	VoxelMesh.box(pelvis, -3, 3, 0, 2, -2, 2, func(_x: float, y: float, _z: float) -> Vector3: return trim if y > 1.0 else cloth)
	VoxelMesh.box(pelvis, -1, 1, -2, 0, 2, 3, func(_x: float, _y: float, _z: float) -> Vector3: return trim)
	VoxelMesh.box(pelvis, -2, 2, -1, 0, -3, -2, func(_x: float, _y: float, _z: float) -> Vector3: return cloth)
	VoxelMesh.box(torso, -3, 3, 0, 5, -2, 2, func(x: float, y: float, z: float) -> Vector3:
		return paint if z > 1.0 and (y == 2.5 or (y == 3.5 and absf(x) > 1.5)) else skin)
	VoxelMesh.box(torso, -1, 1, 5, 6, -1, 1, func(_x: float, _y: float, _z: float) -> Vector3: return skin)
	if o.get(&"necklace", false):
		var x: float = -1.5
		while x <= 1.5:
			VoxelMesh.add(torso, x, 4.4, 2.05, Vector3(3.0 + (x + 2.0) * 0.2, 1.0, 0.6), 0.55)
			x += 1.0
	VoxelMesh.box(head, -3, 3, 0, 6, -3, 3, func(x: float, y: float, z: float) -> Vector3:
		if y == 5.5 or z == -2.5 or (z == -1.5 and y > 2.5) or (absf(x) == 2.5 and y > 3.5 and z < 1.0):
			return hair
		if band != null and y == 4.5:
			return band
		return skin)
	for sx: float in [-1.0, 1.0]:
		VoxelMesh.add(eyes, sx * 1.4, 2.6, 2.75, Vector3(2.0, 0.0, 0.97), 1.08)
		VoxelMesh.add(eyes, sx * 1.45, 2.5, 3.25, Vector3(2.0, 0.0, 0.05), 0.6)
		VoxelMesh.add(eyes, sx * 1.25, 2.8, 3.52, Vector3(2.0, 0.0, 1.0), 0.2)
		VoxelMesh.add(head, sx * 1.4, 3.75, 2.95, hair, 0.42)
		VoxelMesh.add(head, sx * 2.25, 1.55, 2.92, Vector3(2.97, 0.7, 0.72), 0.5)
	VoxelMesh.add(head, -0.35, 1.3, 2.95, Vector3(2.98, 0.55, 0.32), 0.42)
	VoxelMesh.add(head, 0.35, 1.3, 2.95, Vector3(2.98, 0.55, 0.32), 0.42)
	var feathers: Array = o.get(&"feathers", [])
	for i: int in feathers.size():
		var feather: Array = feathers[i]
		var color: Vector3 = feather[1]
		VoxelMesh.box(head, i - 2, i - 1, 6, 6 + float(feather[0]), -2, -1, func(_x: float, _y: float, _z: float) -> Vector3: return color)
	VoxelMesh.box(thigh, -1, 1, -3, 0, -1, 1, func(_x: float, y: float, _z: float) -> Vector3: return cloth if y > -1.0 else skin)
	VoxelMesh.box(shin, -1, 1, -3, 0, -1, 1, func(_x: float, y: float, _z: float) -> Vector3: return trim if y < -2.0 else skin)
	VoxelMesh.box(foot, -1, 1, -1, 0, -1, 2, func(_x: float, _y: float, _z: float) -> Vector3: return dark)
	VoxelMesh.box(upper, -1, 1, -3, 0, -1, 1, func(_x: float, y: float, _z: float) -> Vector3:
		return shoulder if y > -1.0 and shoulder != null else skin)
	VoxelMesh.box(fore, -1, 1, -3, 0, -1, 1, func(_x: float, y: float, _z: float) -> Vector3: return trim if y < -2.0 else skin)
	VoxelMesh.box(fore, -1, 1, -5, -3, -1, 1, func(_x: float, _y: float, _z: float) -> Vector3: return dark)
	var parts: Dictionary = {
		&"pelvis": pelvis, &"torso": torso, &"head": head, &"eyes": eyes, &"thigh": thigh, &"shin": shin,
		&"foot": foot, &"upper": upper, &"fore": fore,
	}
	if o.has(&"plume"):
		var plume := PackedFloat32Array()
		for i: int in 5:
			VoxelMesh.add(plume, 0.0, i * 0.9 + 0.5, -i * 0.35, Vector3(1.0 + fmod(float(o[&"plume"]) + i * 0.08, 1.0), 1.0, 0.58), 1.0 - i * 0.1)
		parts[&"plume"] = plume
	return parts
