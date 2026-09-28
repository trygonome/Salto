class_name WeaponData
extends Resource
## Instrument-arme du héros (version 2.8), choisi avant de partir : son enchaînement de coups et
## son allure dans la main. Le bâton de pluie garde l'enchaînement de base ; les maracas jumelles
## frappent vite et court ; le tambour-marteau frappe lentement, tout autour ; la sarbacane tire des
## fléchettes (coups à distance, voir AttackData.projectiles).
## Les instruments vivent dans res://data/tuning.tres (Tuning.weapons).

@export var id: StringName
## Enchaînement de coups au sol (Frappe répétée).
@export var combo: Array[AttackData]
## Allure dans la main : forme (stick, maracas, hammer, pipe) et couleurs codées (voir VoxelMesh).
@export var shape: StringName
@export var main_color: Vector3
@export var accent_color: Vector3
