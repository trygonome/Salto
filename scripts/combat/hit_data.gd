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
## Nom du coup (AttackData.id, « dive » pour le plongeon, « rainbow » pour le Salto arc-en-ciel).
var move: StringName = &""
## Jugement rythmique de l'appui qui a lancé le coup.
var judgement: RhythmMath.Judgement = RhythmMath.Judgement.MISS
## Durée pendant laquelle la cible est étourdie (s ; 0 = pas d'étourdissement).
var stun_time: float = 0.0
## Vrai pour un gros coup (recul plus fort).
var big: bool = false
