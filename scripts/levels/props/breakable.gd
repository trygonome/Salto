class_name Breakable
extends Node3D
## Objet à casser (version 2.6) :
##  - jarre : un coup la brise ; il en sort des plumes d'or, ou un peu de soin ;
##  - rocher fêlé : trois coups ; il cache un passage secret (signal `revealed`) ;
##  - fourré (version 3.4) : deux coups de lame ; il garde l'entrée d'un recoin ;
##  - nid de plumes (version 3.4) : un coup ; des plumes d'or, au fond d'un recoin.

## Le rocher fêlé vient de céder : un passage secret s'ouvre là.
signal revealed(at: Vector3)

const JAR := &"jar"
const BOULDER := &"boulder"
const THICKET := &"thicket"
const NEST := &"nest"
## Couleurs codées : terre cuite, liseré, pierre, fêlures dorées.
const CLAY := Vector3(2.05, 0.55, 0.38)
const RIM := Vector3(2.08, 0.6, 0.5)
const STONE := Vector3(4.6, 0.1, 0.4)
const CRACK := Vector3(2.12, 0.9, 0.55)
## Feuillage du fourré et ses lianes tressées ; paille du nid et ses plumes d'or.
const LEAF := Vector3(0.3, 0.75, 0.34)
const LEAF_LIGHT := Vector3(0.27, 0.8, 0.44)
const VINE := Vector3(4.07, 0.45, 0.28)
const STRAW := Vector3(2.09, 0.55, 0.45)
const GOLD := Vector3(2.12, 0.95, 0.6)
## Teinte de la gerbe de feuilles d'un fourré tranché ; ses cubes sont deux fois plus gros.
const LEAF_HUE := 0.3
const THICKET_CELL := 2.0

## Secousse d'un coup (écrasement, durées aller et retour en s), disparition (s), hauteur des gerbes (m).
const SQUASH := Vector3(1.15, 0.85, 1.15)
const SQUASH_TIME := 0.05
const SQUASH_BACK := 0.1
const VANISH_TIME := 0.15
const BURST_HEIGHT := 0.3
const WORD_HEIGHT := 1.2

var kind: StringName = JAR
var material: Material
var rng := RandomNumberGenerator.new()

var _hits_left: int = 1
var _broken: bool = false
var _visual: Node3D
var _hurtbox: Hurtbox
var _body: StaticBody3D


func _ready() -> void:
	var tuning: TuningData = Tuning.data
	add_to_group(&"breakables")
	_hits_left = tuning.boulder_hits if kind == BOULDER else tuning.thicket_hits if kind == THICKET else 1
	var cells := PackedFloat32Array()
	var radius: float
	var cell: float = tuning.breakable_cell
	if kind == THICKET:
		radius = tuning.thicket_radius
		cell *= THICKET_CELL
		var r: float = radius / cell
		var n: int = ceili(r)
		for x: int in range(-n, n + 1):
			for y: int in range(0, n + 2):
				for z: int in range(-n, n + 1):
					var d: float = Vector3(x, y * 0.9, z).length()
					if d > r + 0.3 or d < r - 1.4:
						continue
					var vine: bool = (x + y + z) % 4 == 0
					VoxelMesh.add(cells, x, y + 0.5, z, VINE if vine else (LEAF_LIGHT if y > n / 2 else LEAF))
	elif kind == NEST:
		radius = tuning.jar_radius
		for x: int in range(-2, 3):
			for z: int in range(-2, 3):
				if absi(x) == 2 or absi(z) == 2:
					VoxelMesh.add(cells, x, 0.5, z, STRAW)
				VoxelMesh.add(cells, x, 0.0, z, STRAW)
		for k: int in 5:
			var a: float = TAU * k / 5.0
			VoxelMesh.add(cells, cos(a) * 1.2, 1.5, sin(a) * 1.2, GOLD)
			VoxelMesh.add(cells, cos(a) * 1.6, 2.5, sin(a) * 1.6, GOLD)
	elif kind == JAR:
		radius = tuning.jar_radius
		for y: int in 4:
			var r: int = 1 if y == 0 or y == 3 else 2
			for x: int in range(-r, r + 1):
				for z: int in range(-r, r + 1):
					if absi(x) == r or absi(z) == r:
						VoxelMesh.add(cells, x, y + 0.5, z, RIM if y == 3 else CLAY)
	else:
		radius = tuning.boulder_radius
		for x: int in range(-3, 4):
			for y: int in 5:
				for z: int in range(-3, 4):
					var d: float = Vector3(x, y * 1.2 - 1.0, z).length()
					if d > 3.6 or d < 2.2:
						continue
					VoxelMesh.add(cells, x, y + 0.5, z, CRACK if (x == 0 and z >= 2) or (y == 2 and x == 1) else STONE)
	_visual = Node3D.new()
	_visual.name = "Visual"
	var mesh: MultiMeshInstance3D = VoxelMesh.create(cells, material)
	mesh.scale = Vector3.ONE * cell
	_visual.add_child(mesh)
	add_child(_visual)
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	var solid := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = radius * 2.0
	solid.shape = cylinder
	solid.position = Vector3.UP * radius
	_body.add_child(solid)
	add_child(_body)
	_hurtbox = Hurtbox.new()
	_hurtbox.name = "Hurtbox"
	_hurtbox.collision_layer = 16
	_hurtbox.collision_mask = 0
	_hurtbox.monitoring = false
	_hurtbox.radius = radius
	var zone := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius * 1.2
	zone.shape = sphere
	zone.position = Vector3.UP * radius
	_hurtbox.add_child(zone)
	add_child(_hurtbox)
	_hurtbox.hurt.connect(_on_hurt)


func is_broken() -> bool:
	return _broken


func _on_hurt(hit: HitData) -> void:
	if _broken or not hit.attacker is Hero:
		return
	_hits_left -= 1
	var tuning: TuningData = Tuning.data
	var shake: Tween = create_tween()
	shake.tween_property(_visual, "scale", SQUASH, SQUASH_TIME)
	shake.tween_property(_visual, "scale", Vector3.ONE, SQUASH_BACK)
	if _hits_left > 0:
		return
	_broken = true
	var fx: Effects = Effects.of(self)
	if fx:
		var hue: float = tuning.fx_gold_hue if kind == BOULDER or kind == NEST else LEAF_HUE if kind == THICKET else -1.0
		fx.burst(global_position + Vector3.UP * BURST_HEIGHT, tuning.fx_break_cubes, tuning.fx_break_speed, hue, true)
	_body.queue_free()
	_hurtbox.set_deferred(&"monitorable", false)
	var fade: Tween = create_tween()
	fade.tween_property(_visual, "scale", Vector3.ZERO, VANISH_TIME)
	if kind == BOULDER:
		if fx:
			fx.word(GameTexts.WORD_SECRET, global_position + Vector3.UP * WORD_HEIGHT, fx.gold, true)
		revealed.emit(global_position)
		return
	if kind == THICKET:
		return
	if kind == NEST:
		var feathers: int = tuning.nest_feathers + tuning.nest_feathers_per_room * (Game.run.room if Game.run else 0)
		if Game.run:
			Game.run.feathers += feathers
		if fx:
			fx.word(GameTexts.feathers(feathers), global_position + Vector3.UP, fx.gold)
		return
	_drop(hit.attacker as Hero, fx)


## Ce qu'une jarre contient : des plumes d'or le plus souvent, sinon un peu de soin.
func _drop(hero: Hero, fx: Effects) -> void:
	var tuning: TuningData = Tuning.data
	var stingy: bool = Game.run != null and Game.run.pacts.has(Pacts.STINGY)
	if not stingy and rng.randf() < tuning.jar_heal_chance:
		var amount: float = hero.health.maximum * tuning.jar_heal
		hero.health.heal(amount)
		if fx:
			fx.word(GameTexts.WORD_HEAL % roundi(amount), global_position + Vector3.UP, fx.green)
		return
	var feathers: int = rng.randi_range(tuning.jar_feathers_min, tuning.jar_feathers_max)
	if Game.run:
		Game.run.feathers += feathers
	if fx:
		fx.word(GameTexts.feathers(feathers), global_position + Vector3.UP, fx.gold)
