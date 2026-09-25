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
## Coup de pied au début d'un plongeon : touche ce qui est à hauteur du héros en l'air (volants).
@export var air_kick: AttackData
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
## Durée de vie de la traînée du coup (s).
@export var trail_time: float
## Début de la traînée le long de la jambe, en multiples de la distance hanche-pied.
@export var trail_inner_reach: float
## Bout de la traînée, en multiples de la distance hanche-pied (au-delà de 1 : prolongée).
@export var trail_outer_reach: float

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

@export_group("Héros touché")
## Points de vie au niveau 1.
@export var hero_health_base: float
## Points de vie gagnés par niveau.
@export var hero_health_per_level: float
## Invulnérabilité après un coup reçu (s).
@export var hero_hurt_invuln: float
## Durée pendant laquelle le héros encaisse un coup, sans commandes (s).
@export var hero_hurt_time: float
## Vitesse du recul reçu (m/s).
@export var hero_recoil_speed: float
## Vitesse du recul reçu pour les gros coups (m/s).
@export var hero_recoil_big_speed: float
## Arrêt sur image quand le héros est touché (s).
@export var hit_stop_hero: float
## Secousse de caméra quand le héros est touché (0 à 1).
@export var shake_trauma_hurt: float
## Clignotement pendant l'invulnérabilité : durée d'un cycle (s).
@export var hurt_blink_period: float
## Ralenti de l'esquive parfaite : durée en temps réel (s).
@export var perfect_dodge_slow_time: float
## Vitesse du temps pendant ce ralenti (fraction).
@export var perfect_dodge_time_scale: float
## Groove gagné par une esquive parfaite.
@export var groove_perfect_dodge: float
## Groove gagné quand un Muet est libéré.
@export var groove_enemy_freed: float
## Groove gagné en sautant par-dessus une onde de choc.
@export var groove_wave_jumped: float
## Écart de hauteur maximal entre le centre d'un coup et celui de sa cible (m).
@export var attack_vertical_reach: float

@export_group("Muets")
## Distance à laquelle un Muet repère le héros (m) ; une fois lancé, il le garde en vue jusqu'à
## cette distance multipliée par `muet_detection_keep`.
@export var muet_detection_range: float
@export var muet_detection_keep: float
## Distance à son poste au-delà de laquelle un gardien lâche le héros (m).
@export var muet_leash_guard: float
## Même distance pour un Muet errant (m).
@export var muet_leash_wander: float
## Au repos, il rentre vers son poste s'il s'en est éloigné de plus que cette part de sa laisse ;
## sinon il sautille au hasard, parfois (chance par temps), sur une part de son bond.
@export var muet_return_fraction: float
@export var muet_idle_hop_chance: float
@export var muet_idle_hop_fraction: float
## En chasse, il bondit jusqu'au contact du héros, plus cette marge (m).
@export var muet_approach_margin: float
## Bond plus court que cela (m) : il reste sur place.
@export var muet_min_hop: float
## Temps avant sa première attaque, tiré au hasard entre ces deux valeurs.
@export var muet_first_act_min: int
@export var muet_first_act_max: int
## Décalage maximal de chaque Muet par rapport au temps, pour éviter l'effet mécanique (s).
@export var muet_beat_jitter_max: float
## Recul d'un Muet touché (m/s) et sa durée (s).
@export var muet_knockback_speed: float
@export var muet_knockback_time: float
## Contact : il blesse le héros à moins de son rayon plus cette marge (m), au plus une fois par
## `muet_contact_cooldown` (s), s'il n'est pas en l'air (hauteur max, m) et si le héros n'est pas
## au-dessus de lui (part de sa hauteur).
@export var muet_contact_margin: float
@export var muet_contact_cooldown: float
@export var muet_contact_max_lift: float
@export var muet_contact_hero_above: float
## Vitesse à laquelle il se tourne (rad/s).
@export var muet_turn_rate: float
## Éclat blanc d'un Muet touché : durée (s) et force (0 à 1).
@export var muet_hit_flash_time: float
@export var muet_hit_flash_strength: float
## Durée de la libération d'un Muet avant qu'il disparaisse (s), et grossissement.
@export var muet_freed_time: float
@export var muet_freed_pop_scale: float
## Gravité appliquée aux Muets au sol (m/s²).
@export var muet_gravity: float
## Plus forts près des sanctuaires lointains (PV et dégâts en plus par rang de sanctuaire) et
## nuit après nuit (part en plus par nuit).
@export var muet_health_per_tier: float
@export var muet_damage_per_tier: float
@export var muet_health_per_night: float
@export var muet_damage_per_night: float

@export_group("Muets : corps")
## Coup reçu : durée de la réaction (s), élargissement du corps, yeux fermés au-delà de cette part.
@export var muet_hit_time: float
@export var muet_hit_widen: float
@export var muet_hit_eyes_shut: float
## Ressort du corps (gelée) : raideur, amortissement, amplitude maximale, élargissement quand il
## s'écrase, enfoncement, tassement quand il se prépare.
@export var muet_squash_stiffness: float
@export var muet_squash_damping: float
@export var muet_squash_limit: float
@export var muet_squash_widen: float
@export var muet_squash_sink: float
@export var muet_squash_crouch: float
## Élans donnés au ressort : départ d'un bond, atterrissage, coup reçu, frappe, coup de bouclier, crachat.
@export var muet_squash_hop: float
@export var muet_squash_land: float
@export var muet_squash_hit: float
@export var muet_squash_slam: float
@export var muet_squash_bash: float
@export var muet_squash_spit: float
## Respiration au repos : vitesse (rad/s) et hauteur (m).
@export var muet_bob_speed: float
@export var muet_bob_height: float
## Clignement des yeux : intervalle au hasard (s).
@export var muet_blink_min: float
@export var muet_blink_max: float
## Rotation des yeux d'un Muet étourdi (rad/s).
@export var muet_stun_eye_spin: float
## Nombre de couleurs de bouts d'antennes différentes.
@export var muet_tip_variants: int

@export_group("Sautillant")
## Taille d'une case du corps (unités du prototype), PV, dégâts, rayon du corps (m).
@export var hopper_scale: float
@export var hopper_health: float
@export var hopper_damage: float
@export var hopper_radius: float
## Un bond tous les combien de temps ; longueur (m), durée (s) et hauteur (m) d'un bond.
@export var hopper_hop_every: int
@export var hopper_hop_distance: float
@export var hopper_hop_time: float
@export var hopper_hop_height: float

@export_group("Volant")
@export var flyer_scale: float
@export var flyer_health: float
@export var flyer_damage: float
@export var flyer_radius: float
## Altitude de vol (m) ; il la rejoint à cette vitesse (/s) en ondulant (m, rad/s).
@export var flyer_altitude: float
@export var flyer_altitude_rate: float
@export var flyer_bob_height: float
@export var flyer_bob_speed: float
## En chasse, il se tient à cette distance du héros (m), un peu sur le côté (rad) ; il rejoint sa
## place à cette vitesse (/s).
@export var flyer_hover_distance: float
@export var flyer_hover_angle: float
@export var flyer_follow_rate: float
## Au repos, il tourne au-dessus de son poste : rayon (m), vitesse (rad/s).
@export var flyer_idle_radius: float
@export var flyer_idle_speed: float
## Piqué : portée (m), temps de repos entre deux, temps d'annonce (ligne rouge), durée (s),
## élan au-delà du héros (m), hauteur au plus bas (m), courbe de la descente.
@export var flyer_act_max_range: float
@export var flyer_act_cooldown: int
@export var flyer_telegraph_beats: int
@export var flyer_dive_time: float
@export var flyer_dive_overshoot: float
@export var flyer_dive_low: float
@export var flyer_dive_curve: float
## Largeur de la ligne d'annonce (m).
@export var flyer_line_width: float
## Battements d'ailes (rad/s ; plus lents en piqué) et amplitude (rad) ; penché en piqué (rad).
@export var flyer_flap_speed: float
@export var flyer_flap_speed_swoop: float
@export var flyer_flap_angle: float
@export var flyer_swoop_lean: float
## Son ombre est plus petite que son corps (part de son rayon).
@export var flyer_shadow_fraction: float

@export_group("Cornu")
@export var charger_scale: float
@export var charger_health: float
@export var charger_damage: float
## Part des dégâts infligée par simple contact (hors charge).
@export var charger_contact_fraction: float
@export var charger_radius: float
@export var charger_hop_every: int
@export var charger_hop_distance: float
@export var charger_hop_time: float
@export var charger_hop_height: float
## Il charge quand le héros est entre ces distances (m), puis se repose ce nombre de temps.
@export var charger_act_min_range: float
@export var charger_act_max_range: float
@export var charger_act_cooldown: int
## Temps d'annonce avant la charge ; il suit le héros pendant le premier.
@export var charger_telegraph_beats: int
@export var charger_track_beats: int
## Vitesse et longueur de la charge (m/s, m) ; penché en avant (rad).
@export var charger_speed: float
@export var charger_distance: float
@export var charger_lean: float
## Assommé contre un obstacle (s), et dégâts reçus pendant ce temps (multiplicateur).
@export var charger_stun_time: float
@export var charger_stunned_damage_multiplier: float
## Largeur de la ligne d'annonce (m).
@export var charger_line_width: float
## Il recule moins que les autres quand on le frappe (multiplicateur).
@export var charger_knockback_factor: float

@export_group("Porte-bouclier")
@export var shielder_scale: float
@export var shielder_health: float
@export var shielder_damage: float
@export var shielder_radius: float
@export var shielder_hop_every: int
@export var shielder_hop_distance: float
@export var shielder_hop_time: float
@export var shielder_hop_height: float
## Coup de bouclier quand le héros est à moins de cette distance (m), puis repos (temps).
@export var shielder_act_max_range: float
@export var shielder_act_cooldown: int
## Il se tourne lentement (rad/s) : on peut le prendre à revers.
@export var shielder_turn_rate: float
## Il bloque les coups venus de face, à moins de cet angle de son regard (rad) ; le bouclier se
## lève un instant (s, cases, grossissement) et le héros est repoussé (m/s).
@export var shielder_block_angle: float
@export var shielder_block_time: float
@export var shielder_raise: float
@export var shielder_raise_scale: float
@export var shielder_block_push: float
## Un plongeon passe par-dessus son bouclier et l'étourdit (s).
@export var shielder_dive_stun: float
## Coup de bouclier : temps de préparation, puis petit bond vers le héros (m, s, m) ; il touche à
## l'atterrissage à moins de cette marge (m).
@export var shielder_prepare_beats: int
@export var shielder_bash_distance: float
@export var shielder_bash_time: float
@export var shielder_bash_height: float
@export var shielder_bash_reach: float

@export_group("Cracheur")
@export var spitter_scale: float
@export var spitter_health: float
@export var spitter_damage: float
@export var spitter_radius: float
@export var spitter_hop_every: int
@export var spitter_hop_distance: float
@export var spitter_hop_time: float
@export var spitter_hop_height: float
## Il crache quand le héros est à moins de cette distance (m), puis se repose (temps).
@export var spitter_act_max_range: float
@export var spitter_act_cooldown: int
## Il se tient entre ces distances du héros (m) ; entre les deux, il tourne autour de lui en
## changeant de sens tous les quelques temps.
@export var spitter_keep_min: float
@export var spitter_keep_max: float
@export var spitter_strafe_beats: int
## Crachat : il se gonfle (part de sa taille) pendant la préparation (temps), puis lance une bulle
## de silence : vitesse (m/s), durée (s), hauteur (m), départ devant lui (m), rayon (m).
@export var spitter_inflate: float
@export var spitter_prepare_beats: int
@export var spitter_orb_speed: float
@export var spitter_orb_life: float
@export var spitter_orb_height: float
@export var spitter_orb_spawn_distance: float
@export var spitter_orb_radius: float
## La bulle tourne sur elle-même (rad/s) et ondule (rad/s, m) ; elle touche le héros de ses pieds
## (moins cette marge, m) à sa tête.
@export var orb_spin_x: float
@export var orb_spin_y: float
@export var orb_bob_speed: float
@export var orb_bob_height: float
@export var orb_hero_below: float

@export_group("Grand Muet")
@export var boss_scale: float
@export var boss_health: float
@export var boss_damage: float
@export var boss_radius: float
@export var boss_hop_every: int
@export var boss_hop_distance: float
@export var boss_hop_time: float
@export var boss_hop_height: float
## Frappe au sol quand le héros est à moins de cette distance (m), puis repos (temps ; moins en rage).
@export var boss_act_max_range: float
@export var boss_act_cooldown: int
@export var boss_act_cooldown_enraged: int
## PV et dégâts en plus par rang de sanctuaire.
@export var boss_health_per_tier: float
@export var boss_damage_per_tier: float
## Dégâts de la frappe au sol (et en plus par rang), et de l'onde (part des dégâts de contact).
@export var boss_slam_damage: float
@export var boss_slam_damage_per_tier: float
@export var boss_wave_damage_factor: float
## Temps d'annonce (cercle rouge) avant la frappe ; il gonfle pendant l'annonce (part de sa taille).
@export var boss_telegraph_beats: int
@export var boss_slam_inflate: float
## Rayon de la frappe au sol (m).
@export var boss_slam_radius: float
## Part des PV sous laquelle il enrage (phase 2).
@export var boss_phase2_fraction: float
## Onde de choc de la phase 2 : vitesse (m/s) et portée (m).
@export var boss_wave_speed: float
@export var boss_wave_range: float
## Hauteur des pieds au-dessus du sol à partir de laquelle l'onde passe sous le héros (m).
@export var boss_wave_clearance: float
## Il recule peu quand on le frappe (multiplicateur).
@export var boss_knockback_factor: float

@export_group("Nuit")
## Tambours à rapporter pour accomplir la nuit (un par sanctuaire).
@export var night_drums_required: int
## Soin au village (PV/s).
@export var village_heal_rate: float
## Rayon du village (m) : on y reprend des forces et les Muets n'y entrent pas.
@export var village_radius: float
## Marge que les Muets gardent au bord du village (m).
@export var muet_village_margin: float

@export_group("Peuplement de la nuit")
## Gardiens de chaque sanctuaire (le 2e en a un de plus, le 3e deux de plus).
@export var sanctuary_guards: int
## Distance des gardiens à l'autel (m).
@export var sanctuary_guard_min: float
@export var sanctuary_guard_max: float
## Distance du Grand Muet à l'autel, côté village (m).
@export var sanctuary_boss_distance: float
## Muets errants dans la jungle, et leur distance au village (m).
@export var muet_wanderers: int
@export var wanderer_min_distance: float
@export var wanderer_max_distance: float
## Les errants apparaissent loin des sanctuaires et du héros (m).
@export var wanderer_sanctuary_clearance: float
@export var wanderer_hero_clearance: float
## Place libre autour d'un Muet qui apparaît (m), écart d'angle au hasard (rad), essais.
@export var spawn_clearance: float
@export var spawn_angle_jitter: float
@export var spawn_tries: int

@export_group("Objets")
## Multiplicateur de valeur par rareté (commun, rare, épique, légendaire).
@export var item_rarity_multipliers: PackedFloat32Array
## Nombre d'effets par rareté.
@export var item_effects_per_rarity: PackedInt32Array
## Valeur de base de chaque effet (fractions pour les pourcentages).
@export var item_effect_bases: Dictionary[StringName, float]
## Bonus de valeur par niveau d'objet (fraction).
@export var item_level_bonus: float
## Tirage de la valeur d'un effet (fractions).
@export var item_roll_min: float
@export var item_roll_max: float
## Bonus par niveau de forge (fraction).
@export var item_forge_bonus: float
## Chances de rareté du butin du Grand Muet et des coffres (commun, rare, épique, légendaire).
@export var loot_guaranteed_weights: PackedFloat32Array

@export_group("Interface")
## Durée d'un message éphémère (s) et de ses fondus (s).
@export var message_time: float
@export var message_fade_time: float
## Durée d'une réplique près de sa source (s) et écart au-dessus de sa tête (m).
@export var reply_time: float
@export var reply_gap: float
## Durée de la réplique du Chef au début de la nuit (s).
@export var chief_line_time: float
## Grands titres : apparition, maintien, disparition (s).
@export var title_fade_in_time: float
@export var title_hold_time: float
@export var title_fade_out_time: float
## Durée de la carte d'un objet trouvé (s).
@export var loot_card_time: float
## Battement du halo d'une aide (s par cycle).
@export var hint_pulse_period: float
## Vitesse au-delà de laquelle l'aide « courir » est suivie (m/s).
@export var hint_move_speed: float
## Chiffres de dégâts : durée (s) et montée (m).
@export var damage_number_time: float
@export var damage_number_rise: float
## Barre de PV : vitesse de rattrapage de l'affichage (1/s) ; seuil de PV bas (fraction).
@export var health_bar_follow_rate: float
@export var health_low_fraction: float
## Attente entre « Nuit accomplie » et l'écran de fin (s).
@export var end_screen_delay: float

@export_group("Finition")
## Vitesse de chute à partir de laquelle l'atterrissage s'entend (m/s).
@export var land_sound_speed: float

@export_group("Monde voxel")
## Mètres par unité du prototype (le héros y mesure 7 u pour 1,8 m).
@export var voxel_unit: float
## Côté d'un cube, en fraction de la case (un petit jour entre les cubes).
@export var voxel_cube_fraction: float
## Côté des cases de regroupement des cubes (m) : la caméra n'en voit que quelques-unes.
@export var world_chunk_size: float
## Hauteur des collisions des obstacles infranchissables (m).
@export var world_wall_height: float
## Épaisseur et nombre des murs invisibles au bord du monde.
@export var world_border_thickness: float
@export var world_border_segments: int
## Côté du sol (m).
@export var world_ground_size: float
## Saturation du monde selon le nombre de tambours rapportés (0, 1, 2, 3), et nuit gagnée.
@export var world_saturation_levels: PackedFloat32Array
@export var world_saturation_won: float
## Vitesse de retour de la saturation (1/s) ; plus vive pendant un éclat (Salto arc-en-ciel).
@export var world_saturation_rate: float
@export var world_saturation_pulse_rate: float
## Retombée de l'éclat de couleurs (saturation par seconde).
@export var world_saturation_pulse_decay: float
## Vitesse à laquelle un sanctuaire libéré reprend ses couleurs (1/s).
@export var world_freed_rate: float
## Le monde s'anime plus vite quand la nuit est gagnée.
@export var world_time_speed_won: float
## Éclat du décor sur le temps : décroissance après chaque temps.
@export var world_beat_decay: float
## Brouillard : densité (1/m), vitesse de rotation de sa teinte (tours/s), saturation, luminosité.
@export var fog_density: float
@export var fog_hue_speed: float
@export var fog_saturation: float
@export var fog_lightness: float
## Hauteur au-dessus des pieds du héros du point qu'on garde visible à travers le décor (m).
@export var cutaway_height: float
## Hauteur des ombres rondes au-dessus du sol (m) et nombre de côtés du disque.
@export var shadow_height: float
@export var shadow_segments: int
## L'ombre d'un personnage cherche le sol sous lui : départ au-dessus de ses pieds, portée (m).
@export var shadow_ray_start: float
@export var shadow_ray_length: float
## Elle rapetisse quand il s'élève : hauteur (m) à laquelle elle a perdu sa part maximale.
@export var shadow_shrink_height: float
@export var shadow_shrink_max: float
## Épaisseur de la zone de rebond sur un champignon-trampoline (m).
@export var bounce_pad_thickness: float

@export_group("Personnages voxel")
## Côté d'un voxel des personnages (unités du prototype) : 20,6 voxels font les 7 u du héros.
@export var character_voxel: float
## Marge ajoutée à la boîte d'un assemblage articulé pour qu'il ne disparaisse pas en bougeant (m).
@export var voxel_rig_cull_margin: float
## Clignement des yeux : intervalle au hasard (s), durée (s), yeux écrasés à cette hauteur.
@export var blink_min: float
@export var blink_max: float
@export var blink_time: float
@export var blink_squash: float
## Taille du Chef par rapport aux villageois, et sa hauteur (m) : ses répliques s'affichent au-dessus.
@export var chief_scale: float
@export var chief_height: float
## Rayons des ombres rondes (m) : villageois, Chef, héros.
@export var villager_shadow_radius: float
@export var chief_shadow_radius: float
@export var hero_shadow_radius: float
## Entrain de la danse : de base, par tambour rapporté, nuit gagnée ; le Chef danse plus sobrement.
@export var villager_dance_base: float
@export var villager_dance_per_drum: float
@export var villager_dance_won: float
@export var chief_dance_factor: float
## Balancement de gauche à droite (rad, à plein entrain).
@export var villager_sway: float
## Vitesse à laquelle la pose rejoint la pose visée (1/s).
@export var villager_pose_rate: float
## Décalage de la danse d'un villageois au suivant, et du Chef (temps de musique).
@export var villager_phase_step: float
@export var chief_phase: float
## Saltos de fête : durée (s), hauteur (m), premier salto (s, puis un peu plus tard pour chacun),
## intervalle au hasard entre deux saltos (s).
@export var villager_flip_time: float
@export var villager_flip_height: float
@export var villager_first_flip: float
@export var villager_first_flip_step: float
@export var villager_flip_gap_min: float
@export var villager_flip_gap_max: float

@export_group("Effets")
## Petits cubes : nombre en réserve ; boîte d'affichage (m, autour du niveau).
@export var fx_cube_count: int
@export var fx_cull_margin: float
## Vitesse de départ au hasard, en part de la vitesse demandée (plus bas).
@export var fx_speed_min: float
## Vie (s), élan vers le haut (m/s), taille (m), gravité (m/s²) des cubes d'éclat et de la poussière.
@export var fx_cube_life_min: float
@export var fx_cube_life_max: float
@export var fx_cube_rise_min: float
@export var fx_cube_rise_max: float
@export var fx_cube_size_min: float
@export var fx_cube_size_max: float
@export var fx_cube_gravity: float
@export var fx_dust_life_min: float
@export var fx_dust_life_max: float
@export var fx_dust_rise_min: float
@export var fx_dust_rise_max: float
@export var fx_dust_size_min: float
@export var fx_dust_size_max: float
@export var fx_dust_gravity: float
## Poussière : dispersion au départ et hauteur au-dessus du sol (m).
@export var fx_dust_spread: float
@export var fx_dust_lift: float
## Sol où les cubes rebondissent : au moins cette hauteur, sinon sous leur départ (m) ; rebond,
## frottement.
@export var fx_floor_min: float
@export var fx_cube_floor_drop: float
@export var fx_dust_floor_drop: float
@export var fx_bounce: float
@export var fx_bounce_friction: float
## Variation de teinte autour de la teinte demandée ; rotation (rad/s, et rapport entre les axes) ;
## les cubes rapetissent sur la fin de leur vie (plus la valeur est grande, plus c'est tard).
@export var fx_hue_jitter: float
@export var fx_cube_spin: float
@export var fx_cube_spin_ratio: float
@export var fx_shrink: float
## Anneaux : hauteur (m), taille de départ (part du rayon), bord intérieur (part du rayon),
## segments, tours de couleur de l'anneau arc-en-ciel.
@export var fx_ring_lift: float
@export var fx_ring_start: float
@export var fx_ring_inner: float
@export var fx_ring_segments: int
@export var fx_rainbow_turns: float
## Étincelles : durée (s), taille de départ (part), texture (px), éclat du dégradé.
@export var fx_spark_time: float
@export var fx_spark_start: float
@export var fx_spark_texture_size: int
@export var fx_spark_glow: float
## Étincelle d'un coup, d'un coup critique (m).
@export var fx_spark_size: float
@export var fx_spark_size_crit: float
## Mots qui montent : durée (s), montée (m), début de l'effacement (part), jaillissement (durée en
## part, taille de départ, taille au plus fort), affichage (priorité, police, contour, taille d'un
## pixel en m, couleur du contour).
@export var fx_word_time: float
@export var fx_word_rise: float
@export var fx_word_fade_start: float
@export var fx_word_pop_time: float
@export var fx_word_pop_start: float
@export var fx_word_pop_peak: float
@export var fx_word_priority: int
@export var fx_word_font_size: int
@export var fx_word_font_size_big: int
@export var fx_word_outline: int
@export var fx_word_pixel_size: float
@export var fx_word_outline_color: Color
## Teintes des éclats : or, rouge, étourdi.
@export var fx_gold_hue: float
@export var fx_red_hue: float
@export var fx_stun_hue: float
## Muet libéré : hauteur de la gerbe (part de sa taille), cubes et vitesse (m/s ; Grand Muet),
## cubes dorés, anneau (m ; Grand Muet) et sa durée (s).
@export var fx_freed_burst_height: float
@export var fx_freed_cubes: int
@export var fx_freed_boss_cubes: int
@export var fx_freed_speed: float
@export var fx_freed_boss_speed: float
@export var fx_freed_gold_cubes: int
@export var fx_freed_gold_speed: float
@export var fx_freed_ring: float
@export var fx_freed_boss_ring: float
@export var fx_freed_ring_time: float
## Frappe du Grand Muet : anneau plus large que le cercle (m), durée (s), gerbe (hauteur m, cubes, m/s).
@export var fx_slam_ring_extra: float
@export var fx_slam_ring_time: float
@export var fx_slam_burst_height: float
@export var fx_slam_cubes: int
@export var fx_slam_speed: float
## Coup bloqué, cornu assommé, bulle éclatée : cubes et vitesse (m/s).
@export var fx_block_cubes: int
@export var fx_block_speed: float
@export var fx_stun_cubes: int
@export var fx_stun_speed: float
@export var fx_orb_cubes: int
@export var fx_orb_speed: float
## Héros : poussière du saut ; anneau (m, s) et cubes (nombre, m/s, hauteur m) du double saut.
@export var fx_jump_dust: int
@export var fx_jump_dust_speed: float
@export var fx_double_ring: float
@export var fx_double_ring_time: float
@export var fx_double_cubes: int
@export var fx_double_speed: float
@export var fx_double_height: float
## Atterrissage : à partir de cette chute (m), poussière (au moins, par mètre de chute, au plus ; m/s).
@export var fx_land_min_fall: float
@export var fx_land_dust_min: int
@export var fx_land_dust_per_meter: float
@export var fx_land_dust_max: int
@export var fx_land_dust_speed: float
## Plongeon : poussière (nombre, m/s), durée de l'anneau (s) ; Salto arc-en-ciel : gerbe (cubes,
## m/s), anneau (m, s).
@export var fx_dive_dust: int
@export var fx_dive_dust_speed: float
@export var fx_dive_ring_time: float
@export var fx_rainbow_cubes: int
@export var fx_rainbow_speed: float
@export var fx_rainbow_ring: float
@export var fx_rainbow_ring_time: float
## Esquive parfaite : anneau (m, s).
@export var fx_dodge_ring: float
@export var fx_dodge_ring_time: float
## Rebond sur un champignon : anneau (m, s).
@export var fx_bounce_ring: float
@export var fx_bounce_ring_time: float
## Tambours : gerbe quand on le prend (cubes, m/s, hauteur m), quand on le rapporte (cubes, m/s,
## anneau m, s) ; nuit accomplie (cubes, m/s, hauteur m, anneau m, s).
@export var fx_drum_pick_cubes: int
@export var fx_drum_pick_speed: float
@export var fx_drum_pick_height: float
@export var fx_drum_return_cubes: int
@export var fx_drum_return_speed: float
@export var fx_drum_return_ring: float
@export var fx_drum_return_ring_time: float
@export var fx_night_cubes: int
@export var fx_night_speed: float
@export var fx_night_height: float
@export var fx_night_ring: float
@export var fx_night_ring_time: float
