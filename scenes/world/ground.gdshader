shader_type spatial;
// Sol du monde voxel (prototype) : place du village et chemins dorés vers les sanctuaires, autels
// violets, bande dorée qui défile vers l'objectif. Dans le cercle du groove, autour du héros, le sol
// retrouve ses couleurs. Version 2.5 : plus de quadrillage uni ; de grandes plaques d'herbe plus
// claires ou plus sombres, des taches de terre, et chaque petit carré (1 u) un rien différent.
render_mode unshaded;

// Herbe (teinte, saturation, luminosité) : chaque région a la sienne (version 2.6).
uniform vec3 grass_hsl = vec3(0.31, 0.7, 0.27);
// Taches de terre (part du sol) et leur couleur (teinte, saturation, luminosité).
uniform float dirt_amount = 0.2;
uniform vec3 dirt_color = vec3(0.08, 0.42, 0.3);

#include "res://scenes/world/salto_world.gdshaderinc"

varying vec3 v_world;

float seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float k = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * k);
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Bruit de valeur lissé (0 à 1).
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 p = v_world.xz / salto_unit;
	vec2 t = floor(p / 2.0);
	float r = length(p);
	float n = hash21(floor(p));
	float big = value_noise(p * 0.045);
	float mid = value_noise(p * 0.16 + vec2(17.0, 3.0));
	float halo = salto_halo(v_world);
	float h = fract(grass_hsl.x + big * 0.07 - mid * 0.03 + n * 0.02 + sin(length(t) * 0.22 - salto_time * 0.9) * 0.12 * salto_life);
	float s = grass_hsl.y - mid * 0.1;
	float l = grass_hsl.z + big * 0.1 + mid * 0.03 + n * 0.035;
	float dirt = smoothstep(1.0 - dirt_amount, 1.07 - dirt_amount, value_noise(p * 0.07 + vec2(40.0, 11.0)) * 0.7 + mid * 0.3) * (1.0 - salto_village);
	h = mix(h, dirt_color.x, dirt);
	s = mix(s, dirt_color.y, dirt);
	l = mix(l, dirt_color.z + n * 0.03, dirt);
	vec2 s0 = salto_sanctuary_0.xy;
	vec2 s1 = salto_sanctuary_1.xy;
	vec2 s2 = salto_sanctuary_2.xy;
	float pd = min(seg(p, vec2(0.0), s0), min(seg(p, vec2(0.0), s1), seg(p, vec2(0.0), s2)));
	float way = max(1.0 - smoothstep(13.5, 15.0, r), 1.0 - smoothstep(2.2, 3.0, pd)) * salto_village;
	if (way > 0.5) {
		h = fract(0.1 + sin(salto_time * 0.25 + r * 0.05) * 0.06 * salto_life);
		s = 0.6;
		l = 0.44 + n * 0.06;
	}
	if (length(p - s0) < 9.0 || length(p - s1) < 9.0 || length(p - s2) < 9.0) {
		h = fract(0.78 + sin(salto_time * 0.4) * 0.03 * salto_life);
		s = 0.5;
		l = 0.36 + n * 0.05;
	}
	float sat = salto_sat * salto_zone(p);
	s *= mix(sat, max(sat, SALTO_HALO_SAT), halo);
	l += salto_beat * 0.05 * max(salto_sat, halo * SALTO_HALO_SAT);
	l *= 1.0 - smoothstep(80.0, 96.0, r) * 0.45;
	vec3 c = salto_hsl2rgb(vec3(h, s, l));
	if (salto_target.z > 0.5) {
		vec2 ba = salto_target.xy;
		float len = max(length(ba), 1.0);
		float k = clamp(dot(p, ba) / (len * len), 0.0, 1.0);
		float ds = length(p - ba * k);
		float band = (1.0 - smoothstep(1.3, 2.7, ds)) * smoothstep(0.03, 0.14, k) * (1.0 - smoothstep(0.88, 1.0, k));
		float ph = fract(k * len / 3.2 - salto_time * 1.3 * salto_target.w);
		float st = smoothstep(0.0, 0.12, ph) * (1.0 - smoothstep(0.38, 0.55, ph));
		c = mix(c, vec3(1.0, 0.86, 0.35), band * (0.22 + 0.62 * st));
	}
	ALBEDO = salto_output(salto_fog(c, -VERTEX.z));
}
