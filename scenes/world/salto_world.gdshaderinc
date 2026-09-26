// Réglages partagés par tous les matériaux du monde voxel (Paramètres du projet > Shader Globals),
// mis à jour à chaque image par WorldMood. Les couleurs sont calculées comme dans le prototype
// (TSL, valeurs d'écran), puis adaptées au moteur de rendu (salto_output).

global uniform float salto_time;
global uniform float salto_sat;
global uniform float salto_beat;
// Vie de la jungle, de 0 (nuit muette : couleurs éteintes et immobiles) à 1 (nuit gagnée : toutes
// les couleurs du prototype, qui dansent). Chaque tambour rapporté en rend une part.
global uniform float salto_life;
// Cercle du groove : rayon (m) autour du héros où la jungle retrouve toutes ses couleurs. La jauge
// de groove le fait grandir ; le Salto arc-en-ciel le fait éclater.
global uniform float salto_groove;
// Couleur du brouillard (TSL déjà converti en RVB d'écran) et densité par mètre.
global uniform vec4 salto_fog_color;
global uniform float salto_fog_density;
// Sanctuaires : x, z (u), libéré (0 à 1), inutilisé.
global uniform vec4 salto_sanctuary_0;
global uniform vec4 salto_sanctuary_1;
global uniform vec4 salto_sanctuary_2;
// Objectif : x, z (u), actif (1) ou non, sens (1 : on y va, -1 : on en revient).
global uniform vec4 salto_target;
// Héros (m), pour laisser voir le héros à travers le décor ; 1 pour activer.
global uniform vec3 salto_player;
global uniform float salto_cut;
// Mètres par unité du prototype.
global uniform float salto_unit;

// Rayons des zones de silence autour des sanctuaires non libérés (u).
const float SALTO_SILENCE_INNER = 13.0;
const float SALTO_SILENCE_OUTER = 19.0;

vec3 salto_hsl2rgb(vec3 c) {
	vec3 k = clamp(abs(mod(c.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return c.z + c.y * (k - 0.5) * (1.0 - abs(2.0 * c.z - 1.0));
}

// 1 loin des sanctuaires ; vers 0 près d'un sanctuaire encore muet (le silence boit les couleurs).
float salto_zone(vec2 p) {
	vec4 s[3] = vec4[3](salto_sanctuary_0, salto_sanctuary_1, salto_sanctuary_2);
	float f = 1.0;
	for (int i = 0; i < 3; i++) {
		float d = length(p - s[i].xy);
		f = min(f, mix(smoothstep(SALTO_SILENCE_INNER, SALTO_SILENCE_OUTER, d), 1.0, s[i].z));
	}
	return f;
}

// Saturation rendue dans le cercle du groove (celle d'une nuit presque gagnée) : les teintes
// restent celles de la jungle, seules leurs couleurs reviennent.
const float SALTO_HALO_SAT = 0.9;

// 1 dans le cercle du groove autour du héros, 0 au-delà (bord doux). `world` en mètres.
float salto_halo(vec3 world) {
	if (salto_groove <= 0.0) {
		return 0.0;
	}
	float d = length(world.xz - salto_player.xz);
	return 1.0 - smoothstep(salto_groove * 0.55, salto_groove, d);
}

vec3 salto_fog(vec3 c, float depth_m) {
	float f = 1.0 - exp(-salto_fog_density * salto_fog_density * depth_m * depth_m);
	return mix(c, salto_fog_color.rgb, f);
}

// Couleur calculée en valeurs d'écran (sRGB), prête pour le moteur de rendu : Mobile et Forward+
// travaillent en linéaire ; Compatibility (web) travaille directement en sRGB.
vec3 salto_output(vec3 c) {
	c = clamp(c, 0.0, 1.0);
	if (CURRENT_RENDERER == RENDERER_COMPATIBILITY) {
		return c;
	}
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}
