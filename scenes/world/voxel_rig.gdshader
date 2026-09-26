shader_type spatial;
// Matériau voxel des assemblages articulés (VoxelRig : personnages, Muets) : un seul maillage
// animé par un squelette ; chaque sommet porte dans CUSTOM0 la couleur codée de son cube (voir
// salto_voxel.gdshaderinc).
render_mode unshaded, cull_back;

#include "res://scenes/world/salto_world.gdshaderinc"
#include "res://scenes/world/salto_voxel.gdshaderinc"

// Éclat blanc (Muet touché), de 0 à 1.
uniform float flash = 0.0;
// Couleurs retrouvées en arc-en-ciel (Muet qu'on libère), de 0 à 1.
uniform float vivid = 0.0;
// Couleurs rendues pour de bon (Muet libéré qui danse au village), de 0 à 1.
uniform float healed = 0.0;
// Rougeur de la rage (Grand Muet blessé), de 0 à 1.
uniform float rage = 0.0;

varying vec3 v_color;
varying vec3 v_world;
varying vec3 v_normal;

void vertex() {
	v_color = CUSTOM0.rgb;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 c = salto_voxel_color(v_color, v_world, v_normal, CAMERA_POSITION_WORLD, vivid, healed);
	c = mix(c, vec3(c.r * 1.2 + 0.12, c.g * 0.5, c.b * 0.55), rage);
	c = mix(c, vec3(1.0), flash);
	ALBEDO = salto_output(salto_fog(c, -VERTEX.z));
}
