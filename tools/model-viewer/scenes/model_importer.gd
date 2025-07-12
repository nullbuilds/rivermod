class_name ModelImporter
extends Object
##  Imports the game's model files into a format Godot can use.

var _texture_directory: String
var _default_material: Material

## Constructs a new model importer from the given texture directory.
func _init(texture_directory: String, default_material: Material):
	_texture_directory = texture_directory
	_default_material = default_material


## Imports the given model file.
func import(model: ModelFile) -> Array:
	assert(model != null, 'Model must not be null')
	
	# Load textures
	var extra_maps_frames = 0
	var textures = null
	for frame in model.get_frames():
		var frame_data = frame.get_data()
		if frame_data is ModelFile.MapsFrameData:
			if textures == null:
				textures = _import_textures(frame_data)
			else:
				extra_maps_frames += 1
	
	if extra_maps_frames > 0:
		push_error('Expected only a single maps frame in a model file; %d were found; ignoring the extras' % \
				extra_maps_frames)
	
	var extra_material_frames = 0
	var materials = null
	for frame in model.get_frames():
		var frame_data = frame.get_data()
		if frame_data is ModelFile.MaterialFrameData:
			if materials == null:
				materials = _import_materials(frame_data, textures)
			else:
				extra_material_frames += 1
	
	if extra_material_frames > 0:
		push_error('Expected only a single materials frame in a model file; %d were found; ignoring the extras' % \
				extra_material_frames)
	
	var extra_degr_frames = 0
	var elements = null
	for frame in model.get_frames():
		var frame_data = frame.get_data()
		if frame_data is ModelFile.DegrFrameData:
			if elements == null:
				elements = _import_degr_elements(frame_data, materials)
			else:
				extra_degr_frames += 1
	
	if extra_degr_frames > 0:
		push_error('Expected only a single degr frame in a model file; %d were found; ignoring the extras' % \
				extra_degr_frames)
	
	return elements


func _import_textures(maps: ModelFile.MapsFrameData) -> Array[Texture2D]:
	assert(maps != null, 'Maps must not be null')
	
	var textures: Array[Texture2D] = []
	for texture_file in maps.get_texture_names():
		# For an unknown reason, texture files are stored in a GIFS directory
		# with the .PNG extension but the materials list them as having the .GIF
		# extension
		var renamed_texture_file = texture_file.replace('.GIF', '.PNG')
		var texture_path = _texture_directory.path_join(renamed_texture_file)
		
		var texture = null
		if FileAccess.file_exists(texture_path):
			var image = Image.load_from_file(texture_path)
			if image != null:
				texture = ImageTexture.create_from_image(image)
			else:
				push_error('Failed to load texture file "%s"' % texture_path)
		else:
			push_error('No such texture file "%s"' % texture_path)
		
		if texture == null:
			texture = _make_default_texture()
		
		textures.append(texture)
	
	return textures


func _import_materials(material_frame: ModelFile.MaterialFrameData, textures: Array[Texture2D]) -> Array[Material]:
	assert(material_frame != null, 'Material frame must not be null')
	assert(textures != null, 'Textures must not be null')
	
	# The default material is added first as face material indices are
	# 1-indexed. It is assumed a value of 0 means no material but these faces
	# should still be visible in the viewer so we use the default material.
	var materials: Array[Material] = []
	materials.append(_default_material)
	
	for frame in material_frame.get_children():
		var frame_data = frame.get_data()
		if frame_data is ModelFile.MaterialAttributeFrameData:
			var material = StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			material.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
			
			var texture_index = frame_data.get_texture_index()
			if texture_index < textures.size():
				material.albedo_texture = textures[texture_index]
			else:
				push_error('Material specified invalid texture id; was %d but max is %d' % \
						[texture_index, textures.size() - 1])
				material.albedo_texture = _make_default_texture()
			
			# TODO set according to attribute data
			material.cull_mode = material.CULL_DISABLED
			material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			
			materials.append(material)
	
	return materials


func _import_degr_elements(degr: ModelFile.DegrFrameData, materials: Array[Material]) -> Array:
	assert(degr != null, 'Degr must not be null')
	
	var elements = []
	for frame in degr.get_children():
		var frame_data = frame.get_data()
		if frame_data is ModelFile.ElementFrameData:
			var element_objects = _import_element_objects(frame_data, materials)
			elements.append(element_objects)
		else:
			push_error('Expected the degr frame to only contain elements; frame was of type %s' % \
					frame.get_type())
	
	return elements


func _import_element_objects(element: ModelFile.ElementFrameData, materials: Array[Material]) -> Array[Mesh]:
	assert(element != null, 'Element must not be null')
	
	var objects: Array[Mesh] = []
	for frame in element.get_children():
		var frame_data = frame.get_data()
		if frame_data is ModelFile.ObjectFrameData:
			var object_meshes = _import_object_mesh(frame_data, materials)
			objects.append(object_meshes)
		else:
			push_error('Expected the element frame to only contain objects; frame was of type %s' % \
					frame.get_type())
	
	return objects


func _import_object_mesh(object: ModelFile.ObjectFrameData, materials: Array[Material]) -> Mesh:
	assert(object != null, 'Object must not be null')
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var faces:Array[ModelFile.FaceArrayFrameData.Face] = []
	for frame in object.get_children():
		var frame_data = frame.get_data()
		if frame_data is ModelFile.VertexArrayFrameData:
			vertices.append_array(_import_vertices(frame_data))
		elif frame_data is ModelFile.NormalArrayFrameData:
			normals.append_array(_import_normals(frame_data))
		elif frame_data is ModelFile.FaceArrayFrameData:
			faces.append_array(_import_faces(frame_data))
		else:
			push_error('Expected the object frame to only contain vertices, normals, and faces; frame was of type %s' % \
					frame.get_type())
	
	return _build_mesh(vertices, normals, faces, materials)


func _import_vertices(vertices: ModelFile.VertexArrayFrameData) -> PackedVector3Array:
	assert(vertices != null, 'Vertices must not be null')
	
	var converted_vertices = PackedVector3Array([])
	for vertex in vertices.get_vertices():
		var x = vertex.get_x()
		var y = vertex.get_y()
		var z = vertex.get_z()
		converted_vertices.append(Vector3i(x, y, z))
	
	return converted_vertices


func _import_normals(normals: ModelFile.NormalArrayFrameData) -> PackedVector3Array:
	assert(normals != null, 'Normals must not be null')
	
	var converted_normals = PackedVector3Array([])
	for normal in normals.get_normals():
		var x = normal.get_x()
		var y = normal.get_y()
		var z = normal.get_z()
		converted_normals.append(Vector3(Vector3i(x, y, z)).normalized())
	
	return converted_normals


func _import_faces(faces: ModelFile.FaceArrayFrameData) -> Array[ModelFile.FaceArrayFrameData.Face]:
	assert(faces != null, 'Faces must not be null')
	
	return faces.get_faces()


func _build_mesh(vertices: PackedVector3Array, normals: PackedVector3Array, \
		faces: Array[ModelFile.FaceArrayFrameData.Face], materials: Array[Material]) -> Mesh:
	assert(vertices != null, 'Vertices must not be null')
	assert(normals != null, 'Normals must not be null')
	assert(faces != null, 'Faces must not be null')
	assert(vertices.size() == normals.size(), 'The number of vertices and normals must be equal; %d vertices, %d normals' % \
			[vertices.size(), normals.size()])
	assert(materials != null, 'Materials must not be null')
	
	var mesh = ArrayMesh.new()
	
	# Some faces define different UV coordinates for the same vertex. It's
	# unclear how, if at all, the game determines which faces should be created
	# as part of the same surface. To prevent the UVs of adjacent faces from
	# becoming overwritten, each face is created as its own surface.
	# TODO determine if there is a way to do this without creating separate
	# surfaces for each face.
	for face in faces:
		var face_vertices = PackedInt32Array()
		var uvs = PackedVector2Array()
		uvs.resize(vertices.size())
		
		var face_vertex_indices = face.get_used_vertex_indices()
		var face_uv_coordinates = face.get_used_uv_coordinates()
		if face.get_face_vertices() == 4:
			var vertex_index_a = face_vertex_indices[0].get_index()
			var vertex_index_b = face_vertex_indices[1].get_index()
			var vertex_index_c = face_vertex_indices[2].get_index()
			var vertex_index_d = face_vertex_indices[3].get_index()
			
			var vertex_uv_a = face_uv_coordinates[0].get_uv_vector()
			var vertex_uv_b = face_uv_coordinates[1].get_uv_vector()
			var vertex_uv_c = face_uv_coordinates[2].get_uv_vector()
			var vertex_uv_d = face_uv_coordinates[3].get_uv_vector()
			
			face_vertices.append(vertex_index_a)
			face_vertices.append(vertex_index_c)
			face_vertices.append(vertex_index_b)
			
			face_vertices.append(vertex_index_d)
			face_vertices.append(vertex_index_c)
			face_vertices.append(vertex_index_a)
		
			uvs.set(vertex_index_a, vertex_uv_a)
			uvs.set(vertex_index_b, vertex_uv_b)
			uvs.set(vertex_index_c, vertex_uv_c)
			uvs.set(vertex_index_d, vertex_uv_d)
		elif face.get_face_vertices() == 3:
			var vertex_index_a = face_vertex_indices[0].get_index()
			var vertex_index_b = face_vertex_indices[1].get_index()
			var vertex_index_c = face_vertex_indices[2].get_index()
			
			var vertex_uv_a = face_uv_coordinates[0].get_uv_vector()
			var vertex_uv_b = face_uv_coordinates[1].get_uv_vector()
			var vertex_uv_c = face_uv_coordinates[2].get_uv_vector()
			
			face_vertices.append(vertex_index_a)
			face_vertices.append(vertex_index_c)
			face_vertices.append(vertex_index_b)
			
			uvs.set(vertex_index_a, vertex_uv_a)
			uvs.set(vertex_index_b, vertex_uv_b)
			uvs.set(vertex_index_c, vertex_uv_c)
		else:
			push_warning('Expected a face with 3 or 4 vertices; had %d; skipping' % \
					face.get_face_vertices())
		
		var surface_id = mesh.get_surface_count()
		var surface_array = []
		surface_array.resize(Mesh.ARRAY_MAX)
		surface_array[Mesh.ARRAY_VERTEX] = vertices
		surface_array[Mesh.ARRAY_NORMAL] = normals
		surface_array[Mesh.ARRAY_TEX_UV] = uvs
		surface_array[Mesh.ARRAY_INDEX] = face_vertices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
		
		var material_id = face.get_material_index()
		if material_id >= materials.size():
			push_error('Face specified a non-existant material id %d' % \
					material_id)
			material_id = 0
		mesh.surface_set_material(surface_id, materials[material_id])
	
	return mesh


func _make_default_texture() -> Texture2D:
	var size = 256
	var color = Color.MAGENTA
	
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	
	return ImageTexture.create_from_image(image)
