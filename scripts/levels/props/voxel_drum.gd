class_name VoxelDrum
extends Node3D
## Tambour du prototype en voxels : un fût à bandes de deux couleurs (la teinte de son sanctuaire
## et sa complémentaire) et une peau claire. Chaque sanctuaire a sa teinte.

## Teinte de chaque sanctuaire (0 à 1).
const HUES: Array[float] = [0.0, 0.33, 0.66]
## Peau du tambour (teinte bue par le silence, claire).
const SKIN := Vector3(4.1, 0.25, 0.85)
## Fût : couleurs vives (mode 1), saturation, luminosité ; rayons du fût et du vide intérieur,
## hauteur (cases).
const SHELL_MODE := 1.0
const SHELL_SATURATION := 0.95
const SHELL_LIGHTNESS := 0.5
const OUTER := 2.75
const INNER := 1.7
const BARREL := 4
const REACH := 3

## Sanctuaire du tambour (sa teinte).
@export var hue_index: int = 0:
	set(value):
		hue_index = value
		if is_inside_tree():
			_build()
@export var material: Material

var _cubes: MultiMeshInstance3D


func _ready() -> void:
	_build()


## Cellules du tambour de teinte `hue`.
static func cells(hue: float) -> PackedFloat32Array:
	var list := PackedFloat32Array()
	for ix: int in range(-REACH, REACH + 1):
		for iz: int in range(-REACH, REACH + 1):
			var d: float = Vector2(ix, iz).length()
			if d > OUTER:
				continue
			for y: int in BARREL:
				if d > INNER:
					var h: float = hue if y % 2 == 1 else fmod(hue + 0.5, 1.0)
					VoxelMesh.add(list, ix, y + 0.5, iz, Vector3(SHELL_MODE + h, SHELL_SATURATION, SHELL_LIGHTNESS))
			VoxelMesh.add(list, ix, BARREL + 0.5, iz, SKIN)
	return list


func _build() -> void:
	if _cubes:
		_cubes.queue_free()
	_cubes = VoxelMesh.create(cells(HUES[posmod(hue_index, HUES.size())]), material)
	_cubes.scale = Vector3.ONE * Tuning.data.drum_voxel * Tuning.data.voxel_unit
	add_child(_cubes)
