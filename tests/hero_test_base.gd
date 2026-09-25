extends GutTest
## Base des tests du héros : un petit monde physique, le héros sans lecture des commandes
## (on les fixe à la main), et des outils pour avancer image physique par image physique.

const HeroScene: PackedScene = preload("res://scenes/player/hero.tscn")
const DummyScene: PackedScene = preload("res://scenes/enemies/training_dummy.tscn")
## Nombre maximal d'images physiques attendues avant d'abandonner une attente.
const MAX_FRAMES := 240
## Tolérance sur les hauteurs et distances mesurées (m).
const TOLERANCE := 0.06

var tuning: TuningData = Tuning.data
var world: Node3D
var hero: Hero


func before_each() -> void:
	world = Node3D.new()
	add_child_autofree(world)


## Ajoute un bloc statique de taille `size` posé sur y = 0 (ou centré en `center` si donné).
func _add_block(size: Vector3, center: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = center
	world.add_child(body)


## Sol plat et héros posé dessus, au repos.
func _spawn_on_flat_ground() -> void:
	_add_block(Vector3(60.0, 1.0, 60.0), Vector3(0.0, -0.5, 0.0))
	await _spawn(Vector3.ZERO)


func _spawn(at: Vector3) -> void:
	hero = HeroScene.instantiate() as Hero
	hero.reads_player_input = false
	hero.position = at
	world.add_child(hero)
	await _wait_for_state(&"Ground")


## Avance de `frames` images physiques. On reprend la main juste avant que le héros
## ne traite l'image suivante : on observe l'état exact, et les commandes fixées ici
## s'appliquent dès cette image.
func _step(frames: int) -> void:
	for i: int in frames:
		await get_tree().physics_frame


func _state() -> StringName:
	return hero.state_machine.current.name


## Attend (au plus MAX_FRAMES images) que le héros soit dans l'état `state_name`.
func _wait_for_state(state_name: StringName) -> void:
	for i: int in MAX_FRAMES:
		if _state() == state_name:
			return
		await _step(1)
	fail_test("le héros n'est jamais passé dans l'état %s" % state_name)


## Attend la fin du saut en cours et renvoie la hauteur maximale atteinte.
func _measure_apex() -> float:
	var apex: float = hero.global_position.y
	await _step(1)
	while _state() != &"Ground":
		apex = maxf(apex, hero.global_position.y)
		await _step(1)
	return apex


## Ajoute un mannequin d'entraînement en `at`.
func _add_dummy(at: Vector3) -> TrainingDummy:
	var dummy: TrainingDummy = DummyScene.instantiate() as TrainingDummy
	dummy.position = at
	world.add_child(dummy)
	return dummy


func _expected_apex(speed: float, gravity: float) -> float:
	return speed * speed / (2.0 * gravity)
