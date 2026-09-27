shader_type spatial;
// Matériau voxel du prototype pour les assemblages de cubes (MultiMesh) : chaque cube porte dans
// INSTANCE_CUSTOM sa couleur codée (voir salto_voxel.gdshaderinc).
render_mode unshaded, cull_back;

#include "res://scenes/world/salto_world.gdshaderinc"
#include "res://scenes/world/salto_voxel.gdshaderinc"

// Décor statique : devient pointillé entre la caméra et le héros pour qu'on le voie toujours.
uniform bool cutaway = false;

varying vec3 v_color;
varying vec3 v_world;
varying vec3 v_normal;
varying vec3 v_local;
varying vec3 v_local_normal;

// Seuil de Bayer 4×4 (pointillé régulier) pour le pixel `p`.
float bayer4(vec2 p) {
	vec2 q = mod(floor(p), 4.0);
	int i = int(q.x) + int(q.y) * 4;
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0;
}

void vertex() {
	v_color = INSTANCE_CUSTOM.rgb;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_local = VERTEX;
	v_local_normal = NORMAL;
}

void fragment() {
	vec3 w = v_world / salto_unit;
	if (cutaway && salto_cut > 0.5) {
		// Ce qui est entre la caméra et le héros (et au-dessus des pieds) s'efface : tout à fait
		// près de la ligne de vue (plus large près de la caméra), en pointillé léger autour.
		vec3 cam = CAMERA_POSITION_WORLD / salto_unit;
		vec3 pl = salto_player / salto_unit;
		vec2 to_cam = normalize(cam.xz - pl.xz);
		float fwd = dot(w.xz - pl.xz, to_cam);
		vec3 ab = pl - cam;
		float t = clamp(dot(w - cam, ab) / dot(ab, ab), 0.0, 1.0);
		float dd = length(w - (cam + ab * t));
		float tube = 1.0 - smoothstep(mix(9.0, 2.5, t), mix(16.0, 5.5, t), dd);
		float k = smoothstep(0.5, 3.0, fwd) * smoothstep(0.8, 2.2, w.y) * mix(0.82, 1.01, tube);
		if (k > bayer4(FRAGCOORD.xy)) {
			discard;
		}
	}
	float edge = salto_cube_edge(v_local, v_local_normal);
	vec3 c = salto_voxel_color(v_color, v_world, v_normal, CAMERA_POSITION_WORLD, 0.0, 0.0, edge);
	ALBEDO = salto_output(salto_fog(c, -VERTEX.z));
}
