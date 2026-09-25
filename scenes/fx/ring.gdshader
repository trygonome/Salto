shader_type spatial;
// Anneau d'effet du prototype : lumineux (additif), sans profondeur, posé à plat.
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 color : source_color = vec4(1.0);
uniform float opacity = 1.0;

void fragment() {
	ALBEDO = color.rgb * opacity;
}
