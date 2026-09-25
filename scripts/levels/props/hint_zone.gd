extends Area3D
## Zone d'aide contextuelle : quand le héros y entre, le bon bouton brille avec 2 à 4 mots ;
## l'aide disparaît dès que l'action est faite (et ne revient plus), ou quand il sort.

## Nom de l'aide (gardé dans le profil une fois suivie).
@export var hint: StringName
## Action à faire : move (joystick), jump, attack ou dodge.
@export var action: StringName
## Texte de l'aide (2 à 4 mots).
@export var text: String


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body is Hero and not Game.profile.is_hint_done(hint):
		get_tree().call_group(&"hud", &"show_hint", hint, action, text)


func _on_body_exited(body: Node3D) -> void:
	if body is Hero:
		get_tree().call_group(&"hud", &"hide_hint", hint)
