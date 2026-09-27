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

## Phase 5 : Expéditions (version 2.0)
Constat (retours sur téléphone, version 1.3) : « un chouette truc, mais pas ce que je cherche » ;
l'envie : un vrai petit RPG procédural, entraînant, pour les heures creuses, au combat manuel.
Décision : un action-RPG façon Hades, qui réutilise le monde voxel, les Muets, le héros, les effets
et la musique. Une **expédition** = une suite de clairières générées (graine de l'expédition) ;
chaque clairière promet une récompense (don des esprits 1 parmi 3, soin, plumes d'or), lâche ses
Muets chasseurs par vagues, puis ouvre ses passages qui annoncent la leur ; un Grand Muet garde la
dernière. On garde l'expérience et les plumes d'or rapportées.
Jalons :
1. **Tester si c'est amusant** — 7 clairières, 2 vagues, 10 dons (brûlure, onde du 3e coup,
   roulade épineuse, plongeon météore, PV, métronome, sève, furie, vitesse, critique), passages,
   Grand Muet, résumé. *Test : a-t-on envie de relancer ?*
   **Version 2.1** (retours : écran flou qui bloque, murs invisibles, volants qui punissent trop,
   génération pauvre) — écran flou corrigé (caméra et héros protégés d'une position invalide, rien ne
   bouge pendant un arrêt sur image) ; bord des clairières en mur d'arbres visible ; volant qui s'écrase
   après son piqué, à frapper au sol ; 5 formes de clairière nommées (+ l'arène), taille variable ;
   4 rencontres à choix (passage « ? »).
   **Version 2.2** (retour : « les menus manquent cruellement de style ») — écrans dans la direction
   artistique : bois sculpté en cubes, peaux de tambour, bandeau tissé, fond de jungle animé,
   ouvertures animées (voir GDD §11).
La suite (carte, camp, contenu) est reprise et détaillée dans la phase 6.

## Phase 6 : d'une maquette à un vrai jeu (versions 2.3 à 2.9)
Constat (retours sur téléphone, version 2.2, et rapport de recherche) : « un début », mais un goût de
maquette ; les graphismes, les donjons, les Muets et le combat « manquent de quelque chose » ; les plumes
d'or ne servent à rien. Ordre choisi : d'abord ce qu'on sent à chaque seconde (le combat, les Muets), puis
ce qu'on voit (graphismes, donjons), puis ce qui fait revenir (village, variété, confort).
Chaque jalon se termine jouable, avec quoi tester sur le téléphone.

1. **2.3 — Combat : le choc et le contre.**
   - *Équilibre des Muets* : chaque coup entame une jauge d'équilibre ; brisée, le Muet chancelle,
     étourdi, et un **coup de grâce** (un salto qui le libère dans une gerbe de couleurs) l'achève.
   - *Projection* : les coups forts envoient les Muets valser ; contre un arbre, un pilier ou un autre
     Muet, ils prennent des dégâts d'impact (on les joue au billard).
   - *Coup chargé* (Frappe maintenue) : lent, brise les boucliers et l'équilibre, projette loin.
   - *Riposte* : une esquive parfaite (au dernier moment) ralentit le temps un instant, et le coup
     suivant est une riposte critique.
   - *Retours* : chaque type de coup a son son et son effet ; la musique enfle quand le combo tient.
   *Test : les combats ont-ils du poids, a-t-on envie d'enchaîner et de contrer ?*
2. **2.4 — Les Muets : un vrai bestiaire.**
   - Ils attaquent **sur les temps de la musique** : on lit leurs attaques à l'oreille autant qu'à l'œil.
   - Vagues **composées** (des rôles qui se complètent : un bouclier devant, un cracheur derrière…)
     plutôt que tirées au hasard.
   - Nouvelles espèces : le **tisserand** (pose des ronces), le **totem chanteur** (protège et accélère
     les autres : à abattre d'abord), le **danseur** (esquive sur le temps, puis contre), la **brute**
     (saisit le héros).
   - **Élites** à particularités (rapide, cuirassé, éclate en mourant, appelle des renforts, doré : des
     plumes), une par expédition au moins, qui garantit un don rare.
   - **Grand Muet** en vraies phases, avec des attaques qui changent ; un gardien différent par région.
   *Test : chaque combat pose-t-il un petit problème à résoudre ?*
3. **2.5 — Graphismes du monde.**
   - Lumière : soleil chaud et ombres froides, ombres portées des personnages, coins des cubes
     assombris (occlusion), brume et ciel accordés à chaque région.
   - Sol vivant : herbes hautes en cubes, terre, pierres, flaques, chemins ; plus de quadrillage uni.
   - Végétation variée : fromagers à contreforts, palmiers, fougères, lianes ; des arbres de premier plan
     qui ne cachent plus l'action.
   - Ambiance : lucioles, pollen, feuilles qui tombent, eau animée ; héros et Muets détachés du décor
     (lumière de bord).
   *Test : sur une capture, le jeu paraît-il fini ?*
4. **2.6 — Les donjons : des clairières faites main, des régions.**
   - Clairières assemblées à partir de **modules faits à la main** (plateformes, escaliers, ponts,
     fosses, bassins) : du relief, de la hauteur, des formes qui ne sont plus des cercles.
   - **Dangers au tempo** (ronces qui sortent sur le temps, lianes qui fouettent), **éléments à
     utiliser** (tambours à frapper qui étourdissent autour, jarres et bambous à casser, gongs).
   - **3 régions** (Sous-bois, Ruines englouties, Canopée) : palette, musique, Muets et gardien propres ;
     salles spéciales (trésor, secret, repos).
   *Test : se souvient-on d'une clairière après la partie ?*
5. **2.7 — Le village vivant.**
   - Au retour, le Chef et les villageois **réagissent à l'expédition** (où l'on est tombé, contre qui,
     le gardien presque vaincu, la première victoire…) : répliques courtes.
   - Les **plumes d'or reconstruisent le village** en cubes : chaque case débloque quelque chose
     (autel des esprits : un don de plus au choix ; case du tambourinaire : rencontres ; source : PV de
     départ ; scène : musiques).
   *Test : a-t-on envie de revenir au village entre deux expéditions ?*
6. **2.8 — Des parties différentes.**
   - **Instruments-armes** au départ : bâton de pluie (l'actuel), maracas jumelles (rapides),
     tambour-marteau (lent, zones), sarbacane (à distance) : chacun ses enchaînements.
   - **25 dons** environ, en familles (braise, rythme, racines, couleur), avec raretés et quelques
     **dons doubles** (deux familles) ; nouvelles rencontres (la Tisseuse de couleurs, l'Écho solitaire,
     l'Arbre muet…).
   *Test : deux parties se jouent-elles différemment ?*
7. **2.9 — Confort mobile.**
   - **Reprendre une expédition interrompue** (appel, fermeture de l'application).
   - Première expédition qui **apprend sans texte** (un seul sautillant, puis un porte-bouclier…).
   - Réglage du **décalage audio** (calibration) ; **pactes** de difficulté contre plus de plumes.

Écarté du rapport de recherche : pénalité des coups à contretemps (le rythme récompense, ne punit
pas) ; couche audio native Oboe/AAudio (chantier moteur ; la calibration suffit) ; masque qui cache les
annonces d'attaque (lisibilité d'abord).

## Phase 4 : finitions pour le téléphone (versions 1.2 et 1.3)
- **1.2** — couleurs calmes (les teintes ondulent sans dériver), jauge qui retombe sans rythme,
  vibrations (réglage), d'après les vidéos du téléphone.
- **1.3** — l'histoire dans la jungle : cercle des gongs et coffres au sommet des perchoirs dans le
  monde voxel, pages du carnet par nuit, écran Carnet, répliques des Grands Muets ; la musique
  vivante : la troupe du village chante (sa couche monte avec sa taille et près du village).
