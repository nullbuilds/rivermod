// https://www.reddit.com/r/godot/comments/te4bmc/comment/i0nygem/

shader_type spatial;
render_mode unshaded,cull_disabled;

uniform bool world_space = true; // toggle between world and local space
uniform bool remap_range = false; // remap from -1..1 to 0..1

void fragment() {
	// World space normal
	vec4 color = INV_VIEW_MATRIX * vec4(NORMAL, 0.0);
	if (world_space == false) {
		color = inverse(MODEL_MATRIX) * color;
	}
	if (remap_range == true) {
		ALBEDO = (color.rgb + 1.0)/2.0;
	} else {
		ALBEDO = color.rgb;
	}
}
