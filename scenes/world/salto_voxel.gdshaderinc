// Couleur d'un cube voxel du prototype, avant brouillard. `data` : couleur codée (mode + teinte,
// saturation, luminosité). Modes : 0 monde (teinte qui ondule, bue par le silence, pulse au temps)
// · 1 vif (ondule) · 2 fixe · 3 arc-en-ciel · 4 teinte fixe bue par le silence.
// `vivid` (0 à 1) ravive la couleur (Muet libéré). Positions en mètres.
vec3 salto_voxel_color(vec3 data, vec3 world, vec3 normal, vec3 camera, float vivid) {
	vec3 w = world / salto_unit;
	float mode = floor(data.x + 0.001);
	float h = data.x - mode;
	float s = data.y;
	float l = data.z;
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
	h = fract(h + vivid * (salto_time * 0.5 + w.y * 0.1));
	s = mix(s, 1.0, vivid);
	l = mix(l, clamp(l, 0.45, 0.7), vivid);
	vec3 c = salto_hsl2rgb(vec3(h, clamp(s, 0.0, 1.0), clamp(l, 0.0, 1.0)));
	vec3 n = normalize(normal);
	float d = max(dot(n, normalize(vec3(0.35, 1.0, 0.55))), 0.0);
	c = c * (0.66 + 0.52 * d) + vec3(0.035, 0.02, 0.06);
	float rim = pow(1.0 - max(dot(n, normalize(camera - world)), 0.0), 3.0);
	c += rim * vec3(0.16, 0.13, 0.2);
	c *= mix(0.72, 1.0, smoothstep(0.0, 1.3, w.y));
	return c;
}
