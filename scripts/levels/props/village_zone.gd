extends Area3D
## Le village : le héros y reprend des forces (soin continu).


func _physics_process(delta: float) -> void:
	for body: Node3D in get_overlapping_bodies():
		var hero: Hero = body as Hero
		if hero:
			hero.health.heal(Tuning.data.village_heal_rate * delta)
