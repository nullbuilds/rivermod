class_name MapImporter
extends Object
## Imports data from the game's maps.

const _TEXTURE_DIRECTORY: String = 'SCPE'
const _MAP_SHADER: Shader = preload("res://map_texture_shader.gdshader")

var _texture_directory: String

## Constructs a new map importer from the given texture directory.
func _init(game_directory: String):
	_texture_directory = game_directory.path_join(_TEXTURE_DIRECTORY)


## Imports the map's mesh.
func import_mesh(map_file: MapFile, script_file: ScriptFile, cell_size: float, \
		vertical_scale: float) -> Mesh:
	var vertex_rows = MapFile.MAP_SIZE + 1
	var vertex_columns = MapFile.MAP_SIZE + 1
	
	var vertices = PackedVector3Array()
	for vertex_row in vertex_rows:
		for vertex_column in vertex_columns:
			var vertex_height = 0.0
			
			# The first row of vertices has a height of 0.0. The height of a
			# cell defines the height of the cell's bottom-right vertex. The
			# bottom-left vertex is the bottom-right of the previous cell so it
			# uses its height. The first vertex of each column is the
			# bottom-left of the first cell; however, there is no adjacent cell
			# to the left so it uses the height of the literal previous cell
			# (the last cell of the previous row). The first column of the first
			# row which has no previous cell so it defaults to 0.
			
			# Is this the first row of vertices or the bottom-left vertex of the
			# first cell? if so, default to 0.0 height.
			if vertex_row > 0 and !(vertex_row == 1 and vertex_column == 0):
				var cell_row = vertex_row - 1 # 0
				var cell_column = vertex_column - 1 # 512
				
				# Is this the bottom-left vertex of the first cell in a row? If
				# so, use the last cell in the previous row's height
				if vertex_column == 0:
					cell_column = MapFile.MAP_SIZE - 1
					cell_row -= 1
				
				# This is the bottom right of a cell, use its height
				vertex_height = -map_file.get_cell(cell_column, cell_row).get_depth() * vertical_scale
			
			var vertex = Vector3(vertex_column * cell_size, vertex_height, vertex_row * cell_size)
			vertices.append(vertex)
	
	# Cells are divided into triangles along their top-left and bottom-right
	# vertices. Define the triangles in clockwise order so Godot sets the front
	# face correctly. Simultaniously sum the normals of each plane to the
	# vertices that create it so the vertex normals can be calculated later.
	var vertex_face_normals_sum = PackedVector3Array()
	vertex_face_normals_sum.resize(vertices.size())
	vertex_face_normals_sum.fill(Vector3.ZERO)
	var indices = PackedInt32Array()
	for vertex_row in vertex_rows - 1:
		for vertex_column in vertex_columns - 1:
			var top_left_vertex_index = vertex_column + vertex_columns * vertex_row
			var top_right_vertex_index = top_left_vertex_index + 1
			var bottom_right_vertex_index = top_left_vertex_index + vertex_columns + 1
			var bottom_left_vertex_index = top_left_vertex_index + vertex_columns
			
			var top_left_vertex = vertices[top_left_vertex_index]
			var top_right_vertex = vertices[top_right_vertex_index]
			var bottom_left_vertex = vertices[bottom_left_vertex_index]
			var bottom_right_vertex = vertices[bottom_right_vertex_index]
			
			# Triangle 1
			indices.append(top_left_vertex_index)
			indices.append(bottom_right_vertex_index)
			indices.append(bottom_left_vertex_index)
			var triangle1 = Plane(top_left_vertex, bottom_right_vertex, bottom_left_vertex)
			var triangle1_normal = triangle1.normal
			vertex_face_normals_sum[top_left_vertex_index] += triangle1_normal
			vertex_face_normals_sum[bottom_right_vertex_index] += triangle1_normal
			vertex_face_normals_sum[bottom_left_vertex_index] += triangle1_normal
			
			# Triangle 2
			indices.append(top_left_vertex_index)
			indices.append(top_right_vertex_index)
			indices.append(bottom_right_vertex_index)
			var triangle2 = Plane(top_left_vertex, top_right_vertex, bottom_right_vertex)
			var triangle2_normal = triangle2.normal
			vertex_face_normals_sum[top_left_vertex_index] += triangle2_normal
			vertex_face_normals_sum[top_right_vertex_index] += triangle2_normal
			vertex_face_normals_sum[bottom_right_vertex_index] += triangle2_normal
	
	# Finish calculating the normals for each vertex by normalizing the sum of
	# the faces previously calculated
	var normals = PackedVector3Array()
	normals.resize(vertices.size())
	for vertex_index in vertices.size():
		var face_normals_sum = vertex_face_normals_sum[vertex_index]
		normals[vertex_index] = face_normals_sum.normalized()
	
	# Assign the UVs of each cell such a single texture covers all cells.
	var uvs = PackedVector2Array()
	for vertex_row in vertex_rows:
		for vertex_column in vertex_columns:
			var u = float(vertex_column) / float(vertex_columns - 1)
			var v = float(vertex_row) / float(vertex_rows - 1)
			uvs.append(Vector2(u, v))
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	var texture_indices = _get_texture_index_map(map_file)
	
	var texture_list = script_file.get_list(ScriptFile.LIST_MAP_TEXTURE) as ScriptFile.MapTextureList
	var textures = _load_map_textures(texture_list)
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	mesh.surface_set_material(0, _get_map_material(texture_indices, textures))
	return mesh


## Returns the fog-of-war mask.
func get_fog_of_war_mask(map_file: MapFile, discovered: Color = Color.WHITE,
		undiscovered: Color = Color.BLACK,
		format: Image.Format = Image.FORMAT_RGBA8) -> Image:
	var fog_of_war = Image.create(MapFile.MAP_SIZE, MapFile.MAP_SIZE, false,
			format)
	
	for row in MapFile.MAP_SIZE:
		for column in MapFile.MAP_SIZE:
			var cell = map_file.get_cell(column, row)
			var color = discovered if cell.is_discovered() else undiscovered
			fog_of_war.set_pixel(column, row, color)
	
	return fog_of_war


## Returns the minimap.
func get_minimap(map_file: MapFile) -> Image:
	var minimap = Image.create(MapFile.MAP_SIZE, MapFile.MAP_SIZE, false,
			Image.FORMAT_RGBA8)
	
	var palette = _generate_minimap_color_palette()
	
	for row in MapFile.MAP_SIZE:
		for column in MapFile.MAP_SIZE:
			var cell = map_file.get_cell(column, row)
			var color = palette[cell.get_unknown_field()]
			minimap.set_pixel(column, row, color)
	
	return minimap


## Returns the map mesh material.
func _get_map_material(texture_indices: ImageTexture,
		textures: Texture2DArray) -> Material:
	var material = ShaderMaterial.new()
	material.shader = _MAP_SHADER
	material.set_shader_parameter('cell_texture_indices', texture_indices)
	material.set_shader_parameter('textures', textures)
	
	return material


## Returns the texture index map for the map.
func _get_texture_index_map(map_file: MapFile) -> Texture2D:
	var texture_index_map = Image.create(MapFile.MAP_SIZE, MapFile.MAP_SIZE,
			false, Image.FORMAT_RGBA8)
	
	for row in MapFile.MAP_SIZE:
		for column in MapFile.MAP_SIZE:
			var cell = map_file.get_cell(column, row)
			var texture_index = cell.get_texture_index()
			var index_float = texture_index / 255.0
			var color = Color(index_float, index_float, index_float)
			texture_index_map.set_pixel(column, row, color)
	
	return ImageTexture.create_from_image(texture_index_map)


## Loads the map textures.
func _load_map_textures(texture_list: ScriptFile.MapTextureList) -> Texture2DArray:
	var images: Array[Image] = []
	for i in texture_list.size():
		var texture_pair = texture_list.get_texture_pair(i)
		var image_file_name = texture_pair.get_base_texture() \
				.get_image().replace('.GIF', '.PNG')
		var image_file_path = _texture_directory.path_join(image_file_name)
		
		var image = Image.load_from_file(image_file_path)
		images.append(image)
	
	var texture = Texture2DArray.new()
	texture.create_from_images(images)
	return texture


## Generates a color palette for the minimap.
func _generate_minimap_color_palette() -> Array[Color]:
	var palette: Array[Color] = []
	palette.resize(256)
	palette.fill(Color.MAGENTA)
	
	# TODO these colors are not complete. The minimap includes far more
	# seemingly based on the tile texture, unknown field in the cell data, and
	# possibly height though unconfirmed
	palette[0] = Color('f0f8f8') # 00
	palette[16] = Color('e8ece8') # 10
	palette[32] = Color('e8ece8') # 20
	palette[48] = Color('d0d0c0') # 30
	palette[64] = Color('c0c0b0') # 40
	palette[80] = Color('b0b0a0') # 50
	palette[96] = Color('a0a488') # 60
	palette[112] = Color('989478') # 70
	palette[128] = Color('888468') # 80
	palette[144] = Color('787858') # 90
	palette[160] = Color('686840') # A0
	palette[176] = Color('605830') # B0
	palette[192] = Color('504820') # C0
	palette[208] = Color('484418') # D0
	palette[224] = Color('403c18') # E0
	palette[240] = Color('383818') # F0
	palette[255] = Color('383010') # FF
	
	return palette
