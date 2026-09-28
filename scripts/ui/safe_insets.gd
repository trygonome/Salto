class_name SafeInsets
## Marges de la zone sûre de l'écran (encoches, bords arrondis), en px du canevas : gauche, haut,
## droite, bas. Zéro hors téléphone. En paysage, l'encoche est sur un côté : les commandes tactiles
## s'en écartent.


static func of(viewport: Viewport) -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var window: Vector2 = Vector2(DisplayServer.window_get_size())
	if window.x <= 0.0 or window.y <= 0.0:
		return Vector4.ZERO
	var safe: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	var scale: Vector2 = viewport.get_visible_rect().size / window
	return Vector4(safe.position.x * scale.x, safe.position.y * scale.y, (window.x - safe.end.x) * scale.x, (window.y - safe.end.y) * scale.y)
