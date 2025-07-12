class_name ModelFile
extends Object
## Encapsulates the raw contents of a .xxx model file.

var _frames: Array[Frame]

## Attempts to deserialize a model from the provided context.
static func deserialize(context: DeserializationContext) -> ModelFile:
	var model = ModelFile.new()
	
	while context.has_remaining_bytes():
		var frame = Frame.deserialize(context)
		if frame != null:
			model._frames.append(frame)
	
	return model


## Attempts to serialize the model.
func serialize() -> PackedByteArray:
	var bytes = PackedByteArray()
	
	for frame in _frames:
		bytes.append_array(frame.serialize())
	
	return bytes


## Returns a copy of all frames contained within the model.
func get_frames() -> Array[Frame]:
	return _frames.duplicate()


## Represents a frame of data within a model file.
class Frame:
	const _MAX_FRAME_SIZE: int = 0xffffffff
	const _HEADER_LENGTH: int = 8
	const _FRAME_TYPE_DEGR: String = 'DEGR'
	const _FRAME_TYPE_ELEMENT: String = 'ELEM'
	const _FRAME_TYPE_OBJECT: String = 'OBJE'
	const _FRAME_TYPE_VERTEX_ARRAY: String = 'VERT'
	const _FRAME_TYPE_NORMAL_ARRAY: String = 'NORM'
	const _FRAME_TYPE_FACE_ARRAY: String = 'FACE'
	const _FRAME_TYPE_MATERIAL: String = 'MATE'
	const _FRAME_TYPE_MATERIAL_ATTRIBUTE: String = 'ATTR'
	const _FRAME_TYPE_MAPS: String = 'MAPS'
	const _FRAME_TYPE_ANIMATION: String = 'ANIM'
	const _FRAME_DATA_DESERIALIZERS = {
		_FRAME_TYPE_DEGR: Callable(DegrFrameData, 'deserialize'),
		_FRAME_TYPE_ELEMENT: Callable(ElementFrameData, 'deserialize'),
		_FRAME_TYPE_OBJECT: Callable(ObjectFrameData, 'deserialize'),
		_FRAME_TYPE_VERTEX_ARRAY: Callable(VertexArrayFrameData, 'deserialize'),
		_FRAME_TYPE_NORMAL_ARRAY: Callable(NormalArrayFrameData, 'deserialize'),
		_FRAME_TYPE_FACE_ARRAY: Callable(FaceArrayFrameData, 'deserialize'),
		_FRAME_TYPE_MATERIAL: Callable(MaterialFrameData, 'deserialize'),
		_FRAME_TYPE_MATERIAL_ATTRIBUTE: Callable(MaterialAttributeFrameData, 'deserialize'),
		_FRAME_TYPE_MAPS: Callable(MapsFrameData, 'deserialize'),
		_FRAME_TYPE_ANIMATION: Callable(AnimationFrameData, 'deserialize')
	}
	
	var _type: String
	var _data: FrameData
	
	## Attempts to deserialize a frame from the provided context.
	static func deserialize(context: DeserializationContext) -> Frame:
		# Frames have an 8 byte header consisting of a 4 byte ASCII type and a
		# u32le size.
		var frame_type = context.next_fixed_length_string(4)
		
		# The frame size includes the length of the header.
		var frame_size = context.next_u32le()
		if frame_size < _HEADER_LENGTH:
			context.log_error('Frame length (%d) is defined as less than the header length (%d) indicating corruption; adjusting length to %d' % \
					[frame_size, _HEADER_LENGTH, _HEADER_LENGTH])
			frame_size = _HEADER_LENGTH
		
		var data_size = frame_size - _HEADER_LENGTH
		
		# Everything after the frame header, up to the frame size, is data
		if !context.has_remaining_bytes(data_size):
			var remaining_bytes = context.get_remaining_bytes()
			context.log_error('Frame data size (%d) is defined as being larger than the number of remaining bytes in the context; data size truncated to remaining size %d' % \
					[data_size, remaining_bytes])
			data_size = remaining_bytes
		
		var data_context = context.child_context(data_size)
		
		# Read data bytes
		var frame: Frame = null
		if _FRAME_DATA_DESERIALIZERS.has(frame_type):
			frame = Frame.new()
			frame._type = frame_type
			frame._data = _FRAME_DATA_DESERIALIZERS[frame_type] \
					.call(data_context)
		else:
			context.log_error('Unsupported frame type "%s" (0x%s); skipping' % \
					[frame_type, frame_type.to_utf8_buffer().hex_encode()])
		
		if data_context.has_remaining_bytes():
			context.log_warning('The frame defined %d bytes of data but only %d were read; this may indicate a parsing error or a malformed frame' % \
					[data_size, data_context.get_read_bytes()])
		
		return frame
	
	
	## Attempts to serialize the frame.
	func serialize() -> PackedByteArray:
		var frame_type = _type.to_ascii_buffer()
		var data = _data.serialize()
		
		# The length of a frame includes the type, U32 length, and the data
		var length = frame_type.size() + data.size() + 4 
		assert(length <= _MAX_FRAME_SIZE, 'Frame size (%d) exceeds the maximum limit %d' % \
				[length, _MAX_FRAME_SIZE])
		
		var bytes = PackedByteArray()
		bytes.resize(length)
		bytes.append_array(frame_type)
		bytes.encode_u32(frame_type.size(), length)
		bytes.append_array(data)
		
		return bytes
	
	
	## Gets the frame's type string.
	func get_type() -> String:
		return _type
	
	
	## Gets the frame's data.
	func get_data() -> FrameData:
		return _data


## Abstract class representing the data contained within a Frame.
class FrameData:
	## Attempts to serialize the frame data.
	func serialize() -> PackedByteArray:
		return PackedByteArray()


## Represents the DEGR (meaning unknown) data of a model file.
class DegrFrameData extends FrameData:
	const _MAX_CHILDREN: int = 0xffff
	
	var _frames: Array[Frame]
	
	## Attempts to deserialize DEGR data from the provided context.
	static func deserialize(context: DeserializationContext) -> DegrFrameData:
		assert(context != null, 'Context must not be null')
		
		# The number of child frames
		var children = context.next_u16le()
		
		var frames: Array[Frame] = []
		for child in children:
			var frame = Frame.deserialize(context)
			if frame != null:
				frames.append(frame)
			else:
				context.log_error('Malformed DEGR frame; was defined to contain %d child frames but only %d frames could be read' % \
						[children, frames.size()])
				break
		
		var data = DegrFrameData.new()
		data._frames = frames
		return data
	
	
	## Attempts to serialize the frame data.
	func serialize() -> PackedByteArray:
		var frames = _frames.size()
		assert(frames <= _MAX_CHILDREN, 'The number of child frames (%d) exceeds the number that can be serialized (%d)' % \
				[frames, _MAX_CHILDREN])
		
		var bytes = PackedByteArray()
		bytes.resize(2)
		bytes.encode_u16(0, frames)
		
		for frame in _frames:
			bytes.append_array(frame.serialize())
		
		return bytes
	
	
	## Returns a copy of the child frames
	func get_children() -> Array[Frame]:
		return _frames.duplicate()


## Represents an element within a model file.
class ElementFrameData extends FrameData:
	const _MAX_CHILDREN: int = 0xffff
	
	var _frames: Array[Frame]
	var _unknown_field: int
	
	## Attempts to deserialize element data from the provided context.
	static func deserialize(context: DeserializationContext) -> ElementFrameData:
		assert(context != null, 'Context must not be null')
		
		# The number of child frames
		var children = context.next_u16le()
		
		# Unknown field(s)
		var unknown_field = context.next_u16le()
		
		var frames: Array[Frame] = []
		for child in children:
			var frame = Frame.deserialize(context)
			if frame != null:
				frames.append(frame)
			else:
				context.log_error('Malformed element frame; was defined to contain %d child frames but only %d frames could be read' % \
						[children, frames.size()])
				break
		
		var data = ElementFrameData.new()
		data._frames = frames
		data._unknown_field = unknown_field
		return data
	
	
	## Attempts to serialize the frame data.
	func serialize() -> PackedByteArray:
		var frames = _frames.size()
		assert(frames <= _MAX_CHILDREN, 'The number of child frames (%d) exceeds the number that can be serialized (%d)' % \
				[frames, _MAX_CHILDREN])
		
		var bytes = PackedByteArray()
		bytes.resize(4)
		bytes.encode_u16(0, frames)
		bytes.encode_u16(2, _unknown_field)
		
		for frame in _frames:
			bytes.append_array(frame.serialize())
		
		return bytes
	
	
	## Returns the value of the unknown field
	func get_unknown_field() -> int:
		return _unknown_field
	
	
	## Returns a copy of the child frames
	func get_children() -> Array[Frame]:
		return _frames.duplicate()


## Represents an object within a model file.
class ObjectFrameData extends FrameData:
	const _MAX_VERTEX_NORMAL_PAIRS: int = 0xffff
	const _MAX_CHILDREN: int = _MAX_VERTEX_NORMAL_PAIRS * 2 + 1
	
	var _frames: Array[Frame]
	
	## Attempts to deserialize object data from the provided context.
	static func deserialize(context: DeserializationContext) -> ObjectFrameData:
		assert(context != null, 'Context must not be null')
		
		# The number of vertex/normal frame pairs
		var vertex_normal_pairs = context.next_u16le()
		
		# Objects are expected to have a variable number of vertex frame and
		# normal frame pairs plus a single face frame that is always present.
		var children = vertex_normal_pairs * 2 + 1
		
		var frames: Array[Frame] = []
		for child in children:
			var frame = Frame.deserialize(context)
			if frame != null:
				frames.append(frame)
			else:
				context.log_error('Malformed object frame; was expected to contain %d vertex frames, %d normal frames, and 1 face frame only %d frames could be read' % \
						[vertex_normal_pairs, vertex_normal_pairs, frames.size()])
				break
		
		var data = ObjectFrameData.new()
		data._frames = frames
		return data
	
	
	## Attempts to serialize the frame data.
	func serialize() -> PackedByteArray:
		var frames = _frames.size()
		assert(frames % 2 == 1, 'Object frames must contain an odd number of child frames and a minimum of 1; had %d child frames' % \
				frames)
		
		assert(frames <= _MAX_CHILDREN, 'The number of child frames (%d) exceeds the number that can be serialized (%d)' % \
				[frames, _MAX_CHILDREN])
		
		var bytes = PackedByteArray()
		bytes.resize(2)
		bytes.encode_u16(0, frames)
		
		for frame in _frames:
			bytes.append_array(frame.serialize())
		
		return bytes
	
	
	## Returns a copy of the child frames
	func get_children() -> Array[Frame]:
		return _frames.duplicate()


## Represents a vertex array within a model file.
class VertexArrayFrameData extends FrameData:
	const _MAX_VERTICES: int = 0xffff
	
	var _vertices: Array[Vertex]
	
	## Attempts to deserialize a vertex array from the provided context.
	static func deserialize(context: DeserializationContext) -> VertexArrayFrameData:
		assert(context != null, 'Context must not be null')
		
		# The number of vertices
		var vertex_count = context.next_u16le()
		
		var vertices: Array[Vertex] = []
		for i in vertex_count:
			var vertex = Vertex.deserialize(context)
			if vertex != null:
				vertices.append(vertex)
			else:
				context.log_error('Malformed vertex array; was expected to contain %d vertices but only %d could be read' % \
						[vertex_count, vertices.size()])
				break
		
		var data = VertexArrayFrameData.new()
		data._vertices = vertices
		return data
	
	
	## Attempts to serialize the frame data.
	func serialize() -> PackedByteArray:
		var vertices = _vertices.size()
		assert(vertices <= _MAX_VERTICES, 'The number of vertices (%d) exceeds the number that can be serialized (%d)' % \
				[vertices, _MAX_VERTICES])
		
		var bytes = PackedByteArray()
		bytes.resize(2)
		bytes.encode_u16(0, vertices)
		
		for vertex in _vertices:
			bytes.append_array(vertex.serialize())
		
		return bytes
	
	
	## Returns a copy of the vertices.
	func get_vertices() -> Array[Vertex]:
		return _vertices.duplicate()
	
	
	## Represents a vertex within a model file.
	class Vertex:
		const MAX_AXIS_VALUE: int = 32767
		const MIN_AXIS_VALUE: int = -32768
		
		var _x: int
		var _y: int
		var _z: int
		
		## Attempts to deserialize a vertex from the provided context.
		static func deserialize(context: DeserializationContext) -> Vertex:
			assert(context != null, 'Context must not be null')
			
			if !context.has_remaining_bytes(6):
				context.log_error('Insufficient bytes remaining to deserialize a vertex; needed 6; had %d' % \
						context.get_remaining_bytes())
				return null
			
			var vertex = Vertex.new()
			vertex._x = context.next_s16le()
			vertex._y = context.next_s16le()
			vertex._z = context.next_s16le()
			
			return vertex
		
		
		## Attempts to serialize the vertex.
		func serialize() -> PackedByteArray:
			var bytes = PackedByteArray()
			bytes.resize(6)
			bytes.encode_s16(0, _x)
			bytes.encode_s16(2, _y)
			bytes.encode_s16(4, _z)
			
			return bytes
		
		
		## Returns the 16-bit x coordinate.
		func get_x() -> int:
			return _x
		
		
		## Returns the 16-bit y coordinate.
		func get_y() -> int:
			return _y
		
		
		## Returns the 16-bit z coordinate.
		func get_z() -> int:
			return _z


## Represents a normal array within a model file.
class NormalArrayFrameData extends FrameData:
	const _MAX_NORMALS: int = 0xffff
	
	var _normals: Array[Normal]
	
	## Attempts to deserialize a normal array from the provided context.
	static func deserialize(context: DeserializationContext) -> NormalArrayFrameData:
		assert(context != null, 'Context must not be null')
		
		# The number of normals
		var normal_count = context.next_u16le()
		
		var normals: Array[Normal] = []
		for i in normal_count:
			var normal = Normal.deserialize(context)
			if normal != null:
				normals.append(normal)
			else:
				context.log_error('Malformed normal array; was expected to contain %d normals but only %d could be read' % \
						[normal_count, normals.size()])
				break
		
		var data = NormalArrayFrameData.new()
		data._normals = normals
		return data
	
	
	## Attempts to serialize the frame data.
	func serialize() -> PackedByteArray:
		var normals = _normals.size()
		assert(normals <= _MAX_NORMALS, 'The number of normals (%d) exceeds the number that can be serialized (%d)' % \
				[normals, _MAX_NORMALS])
		
		var bytes = PackedByteArray()
		bytes.resize(2)
		bytes.encode_u16(0, normals)
		
		for normal in _normals:
			bytes.append_array(normal.serialize())
		
		return bytes
	
	
	## Returns a copy of the normals.
	func get_normals() -> Array[Normal]:
		return _normals.duplicate()
	
	
	## Represents a normal within a model file.
	class Normal:
		const MAX_AXIS_VALUE: int = 32767
		const MIN_AXIS_VALUE: int = -32768
		
		var _x: int
		var _y: int
		var _z: int
		
		## Attempts to deserialize a normal from the provided context.
		static func deserialize(context: DeserializationContext) -> Normal:
			assert(context != null, 'Context must not be null')
			
			if !context.has_remaining_bytes(6):
				context.log_error('Insufficient bytes remaining to deserialize a normal; needed 6; had %d' % \
						context.get_remaining_bytes())
				return null
			
			var normal = Normal.new()
			normal._x = context.next_s16le()
			normal._y = context.next_s16le()
			normal._z = context.next_s16le()
			
			if normal._x == 0 and normal._y == 0 and normal._z == 0:
				context.log_warning('Normal has a magnitude of 0')
			
			return normal
		
		
		## Attempts to serialize the normal.
		func serialize() -> PackedByteArray:
			var bytes = PackedByteArray()
			bytes.resize(6)
			bytes.encode_s16(0, _x)
			bytes.encode_s16(2, _y)
			bytes.encode_s16(4, _z)
			
			return bytes
		
		
		## Returns the 16-bit x coordinate.
		func get_x() -> int:
			return _x
		
		
		## Returns the 16-bit y coordinate.
		func get_y() -> int:
			return _y
		
		
		## Returns the 16-bit z coordinate.
		func get_z() -> int:
			return _z
		
		
		## Returns the magnitude of the normal
		func get_magnitude() -> float:
			return Vector3i(_x, _y, _z).length()


## Represents a face array within a model file.
class FaceArrayFrameData extends FrameData:
	const _MAX_FACES: int = 0xffff
	
	var _faces: Array[Face]
	
	## Attempts to deserialize a face array from the provided context.
	static func deserialize(context: DeserializationContext) -> FaceArrayFrameData:
		assert(context != null, 'Context must not be null')
		
		# The number of faces
		var face_count = context.next_u16le()
		
		var faces: Array[Face] = []
		for i in face_count:
			var face = Face.deserialize(context)
			if face != null:
				faces.append(face)
			else:
				context.log_error('Malformed face array; was expected to contain %d faces but only %d could be read' % \
						[face_count, faces.size()])
				break
		
		var data = FaceArrayFrameData.new()
		data._faces = faces
		return data
	
	
	## Attempts to serialize the frame data.
	func serialize() -> PackedByteArray:
		var faces = _faces.size()
		assert(faces <= _MAX_FACES, 'The number of faces (%d) exceeds the number that can be serialized (%d)' % \
				[faces, _MAX_FACES])
		
		var bytes = PackedByteArray()
		bytes.resize(2)
		bytes.encode_u16(0, faces)
		
		for face in _faces:
			bytes.append_array(face.serialize())
		
		return bytes
	
	
	## Returns a copy of the faces.
	func get_faces() -> Array[Face]:
		return _faces.duplicate()
	
	
	## Represents a face in a model file.
	class Face:
		var _flags: int
		var _face_vertices: int
		var _material_index: int
		var _vertex_indices: Array[VertexIndex]
		var _uv_coordinates: Array[UvCoordinate]
		var _unknown_bytes: PackedByteArray
		
		## Attempts to deserialize a face from the provided context.
		static func deserialize(context: DeserializationContext) -> Face:
			assert(context != null, 'Context must not be null.')
			
			# It's unknown if flags only indicates whether a face is
			# double-sided or if it contains additional information.
			var flags = context.next_u8le()
			if (0b11111110 & flags) != 0:
				context.log_warning('Face flags is expected to only contain 1-bit of data; was %x' % \
						flags)
			
			# Indicates how many vertices are used by the face as it has a fixed
			# size array. Greater than 4 and less than 3 are assumed to be
			## impossible.
			var face_vertices = context.next_u8le()
			if !(face_vertices == 3 or face_vertices == 4):
				context.log_error('Face vertex count is assumed to only be 3 or 4; was %d' % \
						face_vertices)
			
			# The index of the material to use. This field appears to be
			# 1-indexed so assume 0 as an anomoly.
			var material_index = context.next_u8le()
			if material_index < 1:
				context.log_warning('Face material index is expected to be 1 or more; was %d' % \
						material_index)
			
			# Faces have a hard-coded array of 4 vertices. It's assume that the
			# last vertex index will be 0 when the face vertex count is 3.
			var vertex_indices: Array[VertexIndex] = []
			for i in 4:
				var vertex_index = VertexIndex.deserialize(context)
				vertex_indices.append(vertex_index)
				var value = vertex_index.get_index()
				if face_vertices == 3 and i == 3 and value != 0:
					context.log_warning('Face is defined as having 3 vertices but the 4th index was non-zero: %d' % \
							value)
			
			# Faces have a hard-coded array of 4 UV coordinates. It's assume
			# that the last coordinate index will be 0 when the face vertex
			# count is 3.
			var uv_coordinates: Array[UvCoordinate] = []
			for i in 4:
				var uv_coordinate = UvCoordinate.deserialize(context)
				uv_coordinates.append(uv_coordinate)
				var u = uv_coordinate.get_raw_u()
				var v = uv_coordinate.get_raw_v()
				if face_vertices == 3 and i == 3 and (u != 0 or v != 0):
					context.log_warning('Face is defined as having 3 vertices but the 4th UV coordinate was non-zero: [%d, %d]' % \
							[u, v])
			
			# The purpose of these bytes is unknownl; however, it's assumed the
			# first value is always 0.
			var unknown_bytes = context.next_bytes(4)
			if unknown_bytes[0] != 0:
				context.log_warning('The first unknown byte of a face is assumed to always be 0; was %d' % \
							unknown_bytes[0])
			
			var data = Face.new()
			data._flags = flags
			data._face_vertices = face_vertices
			data._material_index = material_index
			data._vertex_indices = vertex_indices
			data._uv_coordinates = uv_coordinates
			data._unknown_bytes = unknown_bytes
			return data
		
		
		## Attempts to serialize the face.
		func serialize() -> PackedByteArray:
			var bytes = PackedByteArray()
			bytes.resize(3)
			bytes.encode_u8(0, _flags)
			bytes.encode_u8(1, _face_vertices)
			bytes.encode_u8(2, _material_index)
			
			for vertex_index in _vertex_indices:
				bytes.append_array(vertex_index.serialize())
			
			for uv_coordinate in _uv_coordinates:
				bytes.append_array(uv_coordinate.serialize())
			
			bytes.append_array(_unknown_bytes)
			
			return bytes
		
		
		## Returns whether this face is double-sided.
		func is_double_sided() -> bool:
			return (0b00000001 & _flags)
		
		
		## Returns how many vertices/UVs are used by the face.
		## 
		## Faces are hard-coded to always contain 4 vertices; however, fewer may
		## be used by the face type.
		func get_face_vertices() -> int:
			return _face_vertices
		
		
		## Returns a copy of the vertex indices used by the face.
		## 
		## Faces are hard-coded to always contain 4 vertices; however, fewer may
		## be used by the face type.
		func get_used_vertex_indices() -> Array[VertexIndex]:
			return _vertex_indices.slice(0, _face_vertices)
		
		
		## Returns a copy of the UV coordinates used by the face.
		## 
		## Faces are hard-coded to always contain 4 UVs; however, fewer may
		## be used by the face type.
		func get_used_uv_coordinates() -> Array[UvCoordinate]:
			return _uv_coordinates.slice(0, _face_vertices)
		
		
		## Returns the index of the material to use (1-indexed).
		func get_material_index() -> int:
			return _material_index
		
		
		## Returns a copy of the unknown bytes included in the face.
		func get_unknown_bytes() -> PackedByteArray:
			return _unknown_bytes.duplicate()
		
		
		## Represents a vertex index in a face.
		class VertexIndex:
			var _index: int
			var _unknown_field: int
			
			## Attempts to deserialize a vertex index from the provided context.
			static func deserialize(context: DeserializationContext) -> VertexIndex:
				assert(context != null, 'Context must not be null')
				
				# The unknown field is assumed to always be 0
				var unknown_field = context.next_u8le()
				if unknown_field != 0:
					context.log_warning('Vertex index unknown field is assumed to always be 0; was %d' % \
							unknown_field)
				
				var index = context.next_u8le()
				
				var data = VertexIndex.new()
				data._index = index
				data._unknown_field = unknown_field
				return data
			
			
			## Attempts to serialize the vertex index.
			func serialize() -> PackedByteArray:
				var bytes = PackedByteArray()
				bytes.resize(2)
				bytes.encode_u8(0, _unknown_field)
				bytes.encode_u8(1, _index)
				
				return bytes
			
			
			## Returns the vertex index.
			func get_index() -> int:
				return _index
			
			
			## Returns the value of the unknown field paired with a vertex
			## index.
			func get_unknown_field() -> int:
				return _unknown_field
		
		
		## Represents a UV coordinate in a face.
		class UvCoordinate:
			var _unknown_field_u: int
			var _u: int
			var _unknown_field_v: int
			var _v: int
			
			## Attempts to deserialize a vertex index from the provided context.
			static func deserialize(context: DeserializationContext) -> UvCoordinate:
				assert(context != null, 'Context must not be null')
				
				# The unknown fields are assumed to always be 0
				var unknown_field_u = context.next_u8le()
				if unknown_field_u != 0:
					context.log_warning('UV.u unknown field is assumed to always be 0; was %d' % \
							unknown_field_u)
				
				var u = context.next_u8le()
				
				# The unknown fields are assumed to always be 0
				var unknown_field_v = context.next_u8le()
				if unknown_field_v != 0:
					context.log_warning('UV.v unknown field is assumed to always be 0; was %d' % \
							unknown_field_v)
				
				var v = context.next_u8le()
				
				var data = UvCoordinate.new()
				data._unknown_field_u = unknown_field_u
				data._u = u
				data._unknown_field_v = unknown_field_v
				data._v = v
				return data
			
			
			## Attempts to serialize the UV coordinate.
			func serialize() -> PackedByteArray:
				var bytes = PackedByteArray()
				bytes.resize(4)
				bytes.encode_u8(0, _unknown_field_u)
				bytes.encode_u8(1, _u)
				bytes.encode_u8(2, _unknown_field_v)
				bytes.encode_u8(3, _v)
				
				return bytes
			
			
			## Returns the raw U coordinate
			func get_raw_u() -> int:
				return _u
			
			
			## Returns the raw V coordinate
			func get_raw_v() -> int:
				return _v
			
			
			## Returns the uv coordinates as a vector2.
			func get_uv_vector() -> Vector2:
				return Vector2(float(_u) / 255.0, float(_v) / 255.0)
			
			
			## Returns the U coordinate unknown field.
			func get_unknown_field_u() -> int:
				return _unknown_field_u
			
			
			## Returns the V coordinate unknown field.
			func get_unknown_field_v() -> int:
				return _unknown_field_v


## Represents a material within a model file.
class MaterialFrameData extends FrameData:
	const _MAX_CHILDREN: int = 0xffff
	
	var _frames: Array[Frame]
	
	## Attempts to deserialize a material from the provided context.
	static func deserialize(context: DeserializationContext) -> MaterialFrameData:
		assert(context != null, 'Context must not be null')
		
		# The number of child frames
		var children = context.next_u16le()
		
		var frames: Array[Frame] = []
		for child in children:
			var frame = Frame.deserialize(context)
			if frame != null:
				frames.append(frame)
			else:
				context.log_error('Malformed material frame; was defined to contain %d child frames but only %d frames could be read' % \
						[children, frames.size()])
				break
		
		var data = MaterialFrameData.new()
		data._frames = frames
		return data
	
	
	## Attempts to serialize the frame data.
	func serialize() -> PackedByteArray:
		var frames = _frames.size()
		assert(frames <= _MAX_CHILDREN, 'The number of child frames (%d) exceeds the number that can be serialized (%d)' % \
				[frames, _MAX_CHILDREN])
		
		var bytes = PackedByteArray()
		bytes.resize(2)
		bytes.encode_u16(0, frames)
		
		for frame in _frames:
			bytes.append_array(frame.serialize())
		
		return bytes
	
	
	## Returns a copy of the child frames
	func get_children() -> Array[Frame]:
		return _frames.duplicate()


## Represents a material attribute within a model file.
class MaterialAttributeFrameData extends FrameData:
	var _unknown_field_a: int
	var _is_transparent: bool
	var _texture_index: int
	var _unknown_remaining_bytes: PackedByteArray
	
	## Attempts to deserialize a material attribute from the provided context.
	static func deserialize(context: DeserializationContext) -> MaterialAttributeFrameData:
		assert(context != null, 'Context must not be null')
		
		# The purpose of this field is unknown but is usually valued as 2
		var unknown_field_a = context.next_u8le()
		if unknown_field_a != 2:
			context.log_warning('Material attribute unknown field a is assumed to always be 2; was %d' % \
					unknown_field_a)
		
		# This field is beleive to only indicate transparency but has not been
		# proven
		var transparency_field = context.next_u8le()
		if (0b11111110 & transparency_field) != 0:
			context.log_warning('Material attribute transparency field contained more than 1-bit of data; was %x' % \
					transparency_field)
		
		# The index of the texture into the MAPS frame
		var texture_index = context.next_u8le()
		
		# Material attributes have been observed to contain a variable number of
		# bytes after the first three fields. 1 bytes is the typical count.
		# Anything else is considered unusual.
		var remaining_bytes = context.get_remaining_bytes()
		var unknown_remaining_bytes = context.next_bytes(remaining_bytes)
		if remaining_bytes != 1:
			context.log_warning('The number of unknown material attribute bytes is expected to be 1; was %d (%s)' % \
					[remaining_bytes, unknown_remaining_bytes.hex_encode()])
		
		var data = MaterialAttributeFrameData.new()
		data._unknown_field_a = unknown_field_a
		data._is_transparent = 0b00000001 & transparency_field
		data._texture_index = texture_index
		data._unknown_remaining_bytes = unknown_remaining_bytes
		return data
	
	
	## Attempts to serialize the frame data.
	func serialize() -> PackedByteArray:
		var bytes = PackedByteArray()
		bytes.resize(4)
		bytes.encode_u8(0, _unknown_field_a)
		bytes.encode_u8(1, _is_transparent)
		bytes.encode_u8(2, _texture_index)
		bytes.append_array(_unknown_remaining_bytes)
		
		return bytes
	
	
	## Gets the unknown bytes of the attribute.
	func get_unknown_field_a() -> int:
		return _unknown_field_a
	
	
	## Returns whether the material should be rendered with transparency.
	func is_transparent() -> bool:
		return _is_transparent
	
	
	## Returns the index of the texture to use.
	func get_texture_index() -> int:
		return _texture_index
	
	
	## Returns a copy of the unknown bytes of the attribute.
	func get_unknown_bytes() -> PackedByteArray:
		return _unknown_remaining_bytes.duplicate()


## Represents a maps array within a model file.
class MapsFrameData extends FrameData:
	const _MAX_TEXTURE_NAMES: int = 0xffff
	
	var _texture_names: PackedStringArray
	var _extra_bytes: PackedByteArray
	
	## Attempts to deserialize maps data from the provided context.
	static func deserialize(context: DeserializationContext) -> MapsFrameData:
		assert(context != null, 'Context must not be null')
		
		# The number of textures
		var texture_name_count = context.next_u16le()
		
		var texture_names: PackedStringArray = []
		for i in texture_name_count:
			# Some texture names have been found to contain non-printable
			# characters like newlines. This is assumed to be a mistake so they
			# are just removed.
			var texture_name = context.next_c_string().strip_escapes()
			if texture_name != null:
				texture_names.append(texture_name)
			else:
				context.log_error('Malformed texture array; was expected to contain %d texture names but only %d could be read' % \
						[texture_name_count, texture_names.size()])
				break
		
		# Maps frames sometimes contain extra bytes after the last texture name.
		# The purpose of these bytes, if any, is unknown.
		var remaining_bytes = context.get_remaining_bytes()
		var extra_bytes = context.next_bytes(remaining_bytes)
		if remaining_bytes != 0:
			context.log_warning('Extra bytes were found after the texture name; %s' % \
						extra_bytes.hex_encode())
		
		var data = MapsFrameData.new()
		data._texture_names = texture_names
		data._extra_bytes = extra_bytes
		return data
	
	
	## Attempts to serialize the frame data.
	func serialize() -> PackedByteArray:
		var texture_names = _texture_names.size()
		assert(texture_names <= _MAX_TEXTURE_NAMES, 'The number of texture names (%d) exceeds the number that can be serialized (%d)' % \
				[texture_names, _MAX_TEXTURE_NAMES])
		
		var bytes = PackedByteArray()
		bytes.resize(2)
		bytes.encode_u16(0, texture_names)
		
		for texture_name in _texture_names:
			var texture_name_bytes = texture_name.to_ascii_buffer().append(0)
			bytes.append_array(texture_name_bytes)
		
		bytes.append_array(_extra_bytes)
		
		return bytes
	
	
	## Returns a copy of the texture names.
	func get_texture_names() -> PackedStringArray:
		return _texture_names.duplicate()
	
	
	## Returns the extra bytes sometimes included after the texture names.
	func get_extra_bytes() -> PackedByteArray:
		return _extra_bytes.duplicate()


## Represents animation data within a model file.
class AnimationFrameData extends FrameData:
	# It's not currently what this data is or how to parse it
	var _unknown_data: PackedByteArray
	
	## Attempts to deserialize animation data from the provided context.
	static func deserialize(context: DeserializationContext) -> AnimationFrameData:
		assert(context != null, 'Context must not be null')
		
		var to_read = 160
		if !context.has_remaining_bytes(to_read):
			context.log_error('Only %d bytes were available but animation data is expected to always be 160 bytes' % \
					to_read)
			to_read = context.get_remaining_bytes()
		
		var bytes = context.next_bytes(to_read)
		
		var data = AnimationFrameData.new()
		data._unknown_data = bytes
		return data
	
	
	## Attempts to serialize the frame data.
	func serialize() -> PackedByteArray:
		return _unknown_data.duplicate()
	
	
	## Returns the unknown bytes.
	func get_unknown_bytes() -> PackedByteArray:
		return _unknown_data.duplicate()
