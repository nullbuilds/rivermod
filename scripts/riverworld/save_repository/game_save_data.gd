class_name GameSaveData
extends Object
## Encapsulates the save data for a single save slot.

var _last_modified_time: int = -1
var _map_bytes: PackedByteArray
var _data_bytes: PackedByteArray

## Creates a new game save data object.
func _init(last_modified_time: int, map_bytes: PackedByteArray,
		data_bytes: PackedByteArray) -> void:
	_last_modified_time = last_modified_time
	_map_bytes = map_bytes
	_data_bytes = data_bytes


## Gets the last modified time in seconds since the Unix epoch.
func get_last_modified_time() -> int:
	return _last_modified_time


## Gets the bytes of the save's map file.
func get_map_bytes() -> PackedByteArray:
	return _map_bytes


## Gets the bytes of the save's data (river) file.
func get_data_bytes() -> PackedByteArray:
	return _data_bytes
