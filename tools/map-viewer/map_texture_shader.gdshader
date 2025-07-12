shader_type spatial;
render_mode shadows_disabled;

uniform sampler2D cell_texture_indices;
uniform sampler2DArray textures;

void fragment() {
	// Determine the number of cells wide the map is.
	uint map_size = uint(textureSize(cell_texture_indices, 0).x);
	uint max_cell_index = map_size - 1u;
	
	// Scale the UVs to the size of the map.
	vec2 map_scaled_uv = UV * float(map_size);
	
	// Get the coordinates of the cell on the map.
	ivec2 cell_coords = ivec2(int(map_scaled_uv.x), int(map_scaled_uv.y));
	
	// Calculate the UVs of the individual cell.
	vec2 cell_uv = map_scaled_uv - vec2(cell_coords);
	
	// Determine the texture to apply to the cell.
	vec4 cell_texture_data = texelFetch(cell_texture_indices, cell_coords, 0);
	uint cell_texture_index = uint(cell_texture_data.r * 255.0);
	
	// Get pixel to render from the cell's texture.
	ivec3 texture_size = textureSize(textures, 0);
	ivec2 texture_coords = ivec2(
			int(cell_uv.x * float(texture_size.x)),
			int(cell_uv.y * float(texture_size.y)));
	vec4 color = texelFetch(
			textures,
			ivec3(texture_coords.x, texture_coords.y, int(cell_texture_index)),
			0);
	
	ALBEDO = color.rgb;
}
