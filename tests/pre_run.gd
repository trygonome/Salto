extends GutHookScript
## Avant les tests : la sauvegarde va dans un fichier à part (jamais celle du joueur), et le
## jeu part d'un profil neuf.

const TEST_SAVE_PATH := "user://salto_save_tests.json"


func run() -> void:
	Save.path = TEST_SAVE_PATH
	Save.erase()
	Game.profile = Profile.new()
