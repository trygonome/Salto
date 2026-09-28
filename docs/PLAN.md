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
   **Fait** (version 2.3) : barre d'équilibre, coup de grâce, projection et billard, coup chargé jugé au
   relâcher, riposte, garde qui cède, la troupe qui chante avec le combo.
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
   **Fait** (version 2.4) : vagues composées (9 modèles), tisserand, totem chanteur, danseur, brute, élites à
   particularités et don de l'élite, troisième phase du Grand Muet (les gardiens par région viennent en 2.6).
3. **2.5 — Graphismes du monde.**
   - Lumière : soleil chaud et ombres froides, ombres portées des personnages, coins des cubes
     assombris (occlusion), brume et ciel accordés à chaque région.
   - Sol vivant : herbes hautes en cubes, terre, pierres, flaques, chemins ; plus de quadrillage uni.
   - Végétation variée : fromagers à contreforts, palmiers, fougères, lianes ; des arbres de premier plan
     qui ne cachent plus l'action.
   - Ambiance : lucioles, pollen, feuilles qui tombent, eau animée ; héros et Muets détachés du décor
     (lumière de bord).
   *Test : sur une capture, le jeu paraît-il fini ?*
   **Fait** (version 2.5) : lumière chaude et froide, arêtes, contre-jour, sol vivant, palmiers, fromagers,
   fougères, lianes, herbe haute, mares, lucioles, feuilles, halo ; premier plan effacé ; titres qui ne se
   coupent plus au milieu d'un mot. (Brume et ciel par région : en 2.6.)
4. **2.6 — Les donjons : des clairières faites main, des régions.**
   - Clairières assemblées à partir de **modules faits à la main** (plateformes, escaliers, ponts,
     fosses, bassins) : du relief, de la hauteur, des formes qui ne sont plus des cercles.
   - **Dangers au tempo** (ronces qui sortent sur le temps, lianes qui fouettent), **éléments à
     utiliser** (tambours à frapper qui étourdissent autour, jarres et bambous à casser, gongs).
   - **3 régions** (Sous-bois, Ruines englouties, Canopée) : palette, musique, Muets et gardien propres ;
     salles spéciales (trésor, secret, repos).
   *Test : se souvient-on d'une clairière après la partie ?*
   **Fait** (version 2.6) : trois régions (couleurs du sol, du feuillage et de la brume, couche de musique,
   vagues préférées, gardien), rivières et ponts, estrades, plateformes, épines et lianes au tempo, tambours de
   guerre, jarres, rocher fêlé et passage secret, salles de repos (feu de camp), de trésor et secrètes ; choix de
   la région à l'écran titre. (Fosses et escaliers : écartés, le héros se bat au sol ; les plateformes suffisent
   à donner de la hauteur.)
5. **2.7 — Le village vivant.**
   - Au retour, le Chef et les villageois **réagissent à l'expédition** (où l'on est tombé, contre qui,
     le gardien presque vaincu, la première victoire…) : répliques courtes.
   - Les **plumes d'or reconstruisent le village** en cubes : chaque case débloque quelque chose
     (autel des esprits : un don de plus au choix ; case du tambourinaire : rencontres ; source : PV de
     départ ; scène : musiques).
   *Test : a-t-on envie de revenir au village entre deux expéditions ?*
   **Fait** (version 2.7) : le village à pied au retour (et depuis l'écran titre), le Chef qui commente la
   partie (gardien presque libéré, record, première victoire, région ouverte, réponse à l'espèce qui a fait
   tomber le héros) puis rappelle de rebâtir, quatre cases rebâties avec les plumes d'or (autel : un don de plus ;
   case du tambourinaire : plus de rencontres ; source : PV de départ ; scène : troupe et musique), danseurs de
   plus en plus nombreux, fête après une victoire.
6. **2.8 — Des parties différentes.**
   - **Instruments-armes** au départ : bâton de pluie (l'actuel), maracas jumelles (rapides),
     tambour-marteau (lent, zones), sarbacane (à distance) : chacun ses enchaînements.
   - **25 dons** environ, en familles (braise, rythme, racines, couleur), avec raretés et quelques
     **dons doubles** (deux familles) ; nouvelles rencontres (la Tisseuse de couleurs, l'Écho solitaire,
     l'Arbre muet…).
   *Test : deux parties se jouent-elles différemment ?*
   **Fait** (version 2.8) : quatre instruments-armes (bâton de pluie, maracas jumelles, tambour-marteau,
   sarbacane et ses fléchettes), tenus en main, choisis à l'écran titre ou au râtelier du village ; 25 dons en
   quatre familles, raretés (un, deux ou trois rangs), quatre dons doubles, don de l'élite au moins rare ;
   la Tisseuse de couleurs, l'Écho solitaire, l'Arbre muet. Corrigé au passage : les dons de l'expédition ne
   changeaient pas les forces du héros lui-même (seulement celles calculées à part).
7. **2.9 — Confort mobile.**
   - **Reprendre une expédition interrompue** (appel, fermeture de l'application).
   - Première expédition qui **apprend sans texte** (un seul sautillant, puis un porte-bouclier…).
   - Réglage du **décalage audio** (calibration) ; **pactes** de difficulté contre plus de plumes.
   **Fait** (version 2.9) : reprise de l'expédition interrompue (sauvegarde à chaque clairière), première
   expédition qui apprend une espèce à la fois, conseils de réponse des neuf espèces près des boutons (portés de
   la nuit vers l'expédition), coup de grâce et coup chargé conseillés, calibration du son dans la pause, pierre
   des pactes au village (quatre pactes, jusqu'à +100 % de plumes).

Écarté du rapport de recherche : pénalité des coups à contretemps (le rythme récompense, ne punit
pas) ; couche audio native Oboe/AAudio (chantier moteur ; la calibration suffit) ; masque qui cache les
annonces d'attaque (lisibilité d'abord).

## Phase 7 : la refonte jusqu'aux racines (versions 3.0 à 3.8)
Sources : retours sur la version 2.9 (ci-dessous) et rapport de recherche Gemini « Refonte de Salto »
(accroche, cohérence, monde fourni, agencement, langage visuel, rythme, finition, paysage).

**Ce qu'on retient du rapport** : musique âme du monde plutôt que contrainte de timing (Gris, Okami,
musique de Hades qui suit l'état de l'arène) ; navigation sans défilement en paysage ; code couleur des
effets en quatre familles ; icônes voxel 3D animées sur des cartes fixes ; clairières assemblées par blocs
(Spelunky) avec un tracé principal et des recoins facultatifs ; passages mis en scène (rituels, vague de
couleur) ; récit réactif du Chef (Hades) ; finition « maquette miniature » ; zones sûres et contrôles aux
pouces ; caméra à champ étroit pour le paysage.
**Ce qu'on écarte ou corrige** : les chiffres de marché (sources peu fiables, sans incidence sur nos choix) ;
son option C « rythme moteur synergique » : c'est à peu près le jeu actuel (rien n'est puni, un coup en
rythme donne un bonus), et elle est restée invisible au testeur ; on garde donc le monde qui bat la mesure
mais on retire le jugement des appuis. Contours et profondeur de champ en post-traitement : trop coûteux
sur un Android moyen ; on vise le même effet par l'occlusion calculée à la génération. Les noms
d'instruments et de régions proposés : on garde les nôtres.

Ordre : d'abord les fondations qui touchent tout (paysage, pivot du combat), puis ce qu'on lit (langage
visuel, navigation), puis le monde (clairières, passages, finition), puis ce qui fait revenir (hub, récit).
Chaque jalon se termine jouable, avec quoi tester sur le téléphone.

1. **3.0 — Fondations paysage.** Paysage exclusif (orientation verrouillée, fenêtre de test en paysage) ;
   caméra recadrée (champ étroit, vue plus large sur les côtés) ; HUD et contrôles aux pouces (joystick à
   gauche ; Frappe, Esquive, Saut en arc à droite ; vie et groove en haut à gauche ; pause en haut à
   droite), zones sûres (encoches) ; correctif du bouton « Partir en expédition » ; son des pièges (un son
   propre, discret, porté seulement près du héros). *Test : tout se joue en paysage, rien ne gêne les pouces.*
   **Fait** (version 3.0) : paysage exclusif, caméra à champ plus étroit (héros plus grand), commandes et
   HUD écartés de l'encoche, écran titre en deux colonnes sans défilement (le bouton jaune passait sous le
   bas de l'écran en paysage : c'était le bug), pièges sans l'alerte des Muets et avec leur propre son
   discret, qu'on n'entend que de près.
2. **3.1 — Le combat libre, le monde qui bat la mesure.** Fin du jugement des appuis (plus de Parfait/Bien,
   plus d'anneau au sol ni de calibration) ; le groove se remplit par l'action (coups, combo, réponses, coup
   de grâce, esquive parfaite). Le monde garde la pulsation : Muets et pièges s'annoncent sur les temps,
   plantes et lumières respirent avec la musique. Musique qui suit le combat (exploration calme, combat
   soutenu, retour au calme) et s'étoffe à chaque Muet libéré. Dons refondus en **quatre familles de
   couleur** : Feu rouge (dégâts, brûlure, critiques), Eau bleue (protection, esquive, riposte,
   étourdissement), Sève verte (soin, PV, racines), Vent jaune (vitesse, groove, Salto arc-en-ciel) ; les
   dons « rythme » deviennent autre chose ; dons doubles recomposés. Passe de « game feel » sur les impacts.
   *Test : sans y penser, frapper est agréable ; le groove monte en se battant bien.*
   **Fait** (version 3.1) : plus de jugement ni d'anneau ni de calibration ; groove gagné en frappant, plus
   avec le combo ; note qui monte avec le combo à chaque coup qui touche ; pulsation du monde réduite à une
   respiration (30 %) ; musique qui s'étoffe pendant les combats ; dons en quatre familles (Feu, Eau, Sève,
   Vent), trois dons d'Eau nouveaux (Brume, Ressac, Givre), Geyser à la place de Roulement.
3. **3.2 — Langage visuel : icônes voxel et couleurs.** Chaque don, objet, instrument, case du village et
   récompense a sa petite icône voxel animée (elle tourne, respire) ; le cadre, la gemme de rareté et les
   mots-clés portent la couleur de la famille ; un effet se comprend à l'image avant le texte (deux lignes
   au plus). Cartes de dons côte à côte, fixes. *Test : on choisit un don sans lire son nom.*
   **Fait** (version 3.2) : catalogue d'icônes voxel (dessins 7 × 7 extrudés en cubes, relief sur les
   teintes claires) pour les 29 dons, les récompenses, les objets, les cases, les pactes et les régions ;
   icône vivante dans l'interface (petite scène à part, elle tourne doucement) ; cartes de dons côte à côte,
   cadre et laçage à la couleur de la famille, effet écrit dans sa couleur, rareté en couleur.
4. **3.3 — Navigation d'application, sans défilement.** Architecture des écrans en paysage : écran titre
   réduit (toucher pour jouer), hub par onglets (Expédition, Village, Sac, Talents, Carnet, Réglages), pages
   fixes, retour arrière cohérent, transitions ; pause en surimpression à onglets ; résumé en une page.
   Cibles tactiles de 44 px et plus. *Test : on trouve tout en deux touches, on ne fait jamais défiler.*
   **Fait** (version 3.3) : plus aucun écran ne défile ; Sac, Talents, Carnet et Réglages sont des onglets
   (rail à icônes voxel à gauche, « Retour » en bas, qui ramène toujours d'où l'on vient ; le Sac et les
   Talents restent grisés loin du village) ; page Réglages à part ; pause en deux colonnes (où l'on est,
   gestes, dons pris en icônes / Reprendre, onglets, Rentrer) ; résumé en une page (chiffres à droite,
   boutons côte à côte) ; nouvelle page « Préparer l'expédition » : région, instrument et pactes en cartes
   à icône, bonus de plumes sur « Partir » ; elle s'ouvre depuis l'écran titre, le passage du nord, le
   râtelier et la pierre des pactes (les flèches de l'écran titre ont disparu) ; talents en rangées basses
   (nom et rangs sur une ligne), carnet en grille de pages avec la page lue à droite. Reste pour 3.8 : les
   écrans 4:3 des tablettes (cartes plus étroites).
   **Fait** (version 3.4.1, d'après le croquis du joueur) : le menu de pause refait — bandeau en haut (où
   l'on est · MENU · clairière et plumes), icônes rapides (réglages, son, vibrations), six grands boutons à
   gauche, panneau de cartes à droite qui défile dans son cadre (instrument, objets portés, dons de
   l'expédition ; toucher une carte la lit), « Gestes » pour le rappel des gestes.
5. **3.4 — Des sentiers qui serpentent.** Clairières assemblées par blocs sur une grille : un tracé principal
   sinueux de l'entrée à la sortie (les pressés le suivent), des arènes où se jouent les vagues, et des
   recoins facultatifs derrière la végétation à trancher ou un détour (jarres, plumes, pages, stèle de don,
   Muet caché) placés selon les règles d'adjacence (un creux bordé de rochers et d'arbres cache plus
   souvent quelque chose) ; repères visibles de loin. *Test : on a envie de regarder dans les coins, sans y
   être obligé.*
   **Fait** (version 3.4) : chaque clairière de combat est une arène au bout d'un sentier de terre battue
   qui serpente depuis le sud (trois coudes, un rocher à chaque coude) ; des sentiers plus courts mènent
   aux sorties, dont les passages sont au bout ; les Muets attendent que le héros entre dans l'arène. Un
   à trois recoins au bord de l'arène, et parfois un au coude du sentier : un passage étroit, gardé par un
   fourré à trancher (deux coups) ou un rideau de fougères, signalé par des fleurs vives et un champignon
   lumineux ; au fond, des jarres, un nid de plumes d'or, une stèle des esprits (un don au choix entre
   deux) ou un Muet doré endormi qui s'éveille quand on entre. Règles de voisinage : un recoin gardé
   par un fourré cache plus souvent une stèle ou un Muet doré, un recoin bordé de rochers plus souvent
   des plumes. Un repère au-delà des sorties, visible de loin : l'arbre-lanterne (tour en ruine chez les
   Ruines). Clôture invisible en poteaux serrés le long de tout ce qui se marche ; arbres du fond à gros
   cubes (autant de cubes qu'avant pour une jungle plus grande). Le village garde son cercle.
6. **3.5 — Passages rituels.** Les arches deviennent des portes-totems : l'icône voxel de la récompense sur
   le totem ; la franchir déclenche une vague de couleur qui dissout la brume de la zone suivante et une
   transition musicale. *Test : changer de zone est un petit moment.*
   **Fait** (version 3.5) : portes-totems — deux mâts sculptés de visages (yeux, ailes et seuil de
   pierres aux couleurs de la récompense) et, entre leurs sommets, l'icône voxel de la récompense qui
   tourne ; ils surgissent du sol au bout des sentiers de sortie. Franchir : un voile aux couleurs de la
   récompense, un roulement de toms et un carillon, la musique revient à sa base ; de l'autre côté, la
   clairière arrive dans une brume épaisse qu'une vague arc-en-ciel dissout en partant du héros, et la
   musique reprend ses couches deux temps plus tard. Le passage du nord du village fait de même.
7. **3.6 — Finition « maquette miniature ».** Occlusion calculée à la génération (coins et pieds de mur
   assombris), lumière chaude plus douce, brume de profondeur, vague de couleur qui se propage au sol quand
   une zone est libérée (Gris) ; première minute mise en scène : une clairière sombre et muette, frapper la
   stèle, la couleur et un premier accord reviennent. *Test : une capture d'écran paraît finie.*
   **Fait** (version 3.6) : occlusion calculée à la génération (chaque cube entouré d'autres s'assombrit :
   creux des couronnes, coins, pieds de ce qui se dresse) ; soleil plus chaud, ombres plus douces ; une
   clairière libérée lance une vague arc-en-ciel sur le sol et un éclat de couleurs. Première minute : la
   toute première clairière de la première expédition est grise et muette, une pierre du silence se dresse
   sur le chemin (le repère la montre) ; la frapper rend les couleurs en vague et le premier accord, la
   musique revient, puis le premier sautillant arrive. La brume de profondeur est celle des passages (3.5).
8. **3.7 — Hub vivant et récit réactif.** Le Chef et les villageois réagissent à tout (instrument choisi,
   dons pris, morts, gardiens, première fois de chaque chose) ; les villageois ont leur place et leur vie ;
   chaque gardien libéré rend une couche à la musique du village. *Test : on revient au village pour voir ce
   qu'ils vont dire.*
9. **3.8 — Polissage mobile.** Vibrations sur les actions majeures, profilage (60 images/s), ratios d'écran
   (19,5:9, 20:9, tablettes), export web. *Test : fluide et confortable sur plusieurs téléphones.*

Retours sur la version 2.9 intégrés à ces jalons :
- **Bug** : le bouton jaune « Partir en expédition » de l'écran titre ne répondait pas (il a fallu passer
  par le village). Pistes : une région fermée affichée entre les flèches désactive le bouton ; un toucher
  pris pour un défilement dans le menu.
- **Navigation** : les menus demandent de défiler, ce qui n'est pas pensé pour le mobile. Toute la
  navigation doit devenir celle d'une application, sans défilement.
- **Paysage exclusif** : le jeu passe en mode horizontal seulement (cadrage, interface, contrôles).
- **Passages** : les arches pour changer de zone sont peu engageantes.
- **Clairières** : trop fermées, pas assez sinueuses, sans surprises. Il faut récompenser les curieux
  (détours, secrets, découvertes) sans que ce soit une obligation.
- **Objets et cartes de dons** : de petites icônes voxel animées qui les représentent (le nom compte
  moins), et des effets en couleur pour comprendre d'un coup d'œil ce qu'ils font.
- **Le rythme ne se voit pas** (retour le plus grave) : après pas mal de parties, le testeur n'avait
  pas compris que le combat se joue en rythme. Le pilier du jeu est invisible. Constat dans le code :
  les seuls signes sont l'anneau au sol autour du héros (qui se lit comme un simple cercle de
  sélection), son éclat doré et un carillon qui se confond avec le son des coups ; aucun mot
  « Parfait ! » ne s'affiche, le bonus de dégâts (×1,5) ne se voit pas, les Muets attaquent sur les
  temps sans que ça se remarque, et le conseil « Frappe quand l'anneau se referme » de la nuit n'a pas
  été porté dans l'expédition. **La mécanique elle-même est remise en question** : le combat au
  rythme est peu commun, et la recette d'un bon jeu n'est sans doute pas là. Constat qui va dans ce sens :
  le testeur a aimé la direction du jeu sans jamais s'en servir ; le plaisir vient de l'action, des
  dons, du village. Piste à trancher avec la recherche : garder la musique comme âme du monde (les
  Muets, la couleur et la musique qui reviennent, la troupe, la musique qui s'étoffe) sans en faire
  une contrainte de timing, ou n'en garder qu'une touche facultative. Ce qui en dépend dans le code : le
  jugement des appuis (Parfait, Bien), l'anneau au sol, le groove gagné en rythme, la famille de dons
  « rythme » (Métronome, Syncope, Accent, Contrepoint, Roulement), les Muets et pièges calés sur les
  temps, la calibration du son.
- **Son des pièges** : le son des épines est vraiment envahissant à la longue. Cause : chaque piège
  annonce sa frappe tous les 2 temps avec le même son d'alerte que les attaques des Muets (plusieurs
  pièges par clairière), ce qui brouille aussi cette alerte. À revoir : un son propre aux pièges, discret,
  calé sur la musique, porté seulement près du héros (ou seulement à l'écran), sans l'alerte des Muets.

## Phase 4 : finitions pour le téléphone (versions 1.2 et 1.3)
- **1.2** — couleurs calmes (les teintes ondulent sans dériver), jauge qui retombe sans rythme,
  vibrations (réglage), d'après les vidéos du téléphone.
- **1.3** — l'histoire dans la jungle : cercle des gongs et coffres au sommet des perchoirs dans le
  monde voxel, pages du carnet par nuit, écran Carnet, répliques des Grands Muets ; la musique
  vivante : la troupe du village chante (sa couche monte avec sa taille et près du village).
