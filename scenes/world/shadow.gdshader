// Ombres rondes du prototype : disque sombre et transparent posé sur le sol, pris dans le
// brouillard. Opacité : celle du matériau, multipliée par la couleur de l'instance (ombres du décor).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

#include "res://scenes/world/salto_world.gdshaderinc"

// Couleur de l'ombre en valeurs d'écran (sRGB) et opacité.
uniform vec3 shadow_color = vec3(0.078, 0.016, 0.122);
uniform float opacity = 1.0;

void fragment() {
	ALBEDO = salto_output(salto_fog(shadow_color, -VERTEX.z));
	ALPHA = opacity * COLOR.a;
}
