shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, shadows_disabled;
// Barre d'équilibre au-dessus d'un Muet : toujours face à la caméra, blanche qui se vide, dorée
// qui clignote quand l'équilibre est brisé.

uniform float ratio = 1.0;
uniform float broken = 0.0;
uniform vec4 fill_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 broken_color : source_color = vec4(1.0, 0.82, 0.25, 1.0);
uniform vec4 back_color : source_color = vec4(0.08, 0.04, 0.12, 0.75);
// Clignotement quand il chancelle (par seconde).
uniform float blink_rate = 8.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec4 fill = mix(fill_color, broken_color, broken);
	float blink = broken > 0.5 ? 0.6 + 0.4 * sin(TIME * blink_rate * 6.2831) : 1.0;
	vec4 color = UV.x <= ratio ? vec4(fill.rgb * blink, fill.a) : back_color;
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
