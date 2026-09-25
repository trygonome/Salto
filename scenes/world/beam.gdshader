shader_type spatial;
// Colonne de lumière dorée sur l'objectif (comme dans le prototype) : s'efface vers le haut,
// parcourue de bandes qui montent.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec3 color : source_color = vec3(1.0, 0.82, 0.3);
// Opacité, courbe d'effacement, nombre de bandes, vitesse des bandes, part des bandes.
uniform float strength = 0.6;
uniform float fade_power = 1.4;
uniform float stripes = 38.0;
uniform float stripe_speed = 7.0;
uniform float stripe_depth = 0.4;

void fragment() {
	float up = 1.0 - UV.y;
	float a = pow(1.0 - up, fade_power) * (1.0 - stripe_depth + stripe_depth * sin(up * stripes - TIME * stripe_speed)) * strength;
	ALBEDO = color * a;
	ALPHA = a;
}
