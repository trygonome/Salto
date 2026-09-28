extends GutHookScript
## Avant les tests : la sauvegarde va dans un fichier à part (jamais celle du joueur), le jeu part
## d'un profil neuf, et le journal de jeu se tait (test_journal le rallume dans son propre dossier).

const TEST_SAVE_PATH := "user://salto_save_tests.json"


func run() -> void:
	Save.path = TEST_SAVE_PATH
	Save.erase()
	Game.profile = Profile.new()
	Journal.enabled = false
