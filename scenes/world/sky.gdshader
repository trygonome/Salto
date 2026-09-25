shader_type sky;
// Ciel du prototype : bandes de couleurs qui tournent, ternies par le silence, fondues dans le
// brouillard vers l'horizon.

#include "res://scenes/world/salto_world.gdshaderinc"

void sky() {
	vec3 d = normalize(EYEDIR);
	float a = atan(d.z, d.x);
	float r = acos(clamp(d.y, -1.0, 1.0));
	float s = sin(a * 6.0 + salto_time * 0.7 + sin(r * 9.0 - salto_time) * 2.0) + sin(r * 16.0 - salto_time * 1.3) + 0.5 * sin(a * 14.0 - salto_time * 2.0);
	float h = fract(s * 0.12 + salto_time * 0.05 + r * 0.35);
	vec3 c = salto_hsl2rgb(vec3(h, 0.85, 0.42 + 0.13 * sin(s * 3.0)));
	float g = dot(c, vec3(0.333));
	c = mix(vec3(g), c, clamp(salto_sat, 0.35, 1.0));
	c = mix(c, salto_fog_color.rgb, (1.0 - smoothstep(-0.05, 0.35, d.y)) * 0.85);
	COLOR = salto_output(c);
}
