shader_type spatial;
// Eau des mares (version 2.5) : un disque d'eau sarcelle qui ondule en cercles, un reflet qui
// palpite au temps de la musique, un liseré clair au bord ; bue par le silence comme le reste.
render_mode unshaded, blend_mix, depth_draw_opaque, cull_back;

#include "res://scenes/world/salto_world.gdshaderinc"

// Teinte, saturation et luminosité de l'eau ; couleur du bord.
uniform vec3 water_hsl = vec3(0.5, 0.65, 0.34);
uniform vec3 edge_hsl = vec3(0.47, 0.35, 0.72);
// Ondes : nombre de cercles par mètre, vitesse.
uniform float ripple_density = 5.0;
uniform float ripple_speed = 1.4;
// Mare ronde (un disque) ; sinon rivière (tout le rectangle, ondes en travers).
uniform bool round = true;

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = round ? length(uv) : abs(uv.y) * 0.9 + sin(v_world.x * 1.7 + salto_time * 0.8) * 0.03;
	if (r > 1.0) {
		discard;
	}
	float halo = salto_halo(v_world);
	float sat = mix(salto_sat, max(salto_sat, SALTO_HALO_SAT), halo);
	float wave = round ? r * ripple_density * 3.0 : v_world.x * ripple_density * 1.5;
	float ripple = sin(wave - salto_time * ripple_speed * 3.0) * 0.5 + 0.5;
	vec3 hsl = water_hsl;
	hsl.y *= sat;
	hsl.z += ripple * 0.05 + salto_beat * 0.06 * max(salto_sat, halo);
	vec3 c = salto_hsl2rgb(hsl);
	vec3 edge = salto_hsl2rgb(vec3(edge_hsl.x, edge_hsl.y * sat, edge_hsl.z));
	c = mix(c, edge, smoothstep(0.86, 0.97, r));
	ALBEDO = salto_output(salto_fog(c, -VERTEX.z));
	ALPHA = 0.92;
}
