extends Area3D
## Le village : le héros y reprend des forces (soin continu) et y grandit (l'expérience mise de
## côté pendant la sortie s'ajoute quand il arrive).


func _ready() -> void:
	body_entered.connect(func(body: Node3D) -> void:
		if body is Hero and Game.playing:
			Game.enter_village())
	body_exited.connect(func(body: Node3D) -> void:
		if body is Hero:
			Game.leave_village())


func _physics_process(delta: float) -> void:
	for body: Node3D in get_overlapping_bodies():
		var hero: Hero = body as Hero
		if hero:
			hero.health.heal(Tuning.data.village_heal_rate * delta)
