class_name RibbonTrail
extends MeshInstance3D
## Traînée : un ruban tracé le long de la jambe (de la hanche vers le pied, prolongé au-delà)
## qui balaie la zone du coup et s'efface en `lifetime` secondes. Dessinée dans le monde,
## par-dessus le personnage pour rester lisible sous la caméra plongeante.

## Couleur du ruban (l'opacité diminue avec l'âge).
@export var color: Color
## Couleurs du ruban arc-en-ciel, de la plus récente à la plus ancienne.
@export var rainbow_colors: Array[Color]

## Extrémités du ruban (la hanche et le pied qui frappe).
var root_node: Node3D
var tip_node: Node3D
## Vrai tant que la traînée doit s'allonger.
var emitting: bool = false
## Vrai pour un ruban arc-en-ciel (Salto arc-en-ciel).
var rainbow: bool = false
## Durée de vie d'un point du ruban (s).
var lifetime: float = 0.0
## Début et fin du ruban le long de la jambe, en multiples de la distance hanche-pied.
var inner_reach: float = 0.0
var outer_reach: float = 0.0

var _roots: PackedVector3Array = []
var _tips: PackedVector3Array = []
var _ages: PackedFloat32Array = []
var _mesh := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	mesh = _mesh


func _process(delta: float) -> void:
	for i: int in _ages.size():
		_ages[i] += delta
	while not _ages.is_empty() and _ages[0] > lifetime:
		_ages.remove_at(0)
		_roots.remove_at(0)
		_tips.remove_at(0)
	if emitting and root_node and tip_node:
		var hip: Vector3 = root_node.global_position
		var leg: Vector3 = tip_node.global_position - hip
		_roots.append(hip + leg * inner_reach)
		_tips.append(hip + leg * outer_reach)
		_ages.append(0.0)
	_rebuild()


func _rebuild() -> void:
	_mesh.clear_surfaces()
	if _tips.size() < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i: int in _tips.size():
		var age: float = _ages[i] / lifetime
		var fade: Color = _rainbow_color(age) if rainbow else color
		fade.a = color.a * (1.0 - age)
		var faint: Color = fade
		faint.a = 0.0
		# Transparent côté hanche, opaque au bout : le ruban dessine la trajectoire du coup.
		_mesh.surface_set_color(faint)
		_mesh.surface_add_vertex(_roots[i])
		_mesh.surface_set_color(fade)
		_mesh.surface_add_vertex(_tips[i])
	_mesh.surface_end()


## Couleur de l'arc-en-ciel pour un point d'âge relatif `age` (0 = neuf, 1 = sur le point de disparaître).
func _rainbow_color(age: float) -> Color:
	var position: float = age * (rainbow_colors.size() - 1)
	var index: int = mini(floori(position), rainbow_colors.size() - 2)
	return rainbow_colors[index].lerp(rainbow_colors[index + 1], position - index)
