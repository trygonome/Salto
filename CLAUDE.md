# Salto — consignes pour Claude Code

## Le projet
Jeu d'action acrobatique et rythmique en 3D, fait avec **Godot 4** (GDScript).
Cible : Android d'abord (portrait et paysage), web ensuite.
Tout le contexte est dans `docs/` :
- `docs/GDD.md` : conception, direction artistique, charte des retours à l'écran, textes
- `docs/REGLAGES.md` : valeurs chiffrées validées dans le prototype
- `docs/PLAN.md` : architecture et jalons de la tranche verticale

## Règles de travail
- Priorité absolue : la **tranche verticale** décrite dans `docs/PLAN.md`, jalon par jalon.
  Aucune fonctionnalité hors plan sans me demander.
- Chaque jalon se termine **jouable** : dis-moi exactement quoi tester sur mon téléphone.
- **Aucun nombre magique** dans les scripts : toutes les valeurs de réglage vivent dans
  `res://data/tuning.tres` (ressource `Tuning`), en mètres et en secondes.
- GDScript **typé statiquement**. Noms de code en anglais ; textes du jeu et commentaires en français.
- Composition plutôt qu'héritage : composants `Hitbox`, `Hurtbox`, `Health`, `StateMachine`.
- Interface : respecter la **charte des retours à l'écran** (`docs/GDD.md`, section 12).
  Le monde parle avant le texte ; au plus un message éphémère à la fois ; jamais au centre de l'action.
- Direction artistique : n'utiliser que les packs d'assets choisis ; noter chaque licence dans
  `assets/LICENCES.md` ; vérifier les échelles contre le personnage (1,8 m).
- Performance : viser 60 images/s sur un Android de milieu de gamme (renderer **Mobile** ;
  **Compatibility** pour l'export web).
- Tests : la logique pure (fenêtres de rythme, dégâts, combos, progression) est testée ;
  lancer les tests avant chaque commit.
- Git : petits commits clairs, en français.

## Commandes
À compléter au jalon 0 (lancer le jeu, lancer les tests, exporter l'APK Android).

## Structure
```
res://
  scenes/   player/  enemies/  levels/  ui/  fx/
  scripts/  autoload/ (Tuning, Rhythm, Game, Save)  components/
  data/     tuning.tres  items/  talents/
  assets/   models/  animations/  audio/  fonts/  LICENCES.md
  tests/
docs/
```
