class_name HitData
extends RefCounted
## Un coup reçu : qui frappe, combien, d'où, et avec quels retours d'impact.

## Nœud qui porte le coup.
var attacker: Node3D
## Dégâts à retirer.
var damage: float = 0.0
## Vrai pour un coup critique.
var critical: bool = false
## Direction horizontale du coup (de l'attaquant vers la cible, normalisée).
var direction: Vector3 = Vector3.ZERO
## Point de contact, pour l'étincelle.
var point: Vector3 = Vector3.ZERO
## Nom du coup (AttackData.id, ou « dive » pour le plongeon).
var move: StringName = &""
