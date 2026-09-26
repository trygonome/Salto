# Réglages validés dans le prototype

Le prototype mesurait tout en « unités » (u) avec un héros de 7 u.
**Conversion : 1 u ≈ 0,26 m** pour un héros de 1,8 m. Les valeurs du contrôleur sont données directement en mètres.
Les durées sont en secondes. Ce sont des **points de départ** : tout se réajuste en jouant.

## Déplacement
| Réglage | Valeur |
|---|---|
| Vitesse de course | 2,8 m/s dans le prototype (caméra très éloignée) ; tester 3,5 à 5 m/s |
| Accélération / freinage au sol | lissage exponentiel 11 /s (accélère), 14 /s (freine) |
| Contrôle en l'air | lissage 5 /s |
| Rotation vers la direction | lissage 16 /s au sol, 7 /s en l'air |
| Joystick | rayon 46 px, zone morte 12 %, pleine vitesse à 57 %, **base fixe** |

## Saut
| Réglage | Valeur |
|---|---|
| Gravité en montée, bouton tenu | 9,8 m/s² |
| Gravité en montée, bouton relâché (petit saut) | 18 m/s² |
| Gravité en descente | 11,8 m/s² |
| Vitesse initiale du saut | 3,9 m/s (sommet ≈ 0,75 m) |
| Double saut (salto) | 4,0 m/s ; salto de 0,5 s |
| Champignon-trampoline | 6,2 m/s |
| Tolérance après le bord (coyote) | 0,1 s |
| Mémoire des appuis (tous les boutons) | 0,2 s |
| Monter une marche sans sauter | jusqu'à 0,12 m |

## Roulade et élan aérien
| Réglage | Valeur |
|---|---|
| Roulade | 0,38 s, 1,55 m ; les 20 % finaux à demi-vitesse |
| Invulnérabilité | de 5 % à 79 % de la roulade (≈ 0,02 à 0,30 s) |
| Relance | 0,08 s après la fin ; nouvelle roulade possible dès 80 % |
| Sauter depuis une roulade | dès 35 %, garde l'élan (3,6 m/s) |
| Élan aérien | 6,7 m/s pendant 0,22 s, vitesse verticale annulée ; invulnérable 0,16 s ; 1 par saut |

## Coups au sol
Portées à ajouter au rayon de l'ennemi. Dégâts = attaque × multiplicateur.

| Coup | Durée | Impact | Enchaînable dès | Portée | Arc | Dégâts | Élan |
|---|---|---|---|---|---|---|---|
| Martelo | 0,34 | 0,12 | 0,17 | 0,80 m | 120° | ×1,0 | 0,33 m |
| Meia-lua | 0,38 | 0,15 | 0,21 | 0,85 m | 150° | ×1,15 | 0,39 m |
| Armada (final) | 0,56 | 0,25 | 0,42 | 1,0 m | 360° | ×1,8 | petit bond |
| Coup roulé | 0,36 | 0,12 | 0,24 | 0,95 m | 86° | ×1,35 | 1,0 m |

- Nouvel enchaînement si l'appui arrive moins de 0,45 s après la fin du coup précédent.
- Pousser le joystick à plus de 50 % écourte la fin d'un coup (0,06 s après le point d'enchaînement).
- Orientation automatique vers le Muet le plus proche dans un cône de 80°, jusqu'à 1,4 m.

## Plongeon et coup spécial
| Réglage | Valeur |
|---|---|
| Vitesse de chute du plongeon | 8,7 m/s |
| Rayon de l'onde | 0,72 m + 0,35 × hauteur de chute (m), plafonné à +0,77 m |
| Multiplicateur | 1,3 + 0,7 × hauteur de chute (m), plafonné à +1,5 |
| Salto arc-en-ciel | bond à 4,4 m/s puis plongeon ; rayon ≥ 2,4 m ; dégâts ×2,5 ; étourdit 1,5 s ; invulnérable |

## Rythme
| Réglage | Valeur |
|---|---|
| Tempo | 104 BPM (un temps ≈ 0,577 s) |
| Jugement | au moment de l'appui, pas de l'exécution |
| Fenêtre Parfait | de 0,068 s avant à 0,11 s après le temps (tolérante au retard du tactile) |
| Fenêtre Bien | de 0,112 s avant à 0,182 s après |
| Bonus | Parfait ×1,5, Bien ×1,15 |
| Jauge de groove (sur 10) | Parfait +2, Bien +0,5, Muet libéré +1, esquive parfaite +2, onde sautée +1 |

## Retour d'impact
| Réglage | Valeur |
|---|---|
| Arrêt sur image | 0,05 s (coup), 0,075 s (Parfait), 0,06 s (héros touché) |
| Ralenti d'esquive parfaite | 0,45 s à 30 % de vitesse |
| Critique | 15 % de base, ×1,6 ; garanti après une esquive parfaite |
| Combo | multiplicateur 1 + min(0,6 ; 0,04 × combo) ; perdu après 2,6 s sans coup ou si touché |
| Traînée du coup | 0,17 s ; étincelle 0,15 s |

## Héros
| Réglage | Valeur |
|---|---|
| Points de vie | 100 + 10 par niveau |
| Attaque | 12 + 2 par niveau |
| Invulnérabilité après un coup reçu | 0,7 s |
| Recul reçu | 3,1 m/s (6 m/s pour les gros coups) |
| Soins au village | 8 PV/s |

## Muets (valeurs du prototype en u ; ×0,26 pour les mètres)
| Muet | PV | Dégâts | Rayon | Particularités |
|---|---|---|---|---|
| Sautillant | 30 | 9 | 1,5 u | bond de 2,2 u à chaque temps |
| Volant | 20 | 8 | 1,2 u | vole à 7,2 u ; tourne à 6,5 u du héros ; piqué tous les 5 temps, annonce 1 temps, piqué 0,85 s |
| Porte-bouclier | 40 | 10 | 1,6 u | tourne à 2,6 rad/s ; bloque de face (±72°) ; coup de bouclier au contact |
| Cornu | 62 | 22 (contact 45 %) | 2,0 u | annonce 2 temps (suit le héros pendant le premier) ; charge à 21 u/s sur 22 u ; assommé 2,2 s contre un obstacle, subit ×1,5 |
| Cracheur | 22 | 9 | 1,4 u | reste entre 7 et 11 u ; bulle à 9 u/s pendant 3,4 s, à hauteur de bouche |

- Grand Muet : PV 170 + 80 par sanctuaire ; frappe au sol annoncée 2 temps, rayon 8 u ; phase 2 à 50 % avec onde de choc à 12 u/s sur 20 u.
- Par nuit : PV +25 %, dégâts +15 %. Détection à 15 u ; retour au poste au-delà de 22 u (gardiens) ou 34 u (errants).
- Les Muets ne bougent pas tous exactement sur le temps : décaler chacun de quelques centièmes pour éviter l'effet mécanique.

## Caméra
| Réglage | Valeur |
|---|---|
| Inclinaison | 57° vers le bas |
| Distance | ≈ 11,8 m en portrait, 9,5 m en paysage |
| Champ vertical | 50° en portrait, 42° en paysage |
| Taille du héros à l'écran | environ 10 à 12 % de la hauteur en portrait |
| Suivi | lissage 3,5 /s ; anticipation de 0,9 m dans la direction de course |
| Combat | recule de 13 % si un Muet attaque à moins de 4,6 m |

## Progression
- XP pour passer du niveau n au suivant : 40 + 30 (n − 1) + 6 (n − 1)².
- XP par Muet : sautillant 9, volant 11, bouclier 14, cornu 18, cracheur 12 (+4 par sanctuaire) ; Grand Muet 70 + 30 par sanctuaire.
  Mise de côté pendant la sortie, ajoutée au village (ou à la fin de la sortie).
- Cadeau d'un Grand Muet (niveau de la nuit + 1), avec son tambour : rare 50 %, épique 35 %, légendaire 15 % ;
  Roi Muet : épique 60 %, légendaire 40 %. Pas d'autre butin.
- Valeur d'un effet d'objet : base × (1 + 0,35 × (niveau d'objet − 1)) × rareté (1 ; 1,25 ; 1,5 ; 1,8) × tirage (0,8 à 1,2).
- Bases : dégâts 6 %, PV 12, résistance 4 %, critique 4 %, vitesse 4 %, vitesse des coups 4 %, groove 10 %, plongeon 12 %, soin par Muet 1, XP 6 %.
- Sac : 30 objets ; plein, le plus faible des objets non portés laisse sa place.

## Symbiose (version 1.1)
- Plume arc-en-ciel au sommet de chaque perchoir : remplit toute la jauge de groove (revient à chaque sortie).
- Cercle du groove autour du héros : 1,3 m jauge vide → 3,5 m jauge pleine ; Salto arc-en-ciel : éclate à 16 m
  puis retombe de 6 m/s. Dans le cercle, saturation 0,9 (teintes de la jungle inchangées).
- Jauge (version 1.2) : après 3 s sans gain, elle retombe de 0,8 par seconde ; pleine, elle attend le Salto.
- Les teintes du monde ondulent sans jamais dériver (version 1.2) ; les fleurs s'éteignent avec le monde
  et fleurissent dans le cercle du groove.
- Réponse attendue (GDD §7) : dégâts × 1,6, jauge + 1 (sur 10), ses propres couleurs rendues au Muet 0,6 s.
- Vibrations (réglage de la pause) : coup 12 ms, coup fort 30 ms, héros touché 70 ms, tambour 50 ms,
  Salto arc-en-ciel 140 ms.
- Troupe du village : 16 Muets libérés au plus, à 60 % de leur taille, sur deux cercles (2,1 m et 3,1 m).
  Son chœur est à pleine voix à partir de 8 Muets, au village ; on l'entend jusqu'à 22 m.
- Cercle des gongs : 4 gongs (ré, mi, fa#, la) sur un cercle de 1,9 m, mélodie de 3, 4 puis 5 notes ;
  il la joue après 2 temps dans sa zone (3,2 m).
