class_name GameFileSource
extends Object
## Abstract class for accessing game files.

const _MAP_SAVE_FILE_PATTERN: String = "MAP0%d.SAV"
const _DATA_SAVE_FILE_PATTERN: String = "RIVER0%d0.SAV"

## Returns whether the given file path is one of the game's save files or not.
static func is_save_file(path: String) -> bool:
	return path.to_lower().ends_with(".sav")


## Returns the file name for a slot's map save.
static func get_map_save_file_name(slot: int) -> String:
	assert(slot >= 0 and slot <= 9, "slot must be in the range [0, 9]")
	return _MAP_SAVE_FILE_PATTERN % slot


## Returns the file name for a slot's data save.
static func get_data_save_file_name(slot: int) -> String:
	assert(slot >= 0 and slot <= 9, "slot must be in the range [0, 9]")
	return _DATA_SAVE_FILE_PATTERN % slot


## Returns if the given file exists.
func has_file(_path: String) -> bool:
	assert(false, "Not implemented")
	return false


## Returns the bytes of the given file or an empty array if it could not be
## read.
func read_file(_path: String) -> PackedByteArray:
	assert(false, "Not implemented")
	return []


## Overwrites the given file with the provided bytes or creates the file if it
## doesn't exist.
func write_file(_path: String, _bytes: PackedByteArray) -> Error:
	assert(false, "Not implemented")
	return Error.OK


## Gets the last modified time of the file in seconds since the Unix epoch or -1
## if there was an error.
func get_file_modified_time(_path: String) -> int:
	assert(false, "Not implemented")
	return -1


## Deletes the given file.
func delete_file(_path: String) -> Error:
	assert(false, "Not implemented")
	return Error.OK


## Returns the status of the last operation.
func get_error() -> Error:
	assert(false, "Not implemented")
	return Error.OK


## Tests whether the given path is a valid game file.
func _is_game_file() -> bool:
	return false
