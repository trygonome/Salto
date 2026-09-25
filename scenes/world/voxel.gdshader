shader_type spatial;
// Matériau voxel du prototype. Chaque cube porte dans INSTANCE_CUSTOM sa couleur codée
// (mode + teinte, saturation, luminosité). Modes : 0 monde (teinte qui ondule, bue par le silence,
// pulse au temps) · 1 vif (ondule) · 2 fixe · 3 arc-en-ciel · 4 teinte fixe bue par le silence.
render_mode unshaded, cull_back;

#include "res://scenes/world/salto_world.gdshaderinc"

// Décor statique : devient pointillé entre la caméra et le héros pour qu'on le voie toujours.
uniform bool cutaway = false;

varying vec3 v_color;
varying vec3 v_world;
varying vec3 v_normal;

void vertex() {
	v_color = INSTANCE_CUSTOM.rgb;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 w = v_world / salto_unit;
	if (cutaway && salto_cut > 0.5) {
		vec3 cam = CAMERA_POSITION_WORLD / salto_unit;
		vec3 pl = salto_player / salto_unit;
		vec2 to_cam = normalize(cam.xz - pl.xz);
		float fwd = dot(w.xz - pl.xz, to_cam);
		vec3 ab = pl - cam;
		float t = clamp(dot(w - cam, ab) / dot(ab, ab), 0.0, 1.0);
		float dd = length(w - (cam + ab * t));
		float k = smoothstep(1.0, 4.0, fwd) * smoothstep(1.2, 2.6, w.y)
			* mix(0.8, 1.01, 1.0 - smoothstep(1.5 + 3.0 * t, 3.0 + 6.0 * t, dd));
		vec2 q = mod(floor(FRAGCOORD.xy), 2.0);
		float idx = q.x + 2.0 * q.y;
		float th = idx < 0.5 ? 0.125 : (idx < 1.5 ? 0.625 : (idx < 2.5 ? 0.875 : 0.375));
		if (k > th) {
			discard;
		}
	}
	float mode = floor(v_color.x + 0.001);
	float h = v_color.x - mode;
	float s = v_color.y;
	float l = v_color.z;
	float wob = sin(w.x * 0.05 + w.z * 0.07 + salto_time * 0.35) * 0.07;
	float zone = salto_zone(w.xz);
	if (mode < 0.5) {
		h = fract(h + salto_time * 0.04 + wob);
		s *= zone * salto_sat;
		l += salto_beat * 0.06 * salto_sat;
	} else if (mode < 1.5) {
		h = fract(h + salto_time * 0.04 + wob);
		s *= zone;
	} else if (mode < 2.5) {
	} else if (mode < 3.5) {
		h = fract(h + salto_time * 0.1 + w.y * 0.03);
	} else {
		s *= zone * salto_sat;
	}
	vec3 c = salto_hsl2rgb(vec3(h, clamp(s, 0.0, 1.0), clamp(l, 0.0, 1.0)));
	vec3 n = normalize(v_normal);
	float d = max(dot(n, normalize(vec3(0.35, 1.0, 0.55))), 0.0);
	c = c * (0.66 + 0.52 * d) + vec3(0.035, 0.02, 0.06);
	float rim = pow(1.0 - max(dot(n, normalize(CAMERA_POSITION_WORLD - v_world)), 0.0), 3.0);
	c += rim * vec3(0.16, 0.13, 0.2);
	c *= mix(0.72, 1.0, smoothstep(0.0, 1.3, w.y));
	ALBEDO = salto_output(salto_fog(c, -VERTEX.z));
}
