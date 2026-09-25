shader_type spatial;
// Sol du monde voxel (prototype) : dalles de 2 u dont la teinte ondule, place du village et
// chemins dorés vers les sanctuaires, autels violets, bande dorée qui défile vers l'objectif.
render_mode unshaded;

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

void fragment() {
	vec2 p = v_world.xz / salto_unit;
	vec2 t = floor(p / 2.0);
	vec2 f = fract(p / 2.0);
	float e = min(min(f.x, f.y), min(1.0 - f.x, 1.0 - f.y));
	float r = length(p);
	float n = fract(sin(dot(t, vec2(12.9898, 78.233))) * 43758.5453);
	float h = fract(0.33 + n * 0.08 + salto_time * 0.03 + sin(length(t) * 0.22 - salto_time * 0.9) * 0.12);
	float s = 0.72;
	float l = 0.32 + n * 0.08;
	vec2 s0 = salto_sanctuary_0.xy;
	vec2 s1 = salto_sanctuary_1.xy;
	vec2 s2 = salto_sanctuary_2.xy;
	float pd = min(seg(p, vec2(0.0), s0), min(seg(p, vec2(0.0), s1), seg(p, vec2(0.0), s2)));
	float way = max(1.0 - smoothstep(13.5, 15.0, r), 1.0 - smoothstep(2.2, 3.0, pd));
	if (way > 0.5) {
		h = fract(0.1 + sin(salto_time * 0.25 + r * 0.05) * 0.06);
		s = 0.6;
		l = 0.44 + n * 0.06;
	}
	if (length(p - s0) < 9.0 || length(p - s1) < 9.0 || length(p - s2) < 9.0) {
		h = fract(0.78 + salto_time * 0.05);
		s = 0.5;
		l = 0.36 + n * 0.05;
	}
	s *= salto_sat * salto_zone(p);
	l += salto_beat * 0.05 * salto_sat;
	l *= mix(0.62, 1.0, smoothstep(0.02, 0.07, e));
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
