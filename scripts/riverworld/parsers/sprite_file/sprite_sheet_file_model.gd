class_name SpriteSheetFileModel
extends RefCounted
## Models the contents of a .SPR file.

var _header_bytes: PackedByteArray = []
var _sprites: Array[SpriteModel] = []

## Attempts to deserialize a sprite sheet from the provided context.
static func parse(context: ParseContext) -> SpriteSheetFileModel:
	# Read the sheet header length
	if not context.has_remaining_bytes(2):
		var remaining_bytes: int = context.get_remaining_bytes()
		context.log_error("Unable to parse sprite sheet; insufficient bytes (%d) for a header" % remaining_bytes)
		return null
	var header_length: int = context.next_u16le()
	var remaining_header_length: int = header_length - 2
	if header_length < 2:
		context.log_error("Unable to parse sprite sheet; header size is invalid; was %d" % header_length)
		return null
	elif header_length == 2:
		context.log_warning("Sprite sheet header contains no data")
	
	var sprite_sheet: SpriteSheetFileModel = SpriteSheetFileModel.new()
	
	# Read the header bytes
	if not context.has_remaining_bytes(remaining_header_length):
		var remaining_bytes: int = context.get_remaining_bytes()
		context.log_error("Unable to parse sprite sheet; insufficient remaining bytes (%d) for header %d" % [remaining_bytes, remaining_header_length])
		return sprite_sheet
	sprite_sheet._header_bytes = context.next_bytes(remaining_header_length).duplicate()
	
	# Read sprite offset table position
	var sprite_offset_table_start: int = context.get_read_bytes()
	
	# Read sprite offset table length
	# It's unclear how Riverworld knows how many entries are in the offset table
	# so we assumes the first sprite immediately follows the table and use that
	# to determine its length
	if not context.has_remaining_bytes(2):
		var remaining_bytes: int = context.get_remaining_bytes()
		context.log_error("Unable to parse sprite sheet; insufficient bytes (%d) for sprite offset table" % remaining_bytes)
		return sprite_sheet
	var sprite_offset_table_size: int = context.peek_u16le()
	
	# Check if offset table size is valid
	if sprite_offset_table_size % 2 != 0:
		context.log_error("Unable to parse sprite sheet; sprite offset table size is not divisible by 2; was %d" % sprite_offset_table_size)
		return sprite_sheet
	elif not context.has_remaining_bytes(sprite_offset_table_size):
		var remaining_bytes: int = context.get_remaining_bytes()
		context.log_error("Unable to parse sprite sheet; sprite offset table size (%d) is greater than the number of remaining bytes %d" % [sprite_offset_table_size, remaining_bytes])
		return sprite_sheet
	
	# Read the sprite offset table
	@warning_ignore("integer_division")
	var sprite_offset_count: int = sprite_offset_table_size / 2
	var sprite_offsets: PackedInt32Array = []
	for sprite_offset_index in sprite_offset_count:
		var offset: int = context.next_u16le()
		if offset >= sprite_offset_table_size:
			sprite_offsets.push_back(offset)
		else:
			context.log_error("Unable to parse sprite sheet; sprite offset table entry %d specifies an offset (%d) within the table itself; table is %d bytes" % [sprite_offset_index, offset, sprite_offset_table_size])
			return sprite_sheet
	
	# Read sprites in order of offset table
	# This implementation does not preserve the sprite storage location if
	# sprites are stored in a different order than the offset table (ex the
	# offset if sprite 0 is a higher member address than the offset of sprite
	# 1). This is assumed to be irrelavent.
	var sprites: Array[SpriteModel] = []
	var highest_sprite_offset: int = 0
	for offset in sprite_offsets:
		var sprite_offset: int = sprite_offset_table_start + offset
		context.move_cursor(sprite_offset)
		
		# Check if the sprite memory layout is unusual and report this as it
		# will not be preserved when loading
		var sprite_index: int = sprites.size()
		if sprite_offset < highest_sprite_offset:
			context.log_warning("Sprite %d is defined at offset %d but a previous sprite was at %d; the memory layout of these sprites will not be preserved" % [sprite_index, sprite_offset, highest_sprite_offset])
		highest_sprite_offset = maxi(sprite_offset, highest_sprite_offset)
		
		var sprite: SpriteModel = SpriteModel.parse(context)
		if null != sprite:
			sprites.push_back(sprite)
	sprite_sheet._sprites = sprites
	
	return sprite_sheet


## Gets the sprites in the sprite sheet.
func get_sprites() -> Array[SpriteModel]:
	return _sprites


## Returns the header bytes.
## 
## The purpose of these bytes is unknown.
func get_header() -> PackedByteArray:
	return _header_bytes


## Returns the largest width and height of all contained sprites.
func get_max_size() -> Vector2i:
	var max_size: Vector2i = Vector2i.ZERO
	for sprite in _sprites:
		var sprite_size: Vector2i = sprite.get_size()
		max_size = max_size.max(sprite_size)
	
	return max_size


## Represents a single sprite within the sheet.
class SpriteModel extends RefCounted:
	var _size: Vector2i = Vector2i.ZERO
	var _unknown_field_a: int = 0
	var _unknown_field_b: int = 0
	var _pixel_color_indices: PackedByteArray = []
	
	## Attempts to deserialize a sprite from the provided context.
	static func parse(context: ParseContext) -> SpriteModel:
		if not context.has_remaining_bytes(4):
			var offset: int = context.get_read_bytes()
			var remaining_bytes: int = context.get_remaining_bytes()
			context.log_error("Unable to parse sprite at offset %d; only %d bytes remain but 4 are required for the header" % [offset, remaining_bytes])
			return null
		
		# Read header data
		var width: int = context.next_u8le()
		var unknown_field_a: int = context.next_u8le()
		var height: int = context.next_u8le()
		var unknown_field_b: int = context.next_u8le()
		
		# Read pixel data
		var pixel_bytes: int = width * height
		if not context.has_remaining_bytes(pixel_bytes):
			var offset: int = context.get_read_bytes()
			var remaining_bytes: int = context.get_remaining_bytes()
			context.log_error("Unable to parse sprite at offset %d; only %d bytes remain but %d are required for the pixel data" % [offset, remaining_bytes, pixel_bytes])
			return null
		var pixel_color_indices: PackedByteArray = context.next_bytes(pixel_bytes)
		
		var sprite: SpriteModel = SpriteModel.new()
		sprite._size = Vector2i(width, height)
		sprite._unknown_field_a = unknown_field_a
		sprite._unknown_field_b = unknown_field_b
		sprite._pixel_color_indices = pixel_color_indices
		return sprite
	
	
	## Gets the size of the sprite in pixels.
	func get_size() -> Vector2i:
		return _size
	
	
	## Gets the color table index of all pixels.
	## 
	## Indices are returned in left-right, top-down order.
	func get_pixel_color_indices() -> PackedByteArray:
		return _pixel_color_indices
	
	
	## Returns the size of palette used by the sprite.
	func get_color_palette_size() -> int:
		return Array(_pixel_color_indices).max() + 1
	
	
	## Returns the value of the first unknown header field.
	func get_unknown_field_a() -> int:
		return _unknown_field_a
	
	
	## Returns the value of the second unknown header field.
	func get_unknown_field_b() -> int:
		return _unknown_field_b
