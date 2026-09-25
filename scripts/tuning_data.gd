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
## Profondeur de chute sous le point de départ qui ramène le héros au départ (m).
@export var respawn_fall_depth: float

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
## Rayon du joystick tactile, en unités d'interface (base 400 : environ des dp sur téléphone).
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
## Nombre de sauts avant de toucher le sol ; le dernier est le salto.
@export var max_jumps: int
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

@export_group("Combat")
## Niveau du héros au début d'une partie.
@export var hero_start_level: int
## Attaque du héros au niveau 1.
@export var hero_attack_base: float
## Attaque gagnée par niveau.
@export var hero_attack_per_level: float
## Enchaînement au sol, dans l'ordre (martelo, meia-lua, armada).
@export var combo_attacks: Array[AttackData]
## Coup roulé : Frappe pendant ou juste après une roulade.
@export var rolling_kick: AttackData
## Délai après la fin d'une roulade pendant lequel Frappe donne encore le coup roulé (s).
@export var rolling_kick_grace: float
## Délai après la fin d'un coup pendant lequel Frappe continue l'enchaînement (s).
@export var combo_chain_window: float
## Poussée du joystick (fraction) qui écourte la fin d'un coup.
@export var move_cancel_threshold: float
## Délai après le point d'enchaînement avant que le joystick puisse écourter le coup (s).
@export var move_cancel_delay: float
## Cône d'orientation automatique vers la cible la plus proche (degrés).
@export var auto_aim_cone_deg: float
## Portée de l'orientation automatique (m).
@export var auto_aim_range: float
## Durée pendant laquelle un coup touche, à partir de l'impact (s).
@export var attack_active_time: float
## Rayon de détection de la zone de coup (m) : doit couvrir la plus grande portée plus le rayon des cibles.
@export var hitbox_radius: float
## Chance de coup critique (fraction).
@export var crit_chance: float
## Multiplicateur d'un coup critique.
@export var crit_multiplier: float
## Bonus de dégâts par coup du combo (fraction).
@export var combo_bonus_per_hit: float
## Bonus de combo maximal (fraction).
@export var combo_bonus_max: float
## Durée sans toucher avant de perdre le combo (s).
@export var combo_timeout: float

@export_group("Plongeon")
## Vitesse de chute du plongeon (m/s).
@export var dive_fall_speed: float
## Rayon de l'onde sans hauteur de chute (m).
@export var dive_radius_base: float
## Rayon d'onde gagné par mètre de chute (m/m).
@export var dive_radius_per_meter: float
## Bonus de rayon maximal (m).
@export var dive_radius_bonus_max: float
## Multiplicateur de dégâts sans hauteur de chute.
@export var dive_multiplier_base: float
## Multiplicateur gagné par mètre de chute.
@export var dive_multiplier_per_meter: float
## Bonus de multiplicateur maximal.
@export var dive_multiplier_bonus_max: float
## Temps au sol après l'onde avant de pouvoir repartir (s).
@export var dive_recovery: float
## Clip de la pose du plongeon (bibliothèque/nom).
@export var dive_animation: StringName
## Instant du clip figé pendant la chute (s).
@export var dive_pose_time: float
## Inclinaison du corps vers l'avant pendant la chute (degrés).
@export var dive_pitch_deg: float

@export_group("Retours d'impact")
## Arrêt sur image quand un coup touche (s).
@export var hit_stop_hit: float
## Secousse de caméra quand un coup touche (0 à 1).
@export var shake_trauma_hit: float
## Secousse de caméra pour l'onde du plongeon (0 à 1).
@export var shake_trauma_dive: float
## Vitesse à laquelle la secousse s'éteint (/s).
@export var shake_decay: float
## Décalage maximal de la caméra à pleine secousse (m).
@export var shake_max_offset: float
## Poussée de la caméra dans la direction du coup, à pleine secousse (m).
@export var camera_push: float
## Durée de l'étincelle d'impact (s).
@export var spark_time: float
## Durée de vie de la traînée du coup (s).
@export var trail_time: float
## Début de la traînée le long de la jambe, en multiples de la distance hanche-pied.
@export var trail_inner_reach: float
## Bout de la traînée, en multiples de la distance hanche-pied (au-delà de 1 : prolongée).
@export var trail_outer_reach: float
## Durée d'expansion de l'onde du plongeon (s).
@export var shockwave_time: float

@export_group("Animation")
## Fondu entre deux animations (s).
@export var anim_blend_time: float
## Vitesse en dessous de laquelle le héros est considéré immobile (m/s).
@export var idle_speed_threshold: float
## Vitesse du cycle de course à pleine vitesse (1 = vitesse du clip).
@export var run_animation_speed: float
## Hauteur du pivot de la roulade au-dessus des pieds (m).
@export var roll_pivot_height: float

@export_group("Mannequin")
## Hauteur du mannequin d'entraînement (m).
@export var dummy_height: float
## Rayon du mannequin, pour la portée des coups et les collisions (m).
@export var dummy_radius: float
## Points de vie du mannequin (il se relève quand ils sont épuisés).
@export var dummy_health: float
## Recul visuel du mannequin quand il est touché (m).
@export var dummy_recoil_distance: float
## Durée du recul du mannequin (s).
@export var dummy_recoil_time: float

@export_group("Rythme")
## Tempo de la musique (battements par minute).
@export var rhythm_bpm: float
## Avance tolérée pour un Parfait (s).
@export var perfect_early: float
## Retard toléré pour un Parfait (s).
@export var perfect_late: float
## Avance tolérée pour un Bien (s).
@export var good_early: float
## Retard toléré pour un Bien (s).
@export var good_late: float
## Multiplicateur de dégâts d'un Parfait.
@export var perfect_multiplier: float
## Multiplicateur de dégâts d'un Bien.
@export var good_multiplier: float
## Arrêt sur image d'un coup Parfait (s).
@export var hit_stop_perfect: float
## Taille de l'étincelle d'un coup Parfait (1 = étincelle normale).
@export var perfect_spark_scale: float
## Jauge de groove pleine.
@export var groove_max: float
## Groove gagné par un coup Parfait qui touche.
@export var groove_perfect: float
## Groove gagné par un coup Bien qui touche.
@export var groove_good: float
## Volume d'une couche de musique audible (dB).
@export var music_volume_db: float
## Volume d'une couche de musique qui se tait (dB).
@export var music_silent_db: float
## Fondu quand une couche apparaît ou se tait (s).
@export var music_layer_fade_time: float
## Rayon de l'anneau de battement au début de chaque temps (m).
@export var beat_ring_radius_max: float
## Rayon de l'anneau de battement sur le temps (m).
@export var beat_ring_radius_min: float
## Opacité maximale de l'anneau de battement (0 à 1).
@export var beat_ring_opacity: float
## Durée de l'éclat de l'anneau après un appui jugé (s).
@export var judgement_flash_time: float
## Notes du carillon Parfait, en demi-tons au-dessus du son de base : il monte avec le combo.
@export var chime_scale_semitones: PackedFloat32Array
## Volume du carillon pour un Bien (dB, le Parfait est à 0).
@export var good_chime_volume_db: float
## Variation aléatoire de la hauteur du son d'impact (fraction).
@export var hit_pitch_variation: float
## Durée d'un tour complet des couleurs de la jauge pleine (s).
@export var groove_rainbow_cycle_time: float

@export_group("Salto arc-en-ciel")
## Vitesse du bond avant le plongeon géant (m/s).
@export var rainbow_hop_speed: float
## Rayon minimal de l'onde (m).
@export var rainbow_radius: float
## Multiplicateur de dégâts.
@export var rainbow_multiplier: float
## Durée d'étourdissement des cibles touchées (s).
@export var rainbow_stun: float
