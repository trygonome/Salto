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
