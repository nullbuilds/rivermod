class_name EditorFileSource
extends Object
## Abstract interface for accessing editor files.

## Defines the scopes which a file may exist in.
enum EditorFileScope {
	GLOBAL, ## Files scoped to the editor
	GAME    ## Files scoped to a specific game installation
}


## Returns if the given file exists.
@warning_ignore("unused_parameter")
func exists(scope: EditorFileScope, path: String) -> bool:
	assert(false, "Not implemented")
	return false


## Returns the bytes of the given file or an empty array if it could not be
## read.
@warning_ignore("unused_parameter")
func read_file(scope: EditorFileScope, path: String) -> PackedByteArray:
	assert(false, "Not implemented")
	return []


## Overwrites the given file with the provided bytes or creates the file if it
## doesn't exist.
@warning_ignore("unused_parameter")
func write_file(scope: EditorFileScope, path: String,
		bytes: PackedByteArray) -> Error:
	assert(false, "Not implemented")
	return Error.OK


## Gets the list of directories at the given path.
@warning_ignore("unused_parameter")
func get_directories(scope: EditorFileScope, path: String) -> PackedStringArray:
	assert(false, "Not implemented")
	return []


## Deletes the given file.
@warning_ignore("unused_parameter")
func delete_file(scope: EditorFileScope, path: String) -> Error:
	assert(false, "Not implemented")
	return Error.OK


## Returns the status of the last operation.
func get_error() -> Error:
	assert(false, "Not implemented")
	return Error.OK
