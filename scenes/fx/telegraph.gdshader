shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
// Annonce d'une attaque au sol : un bord net et un remplissage qui avance jusqu'à l'attaque.
// Cercle : le remplissage part du centre. Ligne : il part du début (UV.x = 0).

uniform vec4 color : source_color = vec4(1.0, 0.2, 0.2, 0.8);
uniform float progress = 0.0;
uniform bool is_line = false;
uniform float rim_width = 0.08;
uniform float fill_opacity = 0.45;

void fragment() {
	float rim;
	float filled;
	if (is_line) {
		float across = abs(UV.y * 2.0 - 1.0);
		float along = UV.x;
		rim = max(smoothstep(1.0 - rim_width * 2.0, 1.0, across), step(1.0 - rim_width * 0.5, along));
		filled = step(along, progress);
	} else {
		float r = length(UV * 2.0 - 1.0);
		if (r > 1.0) {
			discard;
		}
		rim = smoothstep(1.0 - rim_width, 1.0, r);
		filled = step(r, progress);
	}
	ALBEDO = color.rgb;
	ALPHA = color.a * max(rim, filled * fill_opacity);
}
