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
	vec3 c = salto_voxel_color(v_color, v_world, v_normal, CAMERA_POSITION_WORLD, 0.0, 0.0);
	ALBEDO = salto_output(salto_fog(c, -VERTEX.z));
}
