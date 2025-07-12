class_name MapFile
extends Object
## Represents the contents of a .MAP or map.SAVE file.

const MAP_SIZE: int = 512

var _map_cells: Array[MapCell]

## Attempts to deserialize a map from the provided context.
static func deserialize(context: DeserializationContext) -> MapFile:
	var file_size = context.get_remaining_bytes()
	assert(file_size == 0x100000, 'Map save files are expected to always be 1MiB; was %db' % \
			file_size)
	
	var cells: Array[MapCell] = []
	
	while context.has_remaining_bytes():
		cells.append(MapCell.deserialize(context))
	
	var map = MapFile.new()
	map._map_cells = cells
	return map


## Returns the map cell at the given position.
func get_cell(x: int, y: int) -> MapCell:
	assert(x < MAP_SIZE, 'x must be less than %d' % MAP_SIZE)
	assert(y < MAP_SIZE, 'y must be less than %d' % MAP_SIZE)
	
	return _map_cells[x + y * MAP_SIZE]


## Represents a single cell of a map.
class MapCell:
	var _depth: int
	var _texture_index: int
	var _unknown_field: int
	var _flags: int
	
	## Attempts to deserialize a map cell from the provided context.
	static func deserialize(context: DeserializationContext) -> MapCell:
		var cell = MapCell.new()
		cell._depth = context.next_u8le()
		cell._texture_index = context.next_u8le()
		cell._unknown_field = context.next_u8le()
		cell._flags = context.next_u8le()
		
		return cell
	
	
	## The depth of the bottom-right vertex of the map cell.
	func get_depth() -> int:
		return _depth
	
	
	## Cell texture index into the MAPLAND array of the map's corresponding .ASM
	## file.
	func get_texture_index() -> int:
		return _texture_index
	
	
	## Returns the unknoown field of the map cell.
	## 
	## Used in-part to create the minimap; however, it's not the sole
	## contributor. This may be a shade color or something like a lightmap.
	## Typically has one of 17 non-contiguous values.
	func get_unknown_field() -> int:
		return _unknown_field
	
	
	## Returns whether you can construct buildings on this cell.
	func is_buildable() -> bool:
		return (0b00000001 & _flags)
	
	
	## Returns whether the player walk on this cell.
	func is_boundary() -> bool:
		return (0b00000010 & _flags) >> 1
	
	
	## Returns whether this cell is part of the river.
	## 
	## River cells are unwalkable, have waves, and override the cell to a fixed
	## height.
	func is_river() -> bool:
		return (0b00000100 & _flags) >> 2
	
	
	## Returns whether this cell is a river bank.
	## 
	## River banks have waves and override the cell to a fixed height.
	func is_bank() -> bool:
		return (0b00001000 & _flags) >> 3
	
	
	## Returns whetehr the cell has been revealed from the fog of war.
	func is_discovered() -> bool:
		return (0b00010000 & _flags) >> 4
