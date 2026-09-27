shader_type canvas_item;
// Fond des écrans : le jeu derrière, flou et teinté, bords assombris.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec4 tint : source_color;
uniform vec4 edge : source_color;
// Niveau de flou (niveau de détail de la texture de l'écran).
uniform float blur = 3.0;

void fragment() {
	vec3 behind = textureLod(screen_texture, SCREEN_UV, blur).rgb;
	vec3 color = mix(behind, tint.rgb, tint.a);
	float d = length(UV - vec2(0.5)) * 1.4142;
	color = mix(color, edge.rgb, smoothstep(0.45, 1.0, d) * edge.a);
	COLOR = vec4(color, 1.0);
}
