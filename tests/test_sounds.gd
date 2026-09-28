extends GutTest
## Vrais sons (version 4.0) : la musique jouée par de vrais instruments garde ses couches
## synchrones ; chaque lieu a sa prise de forêt en boucle, et changer de lieu change d'ambiance.

const LevelScene: PackedScene = preload("res://scenes/levels/expedition.tscn")

var tuning: TuningData = Tuning.data


func before_each() -> void:
	Save.path = "user://test_sounds.json"
	Game.profile = Profile.create()
	Game.profile.expeditions = 1
	Game.start_on_load = false
	Game.village_on_load = false
	Game.run = null


func after_all() -> void:
	Game.profile = Profile.new()
	Game.refresh_stats()


func after_each() -> void:
	get_tree().paused = false
	Game.run = null
	Game.playing = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Save.path))


func test_les_couches_de_musique_restent_synchrones() -> void:
	var paths: Array[String] = Rhythm.NIGHT_LAYERS.duplicate()
	paths.append(Rhythm.BAND_LAYER)
	paths.append_array(Rhythm.REGION_LAYERS.values())
	var length: float = (load(paths[0]) as AudioStream).get_length()
	assert_almost_eq(length, 8.0 * 4.0 * 60.0 / 104.0, 0.01, "huit mesures à 104 BPM")
	for path: String in paths:
		assert_almost_eq((load(path) as AudioStream).get_length(), length, 0.001, "%s : même longueur que la base" % path)


func test_chaque_lieu_a_sa_prise_de_foret_en_boucle() -> void:
	for place: StringName in [Regions.UNDERGROWTH, Regions.SUNKEN, Regions.CANOPY, &"village"]:
		var stream: AudioStreamOggVorbis = AmbiencePlayer.STREAMS.get(place) as AudioStreamOggVorbis
		assert_not_null(stream, "une ambiance pour %s" % place)
		if stream:
			assert_true(stream.loop, "%s tourne en boucle" % place)
			assert_gt(stream.get_length(), 20.0, "une vraie prise, assez longue pour ne pas lasser")


func test_changer_de_lieu_change_d_ambiance() -> void:
	var level: Expedition = LevelScene.instantiate() as Expedition
	add_child_autofree(level)
	await get_tree().process_frame
	assert_eq(level.ambience.place, &"village", "le camp : la nuit au village")
	level.start_sortie()
	assert_eq(level.ambience.place, Game.run.region, "en expédition : la forêt de la région")
	await get_tree().create_timer(tuning.ambience_fade_time + 0.2).timeout
	assert_eq(level.ambience.stream, AmbiencePlayer.STREAMS[Game.run.region])
	assert_almost_eq(level.ambience.volume_db, tuning.ambience_volume_db, 0.01, "le fondu est fini")
	level.enter_village()
	assert_eq(level.ambience.place, &"village")
