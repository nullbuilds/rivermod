class_name FileSystemEditorFileSource
extends EditorFileSource
## Accesses editor files on the file system.

var _last_error: Error = Error.OK
var _config_service: EditorConfigurationService
var _protected_file_paths: PackedStringArray = []

## Constructs a new editor file source.
## 
## The provided config file path will be made protected so operations of this
## class cannot access it.
func _init(config_service: EditorConfigurationService,
		protected_config_file_path: PackedStringArray) -> void:
	assert(config_service != null, "config_service must not be null")
	assert(protected_config_file_path != null, "protected_config_file_path must not be null")
	_config_service = config_service
	_protected_file_paths = protected_config_file_path.duplicate()


## Returns if the given file exists.
func exists(scope: EditorFileScope, path: String) -> bool:
	var full_path: String = _get_valid_path(scope, path)
	if _last_error == Error.OK:
		return FileAccess.file_exists(full_path)
	
	return false


## Returns the bytes of the given file or an empty array if it could not be
## read.
func read_file(scope: EditorFileScope, path: String) -> PackedByteArray:
	var full_path: String = _get_valid_path(scope, path)
	
	var bytes: PackedByteArray = []
	if _last_error == Error.OK:
		bytes = FileAccess.get_file_as_bytes(full_path)
		var open_error: Error = FileAccess.get_open_error()
		_last_error = open_error
	
	return bytes


## Overwrites the given file with the provided bytes or creates the file if it
## doesn't exist.
func write_file(scope: EditorFileScope, path: String,
		bytes: PackedByteArray) -> Error:
	var full_path: String = _get_valid_path(scope, path)
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


## Gets the list of directories at the given path.
func get_directories(scope: EditorFileScope, path: String) -> PackedStringArray:
	var full_path: String = _get_valid_path(scope, path)
	
	var directory: DirAccess = DirAccess.open(full_path)
	_last_error = DirAccess.get_open_error()
	if _last_error != Error.OK:
		return []
	
	directory.include_hidden = true
	directory.include_navigational = false
	_last_error = Error.OK
	
	var raw_directories: PackedStringArray = directory.get_directories()
	var filtered_directories: PackedStringArray = []
	for entry in raw_directories:
		if not _protected_file_paths.has(entry):
			filtered_directories.append(entry)
	
	return filtered_directories


## Deletes the given file.
func delete_file(scope: EditorFileScope, path: String) -> Error:
	var full_path: String = _get_valid_path(scope, path)
	if _last_error == Error.OK:
		_last_error = _delete_recursive(full_path)
	
	return _last_error


## Returns the status of the last operation.
func get_error() -> Error:
	return _last_error


## Removes a single file or directory recursively.
func _delete_recursive(path: String) -> Error:
	var overall_error: Error = Error.OK
	var error: Error = Error.OK
	
	if DirAccess.dir_exists_absolute(path):
		for directory in DirAccess.get_directories_at(path):
			error = _delete_recursive(path.path_join(directory))
			if error != Error.OK:
				overall_error = error
		
		for file in DirAccess.get_files_at(path):
			error = DirAccess.remove_absolute(path.path_join(file))
			if error != Error.OK:
				overall_error = error
	
	error = DirAccess.remove_absolute(path)
	if error != Error.OK:
		overall_error = error
	
	return overall_error


## Returns an absolute path for the path if it is within the scope directory and
## does not contain any of the protected paths; otherwise, returns empty.
func _get_valid_path(scope: EditorFileScope, path: String) -> String:
	var validated_path: String = ""
	match scope:
		EditorFileSource.EditorFileScope.GLOBAL:
			validated_path = _get_valid_global_scoped_path(path)
		EditorFileSource.EditorFileScope.GAME:
			validated_path = _get_valid_game_scoped_path(path)
	
	return validated_path


## Returns an absolute path for the path if it is within the global-scoped
## directory and does not contain any of the protected paths; otherwise,
## returns empty.
func _get_valid_global_scoped_path(path: String) -> String:
	return _get_valid_scope_path("user://", path)


## Returns an absolute path for the path if it is within the game-scoped
## directory and does not contain any of the protected paths; otherwise,
## returns empty.
func _get_valid_game_scoped_path(path: String) -> String:
	var install_directory: String = _get_game_install_directory()
	if _last_error != Error.OK:
		return ""
	
	var editor_directory_name: String = _config_service.get_game_install_editor_directory()
	var editor_directory: String = install_directory.path_join(editor_directory_name)
	
	return _get_valid_scope_path(editor_directory, path)


## Returns an absolute path for the path if it is within the scoped directory
## and does not contain any of the protected paths; otherwise, returns empty.
func _get_valid_scope_path(scope_directory: String,path: String) -> String:
	var absolute_path: String = scope_directory.path_join(path).simplify_path()
	if absolute_path.begins_with(scope_directory):
		var overwrites_protected_path: bool = false
		for _protected_file_path in _protected_file_paths:
			if absolute_path.contains(_protected_file_path):
				overwrites_protected_path = true
				break
		if not overwrites_protected_path:
			_last_error = Error.OK
			return absolute_path
	
	_last_error = Error.ERR_INVALID_PARAMETER
	return ""


## Gets the current game install directory and validates it or sets the error
## field when not configured.
func _get_game_install_directory() -> String:
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
