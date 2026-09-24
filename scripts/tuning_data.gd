class_name TuningData
extends Resource
## Tous les réglages chiffrés du jeu, en mètres, secondes et degrés.
## Les valeurs vivent uniquement dans res://data/tuning.tres (points de départ : docs/REGLAGES.md).
## Aucune valeur par défaut ici : un réglage oublié dans le .tres reste à 0 et fait échouer les tests.
## Les autres sections (coups, rythme, Muets, progression) arrivent avec leur jalon.

@export_group("Héros")
## Taille du héros (m) : référence d'échelle pour tous les assets.
@export var hero_height: float
## Rayon de la capsule du héros (m).
@export var hero_radius: float

@export_group("Déplacement")
## Vitesse de course (m/s).
@export var run_speed: float
## Lissage exponentiel de l'accélération au sol (/s).
@export var ground_accel_rate: float
## Lissage exponentiel du freinage au sol (/s).
@export var ground_brake_rate: float
## Lissage exponentiel du contrôle en l'air (/s).
@export var air_control_rate: float
## Lissage de la rotation vers la direction de course, au sol (/s).
@export var turn_rate_ground: float
## Lissage de la rotation vers la direction de course, en l'air (/s).
@export var turn_rate_air: float
## Hauteur de marche franchie sans sauter (m).
@export var step_height: float

@export_group("Joystick")
## Rayon du joystick tactile (px, à l'échelle de l'interface).
@export var joystick_radius_px: float
## Zone morte, en fraction du rayon.
@export var joystick_dead_zone: float
## Fraction du rayon à partir de laquelle on court à pleine vitesse.
@export var joystick_full_speed: float

@export_group("Saut")
## Gravité en montée, bouton tenu (m/s²).
@export var gravity_rise_held: float
## Gravité en montée, bouton relâché : petit saut (m/s²).
@export var gravity_rise_released: float
## Gravité en descente (m/s²).
@export var gravity_fall: float
## Vitesse initiale du saut (m/s).
@export var jump_speed: float
## Vitesse initiale du double saut, le salto (m/s).
@export var double_jump_speed: float
## Durée de la rotation du salto (s).
@export var salto_duration: float
## Vitesse donnée par un champignon-trampoline (m/s).
@export var mushroom_bounce_speed: float
## Tolérance de saut après avoir quitté un bord (s).
@export var coyote_time: float
## Mémoire des appuis, pour tous les boutons (s).
@export var input_buffer_time: float

@export_group("Roulade")
## Durée de la roulade (s).
@export var roll_duration: float
## Distance parcourue par la roulade (m).
@export var roll_distance: float
## Fraction finale de la roulade jouée au ralenti.
@export var roll_tail_fraction: float
## Facteur de vitesse pendant la fin de roulade.
@export var roll_tail_speed_factor: float
## Début de l'invulnérabilité, en fraction de la roulade.
@export var roll_invuln_start: float
## Fin de l'invulnérabilité, en fraction de la roulade.
@export var roll_invuln_end: float
## Délai avant de pouvoir relancer une roulade après la fin (s).
@export var roll_cooldown: float
## Fraction à partir de laquelle une nouvelle roulade peut s'enchaîner.
@export var roll_chain_from: float
## Fraction à partir de laquelle on peut sauter depuis une roulade.
@export var roll_jump_from: float
## Vitesse horizontale conservée en sautant depuis une roulade (m/s).
@export var roll_jump_carry_speed: float

@export_group("Élan aérien")
## Vitesse de l'élan aérien (m/s).
@export var air_dash_speed: float
## Durée de l'élan aérien (s).
@export var air_dash_duration: float
## Durée d'invulnérabilité de l'élan aérien (s).
@export var air_dash_invuln: float
## Nombre d'élans aériens par saut.
@export var air_dashes_per_jump: int

@export_group("Caméra")
## Inclinaison vers le bas (degrés).
@export var camera_tilt_deg: float
## Hauteur du point visé au-dessus des pieds du héros (m).
@export var camera_target_height: float
## Distance au point visé en portrait (m).
@export var camera_distance_portrait: float
## Distance au point visé en paysage (m).
@export var camera_distance_landscape: float
## Champ de vision vertical en portrait (degrés).
@export var camera_fov_portrait_deg: float
## Champ de vision vertical en paysage (degrés).
@export var camera_fov_landscape_deg: float
## Lissage du suivi (/s).
@export var camera_follow_rate: float
## Anticipation dans la direction de course (m).
@export var camera_lookahead: float
## Recul en combat, en fraction de la distance.
@export var camera_combat_pullback: float
## Distance d'un Muet qui attaque déclenchant le recul (m).
@export var camera_combat_radius: float
