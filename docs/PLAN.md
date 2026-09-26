# Plan de la tranche verticale (Godot 4)

Objectif : **10 minutes de jeu vraiment finies** — le village, un chemin, un sanctuaire gardé par un Grand Muet,
trois espèces de Muets, le combat salto-rythme, un cercle de gongs et un coffre caché.
Chaque jalon se termine jouable sur téléphone.

## Architecture
- **Autoloads** : `Tuning` (charge `data/tuning.tres`), `Rhythm` (horloge musicale), `Game` (état de la nuit), `Save`.
- **Héros** : `CharacterBody3D` + machine à états (sol, air, roulade, élan, coup, plongeon, touché) ;
  `AnimationTree` (course, sauts, salto, roulade, 4 coups) ; hitbox `Area3D` activée seulement pendant la fenêtre d'impact.
- **Muets** : scène de base avec composants `Health`, `Hurtbox`, `StateMachine` ; une scène par espèce.
- **Annonces des attaques** : `Decal` au sol (cercles et lignes rouges) + un son d'annonce.
- **Horloge musicale** : position de lecture de la musique + `AudioServer.get_time_since_last_mix()`
  − `AudioServer.get_output_latency()` (méthode documentée par Godot pour synchroniser le jeu et la musique).
- **Ambiance** : `WorldEnvironment` (brouillard, bloom, étalonnage ; saturation pilotée par le nombre de tambours).
- **Interface** : un seul `Theme` pour tout le jeu ; commandes tactiles en nœuds `Control`
  (événements `InputEventScreenTouch` et `InputEventScreenDrag`).
- **Sauvegarde** : un fichier dans `user://`, versionné.

## Jalons
0. **Mise en place** — projet, dossiers, git, `Tuning`, carte des commandes, **export Android d'une scène vide
   installé sur le téléphone** (valider tout de suite la chaîne d'export).
1. **Contrôleur du héros** — course, saut variable, salto, tolérance de bord, mémoire des appuis, roulade, élan aérien,
   caméra ; joystick flottant à base fixe et 3 boutons ; scène de test en blocs.
   *Test : traverser un parcours d'obstacles, faire des saltos sur des rochers.*
2. **Animations et coups** — personnage animé, 3 coups enchaînés, coup roulé, plongeon, annulations, arrêt sur image,
   traînées, secousses. *Test : un mannequin qui encaisse, l'enchaînement doit être fluide.*
3. **Rythme** — musique en couches, horloge, jugement Parfait / Bien, anneau de battement, jauge, Salto arc-en-ciel.
   *Test : frapper sur le temps doit se sentir sans lire aucun texte.*
4. **Muets** — sautillant, volant, cornu avec annonces ; réactions aux coups ; Grand Muet en deux phases.
   *Test : chaque attaque est lisible et esquivable.*
5. **Le niveau** — village, chemin, relief, sanctuaire, tambour à rapporter, cercle de gongs, coffre caché.
6. **Interface** — HUD minimal, pause, écran de fin, sauvegarde ; appliquer la charte des retours à l'écran.
7. **Finition** — effets, sons, étalonnage ; 60 images/s sur le téléphone ; export APK et web.

## Assets
- Choisir **un** pack principal de style low-poly cohérent (par exemple les packs gratuits de Kenney, Quaternius ou KayKit),
  des animations Mixamo pour le héros si besoin, des sons libres de droits.
- Vérifier et noter la licence de chaque pack dans `assets/LICENCES.md`.
- Vérifier chaque modèle à l'échelle du héros (1,8 m) avant de l'utiliser.

## Tests
- Tests automatiques de la logique pure (fenêtres de rythme, dégâts, combos, XP), avec un addon de tests pour Godot
  choisi au jalon 0.
- Pour chaque jalon, une courte liste de vérifications à faire sur le téléphone.

## Phase 2 : au niveau du prototype
Constat (jalon 7) : la tranche verticale Godot est en recul sur le prototype
(`docs/prototype/salto-rpg.html`, à ouvrir dans un navigateur) : identité visuelle, densité du monde,
guidage, progression. Décisions :
- **Tout en voxels, comme le prototype** : décor, Muets, villageois et héros en **voxels générés**
  (couleurs qui ondulent, décor qui pulse au rythme, zones de silence qui boivent les couleurs).
  Le héros est un enfant de la jungle comme les villageois, animé par poses calculées (après le
  jalon 9 : le personnage KayKit détonnait au milieu du monde voxel).
- **Échelle du prototype** : 1 u = 0,26 m. Monde compact et dense (rayon ≈ 22 m), village au centre,
  trois sanctuaires à ≈ 15 m, une trentaine de Muets par nuit.
- **D'abord la nuit 1 au niveau du prototype**, puis les nuits 2 à 5, jalon par jalon.

Jalons :
8. **Monde voxel** — matériau voxel (couleurs animées, pulsation au temps, zones de silence, brouillard
   coloré, transparence entre la caméra et le héros), sol à dalles et chemins dorés, ciel animé, ombres
   rondes ; génération du monde du prototype (village, trois sanctuaires, arbres, rochers, perchoirs,
   souches, champignons-trampolines, fleurs, troncs couchés) avec ses collisions ; villageois qui dansent
   au rythme et Chef (avancés du jalon 9).
   *Test : le monde ressemble au prototype et reste fluide.*
9. **Personnages voxel** — Muets du prototype (sautillant, volant, cornu, Grands Muets ; bouclier et
   cracheur prêts) ; effets du prototype (cubes qui jaillissent, anneaux, étincelles, chiffres qui montent).
   *Test : les Muets sont lisibles et vivants.*
10. **Interface du prototype** — police Bungee, écran titre (saga des cinq nuits), HUD (niveau, PV, XP,
    tambours, pause), bannière d'objectif, boutons colorés avec libellés, anneau de rythme, bannières,
    conseils près des boutons, bulles des villageois, pause et résumé de sortie.
    *Test : on comprend tout sans explication.*
11. **La nuit 1 complète** — trois sanctuaires et leurs Grands Muets, plusieurs tambours portés,
    objectif avec flèche, repère au bord de l'écran et chemin doré, sorties (tomber ramène au village,
    les tambours rapportés restent), défis et plumes, perchoirs, fruits, Muets errants.
    *Test : une nuit entière de bout en bout.*
12. **Progression** — niveaux et expérience, talents (trois voies), butin, sac, équipement, forge et recyclage.
    *Test : on devient plus fort d'une sortie à l'autre.*
13. **Nuits 2 à 5 et nuits sans fin** — porte-bouclier, cracheur, Roi Muet.
    *Test : la saga entière, puis les nuits sans fin.*

État (version 1.0.0) : jalons 0 à 13 faits. Le jeu suit le prototype : écran titre et saga des cinq
nuits, sorties (évanoui ou rentré au village, les tambours rapportés restent jusqu'à la fin de la
nuit), défis et plumes, niveaux, talents, sac et forge, puis les nuits sans fin. Le parcours d'essai
et le carnet de la phase 1 restent dans le projet (scène d'essai, données).

## Phase 3 : la symbiose (version 1.1.0)
Constat (retours sur téléphone, version 1.0.2) : les mécaniques s'empilaient sans se répondre
(plumes, forge, défis, score, butin au sol) : « construit par une calculette ». Décision : chaque
mécanique nourrit les autres (docs/GDD.md §3). Étapes, une par commit :
A. **Simplifier** — plus de plumes, forge, recyclage, défis ni score ; la plume des perchoirs devient
   une plume arc-en-ciel qui remplit la jauge de groove.
B. **Progression au village** — expérience mise de côté jusqu'au village, cadeau des Grands Muets
   attaché au tambour, sac et talents au village.
C. **Le rythme rend la couleur** — cercle de couleurs autour du héros selon la jauge (uniforme
   `salto_groove`), éclat au Salto arc-en-ciel.
D. **Les Muets libérés rejoignent le village** — troupe qui danse, gardée pour la nuit, plafonnée.
E. **Une acrobatie par Muet** — réponse attendue (GDD §7) : dégâts, groove, couleurs, note, conseil.
*Test : une nuit entière ; on comprend pourquoi on revient au village, pourquoi jouer en rythme,
et ce que chaque Muet attend.*
