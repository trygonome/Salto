class_name AttackData
extends Resource
## Un coup du héros : minutage, zone touchée, dégâts, élan et animation.
## Les coups vivent dans res://data/tuning.tres (valeurs de départ : docs/REGLAGES.md).

## Nom du coup, pour la mise au point et les tests.
@export var id: StringName
## Clip joué (bibliothèque/nom).
@export var animation: StringName
## Instant du clip où le coup porte (s) : calé sur `impact` pendant le jeu.
@export var animation_impact: float
## Durée totale du coup (s).
@export var duration: float
## Instant où le coup touche (s).
@export var impact: float
## Instant à partir duquel on peut enchaîner le coup suivant (s).
@export var chain_from: float
## Portée, à ajouter au rayon de la cible (m).
@export var reach: float
## Ouverture de la zone touchée, centrée sur le regard (degrés ; 360 = tout autour).
@export var arc_deg: float
## Multiplicateur de dégâts.
@export var damage_multiplier: float
## Distance parcourue vers l'avant entre le début du coup et l'impact (m).
@export var lunge: float
## Vitesse verticale donnée au début du coup, pour un petit bond (m/s ; 0 = au sol).
@export var hop_speed: float
## Rotation visuelle du corps pendant le coup : clés (temps en s, lacet en degrés), interpolées.
@export var spin_keys: PackedVector2Array


## Temps dans le clip pour le temps `t` du coup : la préparation est comprimée (ou étirée)
## pour que le coup porte exactement à `impact`, puis la fin du clip remplit le reste du coup.
func animation_time(t: float, clip_length: float) -> float:
	if t <= impact:
		return animation_impact * maxf(t, 0.0) / impact
	var after: float = clampf((t - impact) / (duration - impact), 0.0, 1.0)
	return lerpf(animation_impact, clip_length, after)


## Lacet visuel (degrés) au temps `t` du coup ; 0 s'il n'y a pas de clés.
func yaw_offset_deg(t: float) -> float:
	return sample_keys(spin_keys, t)


## Valeur interpolée linéairement entre des clés (x, y) triées par x ; constante hors des bornes.
static func sample_keys(keys: PackedVector2Array, x: float) -> float:
	if keys.is_empty():
		return 0.0
	if x <= keys[0].x:
		return keys[0].y
	for i: int in range(1, keys.size()):
		if x <= keys[i].x:
			var span: float = keys[i].x - keys[i - 1].x
			return lerpf(keys[i - 1].y, keys[i].y, (x - keys[i - 1].x) / span)
	return keys[keys.size() - 1].y
