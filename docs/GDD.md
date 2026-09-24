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

## 3. Boucle de jeu
Une nuit = partir du village → atteindre un sanctuaire → vaincre le **Grand Muet** qui garde le tambour → rapporter le tambour.
Trois tambours = nuit accomplie. Tomber = retour au village : on garde niveau, objets et tambours déjà rapportés.

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
- Retour d'impact : arrêt sur image, traînée du coup, étincelle, secousse, poussée de caméra, son qui monte avec le combo.

## 7. Les Muets
Anciens musiciens du village : bouche cousue, grands yeux, antennes aux couleurs volées.

| Muet | Comportement | Réponse attendue |
|---|---|---|
| Sautillant | avance par bonds, contact | enchaînement de base |
| Volant | tourne au-dessus, pique après une ligne rouge au sol | sauter pour le frapper, esquiver le piqué |
| Porte-bouclier | bloque de face, se tourne lentement | passer derrière ou plonger dessus |
| Cornu | charge en ligne droite après 2 temps d'annonce, s'assomme contre les arbres | esquive au dernier moment ou saut |
| Cracheur | garde ses distances, crache des bulles | sauter par-dessus, s'approcher |

**Grand Muet** : frappe au sol annoncée par un cercle rouge (2 temps). À mi-vie, il enrage et envoie des ondes de choc à sauter.
Libéré, il retrouve sa voix et remercie (réplique sonore courte).

## 8. Secrets
- **Cercle des gongs** : 4 gongs jouent une mélodie au rythme ; la rejouer dans l'ordre fait apparaître un coffre.
- **Coffres cachés** en hauteur (piliers, perchoirs) : un objet + une page du carnet.

## 9. Progression
- Niveau conservé ; 1 point de talent par niveau ; 3 voies (Acrobate, Percussion, Chamane) de 4 talents ; réinitialisation gratuite.
- Objets : 3 emplacements (chevillières, masque, talisman), 4 raretés, effets aléatoires, 5 légendaires à effet unique.
  Forge de +1 à +5 avec des plumes ; recyclage.

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

## 12. Charte des retours à l'écran (leçon du prototype)
- **Le monde parle d'abord** : effets, sons, réactions des personnages avant tout texte.
- **Au plus un message éphémère à la fois**, 5 mots maximum, jamais au centre de l'action (en haut, ou près de sa source).
- **Grands titres** réservés à 3 moments : début de nuit, sanctuaire libéré, nuit accomplie.
- **Chiffres de dégâts** discrets et désactivables.
- **Aide contextuelle** : le bon bouton brille, 2 à 4 mots, disparaît dès que l'action est faite.
- **Butin** : l'objet jaillit du sol, puis une petite carte en bas pendant 2 s ; le détail est dans le sac.
- **Pas de bulles** qui couvrent le jeu : répliques courtes, surtout sonores.

## 13. Audio
Musique en couches calée sur 104 BPM ; chaque tambour rapporté ajoute une couche.
Gongs en gamme pentatonique. Coups en couches (impact + souffle + note), légères variations aléatoires.

## 14. Tranche verticale : hors périmètre
Cinq nuits, nuits sans fin, cracheur, porte-bouclier, talents, forge, carnet complet.

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
