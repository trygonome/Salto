class_name ExitGate
extends Node3D
## Passage vers la clairière suivante : une arche de cubes aux couleurs de la récompense qu'il
## promet, avec son pictogramme qui flotte au-dessus. Il surgit du sol quand la clairière est
## nettoyée ; le héros le choisit en passant dessous.

## Le héros a pris ce passage.
signal chosen(reward: StringName)

## Pictogramme et couleur codée des cubes (mode 2, voir salto_voxel.gdshaderinc) de chaque
## récompense ; matériau des cubes, taille d'une case (m).
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

## Montants (cases : écart, hauteur), linteau.
const HALF_WIDTH := 7
const HEIGHT := 16
const WOOD := Vector3(2.07, 0.55, 0.28)
## Hauteur de départ de l'arche qui surgit (part de sa taille).
const RISE_FROM := 0.02

## Récompense promise.
var reward: StringName = &""

var _taken: bool = false
var _time: float = 0.0

@onready var _icon: Sprite3D = $Icon
@onready var _zone: Area3D = $Zone


func _ready() -> void:
	var color: Vector3 = colors.get(reward, WOOD)
	var cells := PackedFloat32Array()
	for side: int in [-1, 1]:
		for y: int in HEIGHT:
			VoxelMesh.add(cells, side * HALF_WIDTH, y + 0.5, 0.0, WOOD if y < HEIGHT - 3 else color, 1.3)
	for x: int in range(-HALF_WIDTH, HALF_WIDTH + 1):
		VoxelMesh.add(cells, x, HEIGHT + 0.5, 0.0, color, 1.4)
	var mesh: MultiMeshInstance3D = VoxelMesh.create(cells, material)
	add_child(mesh)
	_icon.texture = icons.get(reward)
	_icon.pixel_size = icon_pixel
	_zone.body_entered.connect(_on_body_entered)
	# L'arche surgit du sol (la zone, elle, ne change pas de taille).
	mesh.scale = Vector3(cell, cell * RISE_FROM, cell)
	create_tween().tween_property(mesh, "scale", Vector3.ONE * cell, rise_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_time += delta
	_icon.position.y = icon_height + sin(TAU * _time / bob_period) * bob_height


func _on_body_entered(body: Node3D) -> void:
	if _taken or not body is Hero:
		return
	_taken = true
	chosen.emit(reward)
