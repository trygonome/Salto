shader_type spatial;
// Sol de la jungle la nuit : deux teintes d'herbe mêlées par un bruit doux sur le dessus,
// de la roche sur les parois, qui s'assombrit en profondeur (ravin).

uniform vec3 grass_dark : source_color = vec3(0.1, 0.22, 0.15);
uniform vec3 grass_light : source_color = vec3(0.15, 0.3, 0.18);
uniform vec3 rock_color : source_color = vec3(0.24, 0.22, 0.3);
uniform float patch_size = 3.5;
// Pente à partir de laquelle la roche remplace l'herbe (composante verticale de la normale).
uniform float rock_slope_start = 0.5;
uniform float rock_slope_end = 0.8;
// Profondeur (m) à laquelle la paroi du ravin devient noire.
uniform float dark_depth = 9.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec3 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 world_normal = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	float n = noise(world.xz / patch_size) * 0.7 + noise(world.xz / (patch_size * 0.3)) * 0.3;
	vec3 grass = mix(grass_dark, grass_light, n);
	vec3 rock = rock_color * (0.8 + 0.4 * noise(vec2(world.x + world.z, world.y) / (patch_size * 0.4)));
	float flat_ground = smoothstep(rock_slope_start, rock_slope_end, world_normal.y);
	float depth = clamp(-world.y / dark_depth, 0.0, 1.0);
	ALBEDO = mix(rock, grass, flat_ground) * (1.0 - depth);
	ROUGHNESS = 0.95;
}
