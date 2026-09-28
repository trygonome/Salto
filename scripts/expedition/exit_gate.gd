class_name ExitGate
extends Node3D
## Passage vers la clairière suivante (version 3.5 : porte-totem) : deux mâts sculptés de visages aux
## couleurs de la récompense promise, et, entre leurs sommets, l'icône voxel de cette récompense qui
## tourne doucement ; au sol, un seuil de pierres qui luit. Il surgit du sol quand la clairière est
## nettoyée ; le héros le choisit en passant entre les mâts.

## Le héros a pris ce passage.
signal chosen(reward: StringName)

## Anciens pictogrammes (plus affichés depuis la version 3.5, gardés pour la scène) ; couleur codée
## (mode 2, voir salto_voxel.gdshaderinc) de chaque récompense ; matériau des cubes, taille d'une
## case (m).
@export var icons: Dictionary[StringName, Texture2D]
@export var colors: Dictionary[StringName, Vector3]
@export var material: Material
@export var cell: float
## Pictogramme : hauteur (m), taille d'un pixel (m), balancement (m, s pour un aller-retour).
@export var icon_height: float
@export var icon_pixel: float
@export var bob_height: float
@export var bob_period: float
## Apparition : durée (s).
@export var rise_time: float

## Mâts (cases) : écart au centre, hauteur, un visage tous les FACE_STEP ; bois, bois sombre, encre.
const HALF_WIDTH := 6
const HEIGHT := 20
const FACE_STEP := 6
const WOOD := Vector3(2.07, 0.55, 0.28)
const WOOD_DARK := Vector3(2.06, 0.5, 0.18)
const INK := Vector3(2.75, 0.3, 0.12)
## Icône de la récompense : taille d'une case (m), vitesse de rotation (tours par seconde).
const ICON_CELL := 0.1
const ICON_SPIN := 0.25
## Hauteur de départ de la porte qui surgit (part de sa taille).
const RISE_FROM := 0.02

## Récompense promise.
var reward: StringName = &""

var _taken: bool = false
var _time: float = 0.0
var _emblem: Node3D

@onready var _icon: Sprite3D = $Icon
@onready var _zone: Area3D = $Zone


func _ready() -> void:
	var color: Vector3 = colors.get(reward, WOOD)
	var mesh: MultiMeshInstance3D = VoxelMesh.create(totem_cells(color), material)
	add_child(mesh)
	_icon.visible = false
	# L'icône voxel de la récompense, entre les sommets des mâts.
	_emblem = Node3D.new()
	_emblem.name = "Emblem"
	var icon: MultiMeshInstance3D = VoxelMesh.create(VoxelIcons.cells(reward), material)
	icon.scale = Vector3.ONE * ICON_CELL
	_emblem.add_child(icon)
	_emblem.position.y = icon_height
	add_child(_emblem)
	_zone.body_entered.connect(_on_body_entered)
	# La porte surgit du sol (la zone, elle, ne change pas de taille).
	mesh.scale = Vector3(cell, cell * RISE_FROM, cell)
	_emblem.scale = Vector3.ONE * RISE_FROM
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(mesh, "scale", Vector3.ONE * cell, rise_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_emblem, "scale", Vector3.ONE, rise_time).set_delay(rise_time * 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Cubes des deux mâts (une case par cube) : un visage sculpté tous les FACE_STEP (yeux et bouche
## aux couleurs de la récompense, `color`), des ailes au sommet, un seuil de pierres qui luit.
static func totem_cells(color: Vector3) -> PackedFloat32Array:
	var cells := PackedFloat32Array()
	for side: int in [-1, 1]:
		var x0: float = side * HALF_WIDTH
		for y: int in HEIGHT:
			var band: int = y % FACE_STEP
			for dx: int in range(-1, 2):
				for dz: int in range(-1, 1):
					var c: Vector3 = WOOD if band > 0 else WOOD_DARK
					# Visage tourné vers le passage : deux yeux, une bouche.
					if dz == 0 and band == 4 and dx != 0:
						c = color
					elif dz == 0 and band == 2 and dx == 0:
						c = INK
					VoxelMesh.add(cells, x0 + dx, y + 0.5, dz + 0.5, c)
		# Ailes au sommet, aux couleurs de la récompense.
		for k: int in 3:
			VoxelMesh.add(cells, x0 + side * (2 + k), HEIGHT - k - 0.5, 0.0, color)
		VoxelMesh.add(cells, x0, HEIGHT + 0.5, 0.0, color, 1.2)
	# Seuil : des pierres plates qui luisent de la couleur promise.
	for x: int in range(-HALF_WIDTH + 2, HALF_WIDTH - 1):
		VoxelMesh.add(cells, x, 0.1, 0.0, color if x % 2 == 0 else Vector3(4.6, 0.1, 0.5), 0.9)
	return cells


## Couleur d'interface de la récompense promise (voile du passage).
func veil_color() -> Color:
	var coded: Vector3 = colors.get(reward, WOOD)
	return WorldMood.hsl(coded.x - floorf(coded.x), coded.y, coded.z)


func _process(delta: float) -> void:
	_time += delta
	_emblem.position.y = icon_height + sin(TAU * _time / bob_period) * bob_height
	_emblem.rotation.y = TAU * ICON_SPIN * _time


func _on_body_entered(body: Node3D) -> void:
	if _taken or not body is Hero:
		return
	_taken = true
	chosen.emit(reward)
