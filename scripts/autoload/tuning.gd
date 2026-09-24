extends Node
## Accès global aux réglages : Tuning.data.jump_speed, etc.
## Les valeurs se modifient dans res://data/tuning.tres, jamais dans le code.

var data: TuningData = preload("res://data/tuning.tres") as TuningData
