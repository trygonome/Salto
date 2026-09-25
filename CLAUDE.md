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
Godot **4.7.2**. Les scripts de `tools/` tournent sous Linux (sessions cloud, CI) et téléchargent au besoin
Godot, les modèles d'export et le SDK Android dans `~/.cache/salto-tools` (dossier réglable par `SALTO_TOOLS_DIR`).
- **Lancer le jeu** : ouvrir le projet dans Godot 4.7 puis F5, ou `godot --path .`
  (la fenêtre de test est en portrait ; la redimensionner en paysage pour tester l'autre cadrage).
  La scène principale est la nuit 1 (`scenes/levels/night_1.tscn`) ; le parcours d'essai
  (`scenes/levels/test_course.tscn`) se lance depuis l'éditeur (F6).
- **Lancer les tests** : `tools/test.sh` — addon **GUT 9.7.1** (`addons/gut`), fichiers `tests/test_*.gd`,
  sans fenêtre ; code de sortie non nul si un test échoue.
- **Exporter l'APK de test** : `tools/export_android.sh` → `build/android/salto-debug.apk`.
  Signée avec `tools/android/debug.keystore` (alias `androiddebugkey`, mot de passe `android`) :
  toutes les APK de test ont la même signature et s'installent par-dessus la précédente.
  Depuis l'éditeur sur PC, régler *Paramètres de l'éditeur > Export > Android > Debug Keystore* sur ce fichier
  pour garder la même signature.
- **Régénérer la musique et les bruitages** : `python3 tools/audio/generate_audio.py` (demande `numpy`) —
  musique de la nuit en 4 couches à 104 BPM et sons d'impact, entièrement synthétisés.

## Structure
```
res://
  scenes/   player/  enemies/  levels/  ui/  fx/
  scripts/  autoload/ (Tuning, Feedback, Rhythm, Game, Save)  components/  player/  combat/  enemies/
            camera/  fx/  ui/  utils/  night/  items/  levels/ (props/)  tuning_data.gd
  data/     tuning.tres  notebook.tres  items/  talents/
  assets/   models/  animations/  audio/  fonts/  fx/  ui/  LICENCES.md
  addons/   gut/ (tests, exclu de l'export)
  tests/
docs/
tools/      tests, export Android, keystore de debug (ignoré par Godot)
```
