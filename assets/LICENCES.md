# Licences

Chaque pack ou fichier externe est noté ici **avant** d'être importé, avec l'échelle vérifiée contre le héros (1,8 m).

## Assets du jeu

| Asset | Auteur | Source | Licence | Dossier | Échelle vérifiée |
|---|---|---|---|---|---|
| KayKit Character Animations 1.1 (gratuit) : mannequin d'entraînement et ses clips Rig_Medium_General (parcours d'essai) | Kay Lousberg | https://kaylousberg.itch.io/kaykit-character-animations | CC0 — `animations/kaykit/LICENSE_KayKit_Character_Animations.txt` | `assets/animations/kaykit`, `assets/models/kaykit` | mannequin mis à 1,1 m (taille des plus grands Muets) |
| Pictogrammes des boutons tactiles (`ui/icons/*.svg`) | Salto | créés pour le projet | propriété du projet | `assets/ui/icons` | sans objet (interface) |
| Musique de la nuit (4 couches) et bruitages (`audio/`) | Salto | synthétisés par `tools/audio/generate_audio.py` | propriété du projet | `assets/audio` | sans objet (son) |
| Pictogrammes du HUD, des boutons et du sac (`ui/icons/*.svg` : pause, tambour, village, couronne, étoile, plume, cible, objets, boutons ronds) et thème de l'interface (`ui/theme.tres`, généré par `tools/ui/make_theme.py` avec la palette du prototype) | Salto | créés pour le projet | propriété du projet | `assets/ui` | sans objet (interface) |
| Police Bungee (titres, boutons forts), celle du prototype | The Bungee Project Authors (David Jonathan Ross) | https://fonts.google.com/specimen/Bungee | SIL Open Font License 1.1 — `fonts/OFL_Bungee.txt` | `assets/fonts` | sans objet (police) |
| Police Nunito SemiBold et ExtraBold (textes de l'interface) | The Nunito Project Authors (Vernon Adams, Jacques Le Bailly) | https://fonts.google.com/specimen/Nunito | SIL Open Font License 1.1 — `fonts/OFL_Nunito.txt` | `assets/fonts` | sans objet (police) |
| Muets en voxels portés du prototype (`scripts/enemies/muet_shapes.gd`) : sautillant, volant, cornu, porte-bouclier, cracheur, Grands Muets, Roi Muet | Salto | créés pour le projet | propriété du projet | `scripts/enemies`, `scenes/enemies` | oui : 0,6 à 1,1 m, Grand Muet 1,7 m (sans sa couronne), comme dans le prototype |
| Éléments de jeu : tambours en voxels et leur estrade, plumes des perchoirs, fruits, objets au sol et leur colonne de lumière, flèche et colonne de l'objectif (portés du prototype) ; gongs, coffres et champignon du parcours d'essai (formes simples) | Salto | créés pour le projet | propriété du projet | `scenes/levels/props`, `scripts/levels` | oui : tambours de 0,65 m (0,4 m portés par le héros), plume de 0,5 m, fruit de 0,3 m, comme dans le prototype ; gongs de 2 m, coffre de 0,7 m, champignon de 1,3 m |
| Monde voxel, héros, villageois et ombres rondes (`scripts/world`, `scenes/world`) : génération du monde, couleurs, sol, ciel et personnages portés du prototype `docs/prototype/salto-rpg.html` | Salto | créés pour le projet | propriété du projet | `scripts/world`, `scenes/world` | oui : 1 u = 0,26 m ; héros et villageois de 1,8 m (Chef 2,2 m) |
| Pages du carnet (`data/notebook.tres`) | Salto | textes de `docs/GDD.md` | propriété du projet | `data` | sans objet (texte) |

## Outils (non inclus dans le jeu exporté)

| Outil | Auteur | Source | Licence |
|---|---|---|---|
| GUT 9.7.1 (tests) | Butch Wesley | https://github.com/bitwes/Gut | MIT — `addons/gut/LICENSE.md` |
