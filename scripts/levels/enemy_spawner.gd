extends Marker3D
## Fait apparaître un Muet à cet endroit, puis le fait réapparaître un moment après sa
## libération (parcours d'essai : on peut rejouer chaque attaque autant qu'on veut).

## Muet à faire apparaître.
@export var scene: PackedScene
## Délai avant de réapparaître (s).
@export var respawn_delay: float


func _ready() -> void:
	_spawn.call_deferred()


func _spawn() -> void:
	var muet: Muet = scene.instantiate() as Muet
	muet.position = position
	get_parent().add_child(muet)
	muet.freed.connect(_on_freed)


func _on_freed(_muet: Muet) -> void:
	get_tree().create_timer(respawn_delay, false).timeout.connect(_spawn)
