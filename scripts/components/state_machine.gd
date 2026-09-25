class_name StateMachine
extends Node
## Machine à états générique : chaque enfant est un State, désigné par son nom de nœud.
## Le propriétaire appelle start() une fois prêt, puis physics_update() à chaque image physique,
## ce qui garde l'ordre d'exécution explicite.

signal state_changed(previous: StringName, current: StringName)

## État actif au démarrage.
@export var initial_state: State

## État actif.
var current: State


func start() -> void:
	for child: Node in get_children():
		var state: State = child as State
		if state:
			state.machine = self
	current = initial_state
	current.enter(&"")


func physics_update(delta: float) -> void:
	current.physics_update(delta)


## Quitte l'état actif et entre dans l'état nommé `state_name` (même s'il s'agit de l'état actif).
func transition_to(state_name: StringName) -> void:
	var next: State = get_node(NodePath(String(state_name))) as State
	assert(next != null, "état inconnu : %s" % state_name)
	var previous: StringName = current.name
	current.exit()
	current = next
	current.enter(previous)
	state_changed.emit(previous, current.name)
