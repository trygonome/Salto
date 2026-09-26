// Couleur d'un cube voxel du prototype, avant brouillard. `data` : couleur codée (mode + teinte,
// saturation, luminosité). Modes : 0 monde (teinte qui ondule avec la vie de la jungle, bue par le
// silence, pulse au temps) · 1 vif (fleurs : ondule, s'éteint avec le monde) · 2 fixe ·
// 3 arc-en-ciel · 4 teinte fixe bue par le silence. Les teintes ondulent autour de leur valeur sans
// jamais dériver. Dans le cercle du groove, autour du héros, le monde retrouve ses couleurs.
// `vivid` (0 à 1) ravive la couleur en arc-en-ciel (Muet qu'on libère) ; `healed` (0 à 1) rend
// ses couleurs à un Muet libéré qui danse au village (sa teinte, plus vive). Positions en mètres.
vec3 salto_voxel_color(vec3 data, vec3 world, vec3 normal, vec3 camera, float vivid, float healed) {
	vec3 w = world / salto_unit;
	float mode = floor(data.x + 0.001);
	float h = data.x - mode;
	float s = data.y;
	float l = data.z;
	float halo = salto_halo(world);
	float wob = sin(w.x * 0.05 + w.z * 0.07 + salto_time * 0.35) * 0.07 * salto_life;
	float zone = salto_zone(w.xz);
	float sat = mix(zone * salto_sat, max(zone * salto_sat, SALTO_HALO_SAT), halo);
	if (mode < 0.5) {
		h = fract(h + wob);
		s *= sat;
		l += salto_beat * 0.06 * max(salto_sat, halo * SALTO_HALO_SAT);
	} else if (mode < 1.5) {
		h = fract(h + wob);
		s *= sat;
	} else if (mode < 2.5) {
	} else if (mode < 3.5) {
		h = fract(h + salto_time * 0.1 + w.y * 0.03);
	} else {
		s *= sat;
	}
	s = min(1.0, s * (1.0 + 0.8 * healed));
	l = mix(l, l + (1.0 - l) * 0.2, healed);
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
