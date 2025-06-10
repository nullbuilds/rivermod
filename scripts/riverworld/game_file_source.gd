class_name GameFileSource
extends Object
## Abstract class for accessing game files.

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
