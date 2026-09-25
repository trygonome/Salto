extends GutTest
## Génération du monde : même graine, même monde que le prototype (valeurs relevées dans
## docs/prototype/salto-rpg.html avec aucune nuit accomplie).


func _generate(seed_value: int) -> WorldGen:
	var gen := WorldGen.new()
	gen.generate(seed_value, 0)
	return gen


func _count(gen: WorldGen, walls: bool) -> int:
	var n: int = 0
	for s: WorldGen.Solid in gen.solids:
		if (s.h >= WorldGen.WALL) == walls:
			n += 1
	return n


func test_le_tirage_est_celui_du_prototype() -> void:
	var rng := ProtoRandom.new(1)
	var first: float = rng.next()
	assert_between(first, 0.0, 1.0)
	var again := ProtoRandom.new(1)
	assert_eq(again.next(), first, "même graine, même tirage")


func test_la_graine_12345_donne_le_monde_du_prototype() -> void:
	var gen: WorldGen = _generate(12345)
	assert_eq(gen.voxel_count(), 17432)
	assert_eq(gen.solids.size(), 156)
	assert_eq(_count(gen, true), 57, "solides infranchissables")
	var bouncers: int = 0
	for s: WorldGen.Solid in gen.solids:
		if s.kind == WorldGen.BOUNCE:
			bouncers += 1
	assert_eq(bouncers, 7)
	assert_almost_eq(gen.sanctuaries[0], Vector2(-13.0563, -57.3105), Vector2.ONE * 0.001)
	assert_almost_eq(gen.sanctuaries[1], Vector2(50.2502, 31.169), Vector2.ONE * 0.001)
	assert_almost_eq(gen.sanctuaries[2], Vector2(-39.6162, 35.2564), Vector2.ONE * 0.001)
	assert_eq(gen.sanctuary_names, PackedStringArray(["du Nord", "du Sud-Est", "du Sud-Ouest"]))
	assert_eq(gen.pickups.size(), 5)
	assert_almost_eq(gen.pickups[0], Vector3(46.2168, 5.5, 3.0074), Vector3.ONE * 0.001)
	assert_almost_eq(gen.pickups[4], Vector3(-13.6373, 5.5, -30.8004), Vector3.ONE * 0.001)
	var hut: WorldGen.Solid = gen.solids[10]
	assert_almost_eq(Vector2(hut.x, hut.z), Vector2(8.574, -16.821), Vector2.ONE * 0.001, "première case")
	var last: WorldGen.Solid = gen.solids[gen.solids.size() - 1]
	assert_almost_eq(Vector3(last.x, last.z, last.r), Vector3(-72.2171, -16.154, 1.1), Vector3.ONE * 0.001, "dernier champignon")


func test_une_autre_graine_donne_un_autre_monde_du_prototype() -> void:
	var gen: WorldGen = _generate(987654321)
	assert_eq(gen.voxel_count(), 18605)
	assert_eq(gen.solids.size(), 160)
	assert_eq(_count(gen, true), 63)
	assert_eq(gen.sanctuary_names, PackedStringArray(["du Nord-Ouest", "du Sud-Est", "du Sud-Ouest"]))
	assert_eq(gen.pickups.size(), 4)


func test_le_village_et_les_chemins_restent_libres() -> void:
	var gen: WorldGen = _generate(12345)
	for i: int in gen.voxel_count():
		var p := Vector2(gen.voxels[i * WorldGen.STRIDE], gen.voxels[i * WorldGen.STRIDE + 2])
		var size: float = gen.voxels[i * WorldGen.STRIDE + 6]
		if size == 0.5:
			assert_false(gen.near_path(p, 3.5), "pas de fleur sur un chemin")


func test_le_sol_sous_un_rocher_est_son_sommet() -> void:
	var gen: WorldGen = _generate(12345)
	var rock: WorldGen.Solid = null
	for s: WorldGen.Solid in gen.solids:
		if s.h < WorldGen.WALL and s.kind != WorldGen.BOUNCE and s.h > 2.0:
			rock = s
			break
	assert_not_null(rock)
	assert_eq(gen.ground_at(rock.x, rock.z, rock.h + 1.0), rock.h, "on se pose dessus")
	assert_eq(gen.ground_at(rock.x, rock.z, 0.0), 0.0, "au pied, on reste au sol")


func test_le_totem_grandit_avec_les_nuits() -> void:
	var gen := WorldGen.new()
	gen.generate(12345, 2)
	assert_eq(gen.totem_height, 7)
