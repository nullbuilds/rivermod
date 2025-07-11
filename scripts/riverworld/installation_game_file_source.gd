class_name InstallationGameFileSource
extends GameFileSource
## Provides access to the game's installed files.

var _config_service: EditorConfigurationService = null
var _last_error: Error = Error.OK

## Constructs a new installation file source with the given configuration
## service.
func _init(config_service: EditorConfigurationService) -> void:
	assert(config_service != null, "config_service must not be null")
	_config_service = config_service


## Checks if the given path is a Riverworld install directory.
func is_install_directory(path: String) -> bool:
	if path.is_absolute_path():
		var executable_name: String = get_direct_x_executable_name()
		var executable_path: String = path.path_join(executable_name)
		return FileAccess.file_exists(executable_path)
	return false


## Returns if the given file exists.
func has_file(path: String) -> bool:
	var full_path: String = _get_valid_game_path(path)
	if _last_error != Error.OK:
		return false
	return FileAccess.file_exists(full_path)


## Returns the bytes of the given file or an empty array if it could not be
## read.
func read_file(path: String) -> PackedByteArray:
	var full_path: String = _get_valid_game_path(path)
	
	var bytes: PackedByteArray = []
	if _last_error == Error.OK:
		bytes = FileAccess.get_file_as_bytes(full_path)
		var open_error: Error = FileAccess.get_open_error()
		_last_error = open_error
	
	return bytes


## Overwrites the given file with the provided bytes or creates the file if it
## doesn't exist.
func write_file(path: String, bytes: PackedByteArray) -> Error:
	var full_path: String = _get_valid_game_path(path)
	if _last_error == Error.OK:
		var error: Error = Error.OK
		error = DirAccess.make_dir_recursive_absolute(full_path.get_base_dir())
		if error == Error.OK:
			var file: FileAccess = FileAccess.open(full_path, FileAccess.WRITE)
			error = FileAccess.get_open_error()
			if error == Error.OK:
				if file.store_buffer(bytes):
					error = file.get_error()
				file.close()
		_last_error = error
	
	return _last_error


## Gets the last modified time of the file in seconds since the Unix epoch or -1
## if there was an error.
func get_file_modified_time(path: String) -> int:
	var full_path: String = _get_valid_game_path(path)
	if _last_error == Error.OK:
		var last_modified: int = FileAccess.get_modified_time(full_path)
		if last_modified > 0:
			_last_error = Error.OK
			return last_modified
		else:
			_last_error = Error.FAILED
	
	return -1


## Deletes the given file.
func delete_file(path: String) -> Error:
	var full_path: String = _get_valid_game_path(path)
	if _last_error == Error.OK:
		_last_error = DirAccess.remove_absolute(full_path)
	
	return _last_error


## Returns the status of the last operation.
func get_error() -> Error:
	return _last_error


## Returns an absolute path for the path if it is within the game's install
## directory and does not contain any of the protected paths; otherwise, returns
## empty.
func _get_valid_game_path(path: String) -> String:
	var install_directory: String = _get_install_directory()
	if _last_error != Error.OK:
		return ""
	
	var absolute_path: String = path
	if not path.is_absolute_path():
		absolute_path = install_directory.path_join(path).simplify_path()
	
	if absolute_path.begins_with(install_directory):
		var protected_directory: String = _config_service.get_game_install_editor_directory()
		if not absolute_path.contains(protected_directory):
			_last_error = Error.OK
			return absolute_path
	
	_last_error = Error.ERR_INVALID_PARAMETER
	return ""


## Gets the current game install directory and validates it or sets the error
## field when not configured.
func _get_install_directory() -> String:
	var install_directory: String = _config_service.get_game_install_directory()
	if not install_directory.is_empty():
		if DirAccess.dir_exists_absolute(install_directory):
			_last_error = Error.OK
			return install_directory
		else:
			_last_error = Error.ERR_FILE_BAD_PATH
	else:
		_last_error = Error.ERR_UNCONFIGURED
	
	return ""
