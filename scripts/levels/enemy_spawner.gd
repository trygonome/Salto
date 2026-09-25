extends Marker3D
## Fait apparaître un Muet à cet endroit. S'il a un délai de réapparition (parcours d'essai),
## le Muet revient un moment après sa libération ; sinon il est libéré pour la nuit.

## Le Muet de ce point vient d'être libéré.
signal muet_freed(muet: Muet)

## Muet à faire apparaître.
@export var scene: PackedScene
## Délai avant de réapparaître (s ; 0 = ne revient pas).
@export var respawn_delay: float
## Butin qui jaillit à la libération (facultatif : le Grand Muet en laisse toujours un).
@export var loot_scene: PackedScene


func _ready() -> void:
	_spawn.call_deferred()


func _spawn() -> void:
	var muet: Muet = scene.instantiate() as Muet
	muet.position = position
	get_parent().add_child(muet)
	muet.freed.connect(_on_freed)


func _on_freed(muet: Muet) -> void:
	muet_freed.emit(muet)
	if loot_scene:
		var loot: Node3D = loot_scene.instantiate() as Node3D
		get_parent().add_child(loot)
		loot.global_position = muet.global_position
	if respawn_delay > 0.0:
		get_tree().create_timer(respawn_delay, false).timeout.connect(_spawn)
