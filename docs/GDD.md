# Salto : la jungle muette — document de conception

## 1. Vision
Un jeu d'action acrobatique en 3D où l'on se bat au rythme de la musique.
Un jeune acrobate rend leurs tambours à une jungle dont le **Grand Silence** a volé la musique et les couleurs.
Sensation visée : fluide, joyeuse, percutante. Le rythme récompense, il ne bloque jamais.

## 2. Piliers
1. **Le corps d'abord** : courir, sauter, faire des saltos et rouler doit être un plaisir avant même de combattre.
2. **Le rythme récompense, il ne punit pas** : frapper sur le temps rend plus fort ; à contretemps, ça marche quand même.
3. **Lisibilité** : chaque attaque ennemie s'annonce (son + signe au sol) ; chaque réussite se voit dans le monde, pas dans un texte.
4. **La jungle revit** : chaque tambour rapporté rend des couleurs au monde et une couche à la musique.

## 2 bis. Expéditions (mode principal depuis la version 2.0)
Action-RPG procédural au combat manuel, pour des parties de 8 à 12 minutes :
- **Expédition** : 7 clairières générées à partir d'une graine, la dernière gardée par un **Grand Muet**.
  Les Muets arrivent par vagues et poursuivent le héros.
- **Clairières** (version 2.1) : chacune a sa forme, sa taille (de 7,8 à 10,4 m de rayon) et son nom, tirés
  de sa graine. Le bord est un **mur d'arbres et de buissons** qu'on voit (le mur invisible est juste
  derrière), ouvert seulement aux passages. Formes : **clairière** (rochers, souches, un champignon-trampoline),
  **ruines** (cercle de piliers, certains brisés à sauter, autel au centre), **bosquet** (arbres au milieu du
  combat), **troncs couchés** (à contourner ou sauter), **champignonnière** (trampolines et un grand
  champignon portant une plume arc-en-ciel), et l'**arène** du Grand Muet (cercle de piliers).
- **Récompense de la clairière**, annoncée par le passage qui y mène : **don des esprits** (1 parmi 3),
  **soin** (35 % des PV), **plumes d'or** ou **rencontre** (passage « ? »). La première clairière donne un don.
- **Rencontres** (version 2.1) : une clairière calme, sans Muets ; un personnage au centre, on s'en approche
  et il parle ; deux choix, puis les passages s'ouvrent. Chacune une fois par expédition :
  - *La source des anciens* : boire (tous les PV) ou y plonger la main (un don, contre 25 % des PV) ;
  - *Le marchand muet* : 40 plumes d'or pour un don, ou le saluer (un peu de soin) ;
  - *Le vieux tambourinaire* (Kamba) : apprendre son rythme (Métronome, un rang) ou écouter son histoire
    (une page du carnet, un peu de soin) ;
  - *Un villageois perdu* : le soigner (−20 PV, il offre un objet) ou lui montrer le chemin (+15 plumes d'or).
- **Dons des esprits** (rang 1 à 3 en les reprenant) : Pied de braise (les coups brûlent), Écho du tambour
  (onde du 3e coup), Roulade épineuse, Plongeon météore, Cœur de la jungle (PV), Métronome (coups parfaits),
  Sève (soin par Muet), Furie, Pieds légers, Œil du faucon (critique).
- La jungle reprend ses couleurs et la musique ses couches de clairière en clairière.
- **Régions** (version 2.6) : on choisit à l'écran titre où partir (flèches autour du nom) ; libérer le gardien
  d'une région ouvre la suivante (le résumé l'annonce). Chacune ses formes de clairière, son herbe, sa terre, son
  feuillage, sa brume, sa couche de musique, ses vagues préférées et son **gardien** :
  - *Sous-bois* : clairières, bosquets, troncs, champignonnières ; le **Grand Muet**.
  - *Ruines englouties* (sarcelle, udus et gouttes d'eau) : ruines, **rivières** à franchir sur des ponts
    (l'eau ralentit, héros comme Muets), estrades ; le **Gardien des Ruines**, en pierre moussue, qui fait
    tomber des **piliers** annoncés (un cercle rouge) ou frappe le sol, en alternance.
  - *Canopée* (vert-jaune, bambous et oiseaux) : **plateformes** et passerelles en hauteur, lianes fouets ;
    la **Reine des Cimes**, ailée, qui fond sur le héros et sème une couronne de bulles en s'écrasant.
- **Décor de jeu** (version 2.6) : **épines** qui jaillissent au tempo (un cercle rouge le temps d'avant) et
  **lianes fouets** qui balaient une ligne annoncée ; elles blessent aussi les Muets (on les y projette).
  **Tambours de guerre** à frapper : une onde étourdit et ébranle les Muets autour, le groove monte ; puis il se
  recharge (il bat au rythme quand il est prêt). **Jarres** (plumes d'or ou un peu de soin) ; **rocher fêlé**
  (3 coups) qui ouvre un **passage secret** vers un trésor sans combat.
- **Salles spéciales** (version 2.6), annoncées par leur passage : **repos** (un feu de camp : +40 % des PV,
  ou affûter un don déjà pris d'un rang), **trésor** (un coffre après le combat : 35 plumes d'or et un don),
  **secret** (un coffre sans combat : 50 plumes d'or et un don).
- **Fin** : Grand Muet libéré (jungle libérée), héros évanoui, ou retour depuis la pause. On garde
  l'expérience (le niveau) et les plumes d'or.
- **Le village vivant** (version 2.7) : le camp de l'écran titre est le village. Au retour d'une expédition
  (« Retour » du résumé), ou par le bouton « Le village » de l'écran titre, on y marche : un feu au centre, le
  **Chef Taroum** devant, des danseurs autour (un de plus par case rebâtie ; ils enchaînent les saltos après une
  victoire). Le Chef **commente l'expédition** en une réplique au-dessus de lui : le gardien presque libéré, le
  record de clairières, la première victoire, la région qui s'ouvre, ou la réponse à l'espèce qui a fait tomber le
  héros (« Un bouclier ne protège que de face… ») ; puis, si les plumes le permettent, il rappelle de rebâtir.
  Quatre **chantiers** (piquets, planches, pierres renversées) : s'en approcher propose de les rebâtir contre des
  plumes d'or ; rebâtie, la case surgit en couleurs (gerbe arc-en-ciel) et dit ce qu'elle fait quand on s'en
  approche :
  - *l'autel des esprits* (90) : un don de plus au choix à chaque offre ;
  - *la case du tambourinaire* (70) : les rencontres paraissent plus souvent ;
  - *la source* (50, 100, 160 : trois rangs) : +10 PV au départ par rang ;
  - *la scène* (110) : la troupe accompagne l'expédition et la musique part avec une couche de plus.
  La musique du village gagne une couche par case rebâtie. Le passage du nord part en expédition ; la pause
  ramène à l'écran titre.
Le reste du document décrit la nuit dans le monde voxel (mode d'origine), dont l'expédition reprend le
combat, les Muets et le monde.

## 3. Boucle de jeu
Une nuit = partir du village → atteindre un sanctuaire → vaincre le **Grand Muet** qui garde le tambour → rapporter le tambour.
Trois tambours = nuit accomplie. Tomber = retour au village : on garde niveau, objets et tambours déjà rapportés.

**Tout se tient** (symbiose, version 1.1) : chaque mécanique nourrit les autres, sans monnaie ni défi à côté.
- **Le rythme rend la couleur** : la jauge de groove fait revivre la jungle autour du héros (un cercle de
  couleurs qui grandit avec elle) ; le Salto arc-en-ciel la fait éclater loin.
- **Chaque Muet attend sa réponse** (§7) : la bonne acrobatie remplit la jauge et lui rend un instant ses couleurs.
- **Le héros grandit au village** : l'expérience des Muets libérés s'y ajoute quand il y revient ; le cadeau
  de chaque Grand Muet voyage avec son tambour ; le sac et les talents s'ouvrent au village.
- **Les Muets libérés rejoignent le village** : ils y dansent, en couleurs, jusqu'à la fin de la nuit.

## 4. Commandes (mobile)
- **Joystick flottant** à gauche : la base se fixe là où le pouce se pose et **ne le suit jamais** ; repère discret au repos en bas à gauche.
- **Trois boutons** en arc à droite : Frappe (le plus gros), Saut, Esquive. Pictogrammes, pas de texte.
- Clavier / manette : déplacement, Espace = saut, J = frappe, K = esquive.
- Chaque appui est **mémorisé 0,2 s** et s'exécute dès que possible ; l'esquive et le saut **interrompent n'importe quel coup**.

## 5. Déplacements
Saut à hauteur variable (relâcher tôt = petit saut), **double saut = salto**, champignons-trampolines,
**roulade** invulnérable, **élan aérien**, tolérance de saut en bord de plateforme.
Relief à exploiter : rochers, souches, perchoirs en escalier.

## 6. Combat
- Enchaînement au pied inspiré de la **capoeira** : martelo → meia-lua → armada (coup tournoyant qui frappe tout autour).
- **Plongeon** : Frappe en l'air. Plus on tombe de haut, plus l'onde est large et forte.
- **Coup roulé** : Frappe pendant ou juste après une roulade.
- **Esquive parfaite** : être touché pendant l'invulnérabilité → ralenti + prochain coup critique.
- **Rythme** : chaque action est jugée au moment de l'appui. Parfait ×1,5, Bien ×1,15.
  La jauge de groove pleine débloque le **Salto arc-en-ciel** (bond + plongeon géant).
  Elle se remplit en rythme, par les bonnes réponses aux Muets, les esquives parfaites, et d'un coup avec la
  **plume arc-en-ciel** posée au sommet de chaque perchoir (elle revient à chaque sortie).
  Autour du héros, la jungle retrouve ses couleurs d'autant plus loin que la jauge est pleine.
- Retour d'impact : arrêt sur image, traînée du coup, étincelle, secousse, poussée de caméra, son qui monte avec le combo.
- **Équilibre** (version 2.3) : chaque coup entame l'équilibre du Muet (une petite barre au-dessus de sa tête,
  qui se remplit après un moment sans coup). Brisé, il **chancelle** (« Brisé ! », étourdi, plus fragile) ;
  Frappe près de lui est alors le **coup de grâce** : un salto qui le libère d'un coup (le Grand Muet, lui,
  encaisse un grand coup). Frapper un bouclier ébranle aussi : à force, la garde cède.
- **Projection** : l'armada, le coup chargé, la riposte, le plongeon envoient valser. Un Muet projeté contre un
  arbre, un pilier ou un mur se blesse et reste sonné ; contre un autre Muet, les deux se blessent et l'autre
  part à son tour (billard).
- **Coup chargé** : Frappe maintenue pendant un coup ; le héros se ramasse, la charge monte (étincelles d'or,
  son qui monte), puis il frappe en relâchant (jugé sur le temps au relâcher) : jusqu'à ×2,2, brise les gardes.
- **Riposte** : après une esquive parfaite, Frappe bondit sur le Muet esquivé : coup critique qui ébranle et projette.
- **La troupe chante** : quand le combo tient, la couche de la troupe du village monte dans la musique.

## 7. Les Muets
Anciens musiciens du village : bouche cousue, grands yeux, antennes aux couleurs volées.

| Muet | Comportement | Réponse attendue | Coup qui la donne |
|---|---|---|---|
| Sautillant | avance par bonds, contact | enchaînement de base | armada (3e coup) |
| Volant | tourne au-dessus, pique après une ligne rouge au sol, puis s'écrase au sol, étourdi (1,6 s) | esquiver le piqué, puis le frapper au sol | coup en l'air (plongeon) ou tout coup quand il est étourdi |
| Porte-bouclier | bloque de face, se tourne lentement | passer derrière ou plonger dessus | tout coup de dos, plongeon |
| Cornu | charge en ligne droite après 2 temps d'annonce, s'assomme contre les arbres | esquive au dernier moment ou saut | tout coup quand il est assommé |
| Cracheur | garde ses distances, crache des bulles | sauter par-dessus, s'approcher | coup roulé |
| Tisserand | garde ses distances, fait pousser des ronces sous le héros (cercle annoncé 2 temps) | sortir du cercle, lui sauter dessus | plongeon |
| Totem chanteur | reste en retrait, chante : les Muets proches sont protégés (dégâts ÷2), soignés, pressés | l'abattre d'abord | coup chargé |
| Danseur | vif, tourne autour du héros, esquive un coup sur deux puis contre d'une vrille | esquiver la vrille, riposter | riposte |
| Brute | lente ; lève les poings, bondit sur la ligne annoncée, saisit et jette ; puis essoufflée | esquiver, frapper quand elle souffle | tout coup quand elle est sonnée |

**Grand Muet** : frappe au sol annoncée par un cercle rouge (2 temps). À mi-vie, il enrage et envoie des ondes de choc à sauter.
Sous le quart de ses PV (version 2.4), dernière phase : il rugit, appelle ses gardiens, lance une couronne de bulles
à chaque frappe et attaque plus souvent.

**Vagues composées** (version 2.4) : chaque vague suit un modèle de rôles qui se complètent (meute, essaim, mur de
boucliers et de cracheurs, cavalerie de cornus, ronces, bal de danseurs, chœur d'un totem, brutes, fanfare) ;
les espèces de retrait apparaissent plus loin.
**Élites** : un par expédition (clairière tirée de la graine), plus gros, couronné d'or, avec sa barre et son nom et
une particularité : vif, cuirassé, éclatant (explose une fois libéré), appelant (renforts à mi-vie), doré (plumes
d'or). Libéré, il offre un **don de l'élite** après la récompense de la clairière.
Sa réponse : le **Salto arc-en-ciel**. Libéré, il retrouve sa voix et remercie (réplique sonore courte).

**La bonne réponse** fait plus de dégâts (×1,6), remplit la jauge de groove, rend un instant ses couleurs au Muet
(gerbe de cubes) et sonne une note. Les autres coups marchent toujours (pilier 2). À la première rencontre
d'une espèce, un conseil près du bon bouton apprend sa réponse.

**Libérés**, les Muets rejoignent le village : plus petits, en couleurs, ils dansent autour de la place
(un bond un temps sur deux) jusqu'à la fin de la nuit ; les Grands Muets aussi, avec leur couronne.

## 8. Secrets
- **Cercle des gongs** : dans une clairière près d'un chemin, 4 gongs jouent une mélodie au rythme (3 notes la
  nuit 1, 4 la nuit 2, 5 ensuite) ; la rejouer dans l'ordre fait apparaître un coffre.
- **Coffres cachés** au sommet des perchoirs : une page du carnet, et le rythme qu'ils gardaient remplit la jauge
  de groove (pas d'objet : les objets sont les cadeaux des Grands Muets).
- **Le carnet** (12 pages) raconte le Grand Silence : chaque nuit de la saga cache ses pages (le coffre des gongs
  garde la première) ; le Roi Muet se révèle la nuit 5. L'écran Carnet (pause, titre) dit où chercher les pages
  manquantes. Une page trouvée : petite carte en bas.
- **Grand Muet libéré** : il retrouve sa voix, une courte réplique au-dessus de lui.

## 9. Progression
Le héros **grandit au village** : c'est là que l'on revient, que l'on fête et que l'on se prépare.
- Niveau conservé ; 1 point de talent par niveau ; 3 voies (Acrobate, Percussion, Chamane) de 4 talents ; réinitialisation gratuite.
- L'expérience des Muets libérés est **mise de côté** pendant la sortie (sa part bat dans la barre) et s'ajoute
  quand le héros rentre au village (ou à la fin de la sortie) ; le Chef salue chaque niveau gagné.
- Objets : 3 emplacements (chevillières, masque, talisman), 4 raretés, effets aléatoires, 5 légendaires à effet unique.
  Pas de butin au sol : chaque **Grand Muet offre un cadeau** qui voyage avec son tambour et arrive dans le sac
  au village (perdu en route, il retourne à l'autel avec le tambour). Sac plein : le plus faible des objets
  non portés laisse sa place.
- Le **sac et les talents** s'ouvrent au village (depuis la pause) et depuis l'écran titre et le résumé.
- Ni monnaie, ni forge, ni défis, ni score : le résumé d'une sortie dit les tambours, les Muets libérés,
  le niveau et le temps.

## 10. Histoire (résumé)
Avant le Grand Silence, chaque Muet était un musicien. Le Silence a bu leurs voix puis les couleurs.
Les tambours sont les derniers cœurs du village. Le **Roi Muet** fut le premier tambour : il a ouvert la porte au Silence
pour entendre « ce qu'il y avait après la musique ». Le **Chef Taroum** le sait et n'en parle jamais.

## 11. Direction artistique
- **Style** : low-poly stylisé, formes rondes, silhouettes fortes. Un seul pack d'assets par famille (personnages, nature) pour la cohérence.
- **Échelles** : personnage 1,8 m ; Muets 0,7 à 1,1 m (à la taille du héros) ; arbres 5 à 8 m. Chaque asset est vérifié contre le personnage.
- **Palette** : nuit indigo et sarcelle ; accents chauds (or, orange) pour ce qui est vivant (tambours, feux, héros) ;
  Muets en violet désaturé, antennes colorées. Le monde commence **désaturé** et regagne ses couleurs à chaque tambour (étalonnage global).
- **Lumière** : lune froide, lanternes chaudes au village, brouillard léger, bloom sur les éléments émissifs uniquement.
- **Animation** : squelettique (packs ou Mixamo), anticipation et relâché sur les coups ; les Muets ne bougent jamais tous en même temps.
- Avant de produire : choisir ensemble 3 ou 4 références (jeux ou images) et le pack d'assets principal.
- **Monde** (version 2.5) : lumière chaude côté soleil, froide côté ombre, arêtes des cubes un peu assombries
  (relief des voxels), contre-jour sur le héros et les Muets pour qu'ils se détachent. Sol sans quadrillage :
  grandes plaques d'herbe, taches de terre, petits carrés un rien différents ; touffes d'herbe haute, cailloux,
  fougères. Bord des clairières : palmiers, buissons et arbres devant, fromagers aux couronnes plates derrière,
  lianes qui pendent. Mares d'eau sarcelle qui ondulent au bord de pierres. Lucioles qui palpitent et rayonnent,
  feuilles qui tombent. Ce qui est entre la caméra et le héros s'efface (tout à fait sur la ligne de vue).
- **Écrans et menus** (version 2.2) : « jungle tribale en cubes », tout dessiné par le code (net à toutes
  les tailles). Boutons en planches de bois sculpté (biseau clair en haut, sombre en bas, coins en escalier,
  veinures), l'action principale en planche dorée cloutée ; cartes des dons et des rencontres en **peaux de
  tambour** lacées, encre sombre ; pages du carnet en parchemin sous un **bandeau tissé** aux couleurs volées
  (rose, or, cyan, vert), qui souligne aussi chaque titre. Fond : le jeu flou derrière un voile de jungle,
  des feuilles en cubes aux coins qui se balancent sur la musique, des cubes de couleur qui montent.
  À l'ouverture : le titre tombe, le bandeau se tisse, chaque élément surgit l'un après l'autre ; chaque carte
  de don sonne un petit tambour, un ton plus haut que la précédente ; un bouton appuyé s'enfonce.
  Dans le jeu, l'objectif, les messages et le bouton pause sont de petites plaques de bois.

## 12. Charte des retours à l'écran (leçon du prototype)
- **Le monde parle d'abord** : effets, sons, réactions des personnages avant tout texte.
- **Au plus un message éphémère à la fois**, 5 mots maximum, jamais au centre de l'action (en haut, ou près de sa source).
- **Grands titres** réservés à 3 moments : début de nuit, sanctuaire libéré, nuit accomplie.
- **Chiffres de dégâts** discrets et désactivables.
- **Aide contextuelle** : le bon bouton brille, 2 à 4 mots, disparaît dès que l'action est faite.
- **Butin** : le cadeau d'un Grand Muet arrive au village avec son tambour : une petite carte en bas pendant 2 s ;
  le détail est dans le sac.
- **Pas de bulles** qui couvrent le jeu : répliques courtes, surtout sonores.

## 13. Audio
Musique en couches calée sur 104 BPM ; chaque tambour rapporté ajoute une couche.
La troupe du village (Muets libérés) a sa couche : un chœur et des mains qui claquent, d'autant plus fort
que la troupe est grande et que le héros est près du village.
Gongs en gamme pentatonique. Coups en couches (impact + souffle + note), légères variations aléatoires.

## 14. Tranche verticale : hors périmètre
Cinq nuits, nuits sans fin, cracheur, porte-bouclier, talents, carnet complet.

## Annexe : textes
**Nuits** — 1 : Le vol des tambours · 2 : La nuit des boucliers · 3 : La charge des cornus · 4 : Le chœur des cracheurs · 5 : Le Roi Muet.
**Chef, début de nuit 1** : « Les Muets ont volé nos trois tambours ! Rapporte-les avant l'aube. »
**Muets libérés** : « Ma voix… elle est revenue ! » · « Je me souviens de la chanson ! » · « Merci, petit acrobate ! » · « Enfin, j'entends la jungle ! »

**Pages du carnet**
1. Avant le Grand Silence, chaque Muet était un musicien du village. Leurs voix faisaient danser la jungle.
2. Le Grand Silence est venu une nuit sans lune. Il a bu les voix d'abord, puis les couleurs.
3. Ceux qui ont perdu leur voix ont perdu leur visage. Ils errent, bouche cousue, en cherchant un rythme à voler.
4. Les tambours sont les derniers cœurs du village. Tant qu'ils battent, le Silence ne peut pas entrer.
5. Les gongs des anciens sanctuaires gardent un morceau de chaque chanson. Rejoue-la, et ils se souviennent.
6. Un Muet libéré retrouve sa voix d'un seul coup. Le premier son qu'il fait est toujours un rire.
7. Les cornus portaient les grands tambours. Ils chargent encore, par habitude, vers le bruit qu'ils ont perdu.
8. Les volants étaient les flûtistes. Écoute bien leurs ailes : elles sifflent encore un peu.
9. Le Roi Muet fut le premier tambour du village. C'est lui qui a ouvert la porte au Silence, pour entendre ce qu'il y avait après la musique.
10. Le Chef Taroum sait tout cela. Il n'en parle jamais, mais il danse plus fort chaque fois qu'un tambour revient.
11. Quand les cinq nuits seront passées, le Silence ne partira pas. Il attendra, patient, qu'on oublie de jouer.
12. Alors il faudra jouer encore, chaque nuit. C'est pour ça que les nuits sans fin existent.
