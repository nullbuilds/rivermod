class_name FileSystemSaveArchiveRepository
extends SaveArchiveRepository
## Save archive implemented using the file system. Thread safe.

const _SAVE_MANIFEST_FILE_NAME: String = "save.json"
const _MAP_FILE_NAME: String = "MAP.SAV"
const _DATA_FILE_NAME: String = "RIVER.SAV"
const _SAVES_DIRECTORY: String = "saves"
const _SAVE_ARCHIVE_SCOPE: EditorFileSource.EditorFileScope = EditorFileSource.EditorFileScope.GLOBAL

var _hasher: Script = preload("res://scripts/hashing/Hasher.cs")
var _last_error: Error = Error.OK
var _editor_file_source: EditorFileSource = null
var _mutex: Mutex = Mutex.new()

## Constructs a new archive repository.
func _init(editor_file_source: EditorFileSource) -> void:
	assert(editor_file_source != null, "editor_file_source must not be null")
	_editor_file_source = editor_file_source


## Gets the status of the last operation.
func get_error() -> Error:
	return _last_error


## Archives the given save data and returns its manifest.
func archive(save_data: GameSaveData) -> SaveArchiveManifest:
	assert(save_data != null, "save_data must not be null")
	
	_mutex.lock()
	var manifest: SaveArchiveManifest = _create_manifest(save_data)
	if _last_error != Error.OK:
		return null
	
	var save_directory: String = _get_save_directory(manifest.get_id())
	
	# Write manifest
	var manifest_file: String = save_directory.path_join(_SAVE_MANIFEST_FILE_NAME)
	if _editor_file_source.exists(_SAVE_ARCHIVE_SCOPE, manifest_file):
		# Load the existing manifest
		manifest = _load_manifest(manifest_file)
		if _last_error != Error.OK:
			_mutex.unlock()
			return null
		_mutex.unlock()
		return manifest
	
	_last_error = _editor_file_source.write_file(_SAVE_ARCHIVE_SCOPE, \
			manifest_file, manifest.serialize().to_ascii_buffer())
	if _last_error != Error.OK:
		_mutex.unlock()
		return null
	
	# Write map data
	var map_file: String = save_directory.path_join(_MAP_FILE_NAME)
	_last_error = _editor_file_source.write_file(_SAVE_ARCHIVE_SCOPE, \
			map_file, save_data.get_map_bytes())
	if _last_error != Error.OK:
		_mutex.unlock()
		return null
	
	# Write save data
	var data_file: String = save_directory.path_join(_DATA_FILE_NAME)
	_last_error = _editor_file_source.write_file(_SAVE_ARCHIVE_SCOPE, \
			data_file, save_data.get_data_bytes())
	if _last_error != Error.OK:
		_mutex.unlock()
		return null
	
	_mutex.unlock()
	return manifest


## Get the manifests of all archived saves.
func get_archived_saves() -> Array[SaveArchiveManifest]:
	_mutex.lock()
	var directories: PackedStringArray = _editor_file_source.get_directories(
			_SAVE_ARCHIVE_SCOPE, _SAVES_DIRECTORY)
	_last_error = _editor_file_source.get_error()
	if _last_error != Error.OK:
		_mutex.unlock()
		return []
	
	var manifests: Array[SaveArchiveManifest] = []
	for directory in directories:
		var save_directory: String = _get_save_directory(directory)
		var manifest_file: String = save_directory.path_join(
				_SAVE_MANIFEST_FILE_NAME)
		var manifest: SaveArchiveManifest = _load_manifest(manifest_file)
		if _last_error != Error.OK:
			_mutex.unlock()
			return []
		manifests.append(manifest)
	
	_mutex.unlock()
	return manifests


## Gets the save data for the given id.
func get_archived_save_data(id: String) -> GameSaveData:
	assert(id != null, "id must not be null")
	
	_mutex.lock()
	var save_directory: String = _get_save_directory(id)
	
	# Read last modified data from manifest
	var manifest_file: String = save_directory.path_join(_SAVE_MANIFEST_FILE_NAME)
	var manifest: SaveArchiveManifest = _load_manifest(manifest_file)
	if _last_error != Error.OK:
		_mutex.unlock()
		return null
	var last_modified_time: int = manifest.get_created_at_timestamp()
	
	# Get map data
	var map_file: String = save_directory.path_join(_MAP_FILE_NAME)
	var map_bytes: PackedByteArray = _editor_file_source.read_file(
			_SAVE_ARCHIVE_SCOPE, map_file)
	_last_error = _editor_file_source.get_error()
	if _last_error != Error.OK:
		_mutex.unlock()
		return null
	
	# Get save data
	var data_file: String = save_directory.path_join(_DATA_FILE_NAME)
	var data_bytes: PackedByteArray = _editor_file_source.read_file(
			_SAVE_ARCHIVE_SCOPE, data_file)
	if _last_error != Error.OK:
		_mutex.unlock()
		return null
	
	_mutex.unlock()
	return GameSaveData.new(last_modified_time, map_bytes, data_bytes)


## Deletes the save with the given id.
func delete_save(id: String) -> Error:
	assert(id != null, "id must not be null")
	
	if id.is_empty():
		_last_error = Error.ERR_DOES_NOT_EXIST
		return _last_error
	
	_mutex.lock()
	var save_directory: String = _get_save_directory(id)
	_last_error = _editor_file_source.delete_file(_SAVE_ARCHIVE_SCOPE, \
			save_directory)
	_mutex.unlock()
	return _last_error


## Loads a save archive manifesrt from a JSON file.
func _load_manifest(manifest_path: String) -> SaveArchiveManifest:
	var json: PackedByteArray = _editor_file_source.read_file(
			_SAVE_ARCHIVE_SCOPE, manifest_path)
	_last_error = _editor_file_source.get_error()
	if _last_error != Error.OK:
		return null
	
	return SaveArchiveManifest.deserialize(json.get_string_from_ascii())


## Creates a save manifest from the given save data.
func _create_manifest(save_data: GameSaveData) -> SaveArchiveManifest:
	var id: String = _get_save_id(save_data)
	var created_at_timestamp: int = save_data.get_last_modified_time()
	var utf_offset_minutes: int = Time.get_time_zone_from_system().bias
	
	var parse_context: ParseContext = ParseContext.from_bytes(save_data.get_data_bytes())
	var save_name: String = SaveDataModel.parse(parse_context).get_save_name()
	
	var had_error: bool = false
	for event in parse_context.get_events():
		var level: ParseContext.ContextEvent.Level = event.get_level()
		var level_string : String = ParseContext.ContextEvent.Level.keys()[level]
		printerr("[%s] Save data parser - %s" % [level_string, event.get_message()])
		if event.get_level() == ParseContext.ContextEvent.Level.ERROR:
			had_error = true
	
	if had_error:
		_last_error = Error.ERR_FILE_CORRUPT
		return null
	
	return SaveArchiveManifest.new(id, save_name, created_at_timestamp,
			utf_offset_minutes)


## Computes the unique id for the given save data.
func _get_save_id(save_data: GameSaveData) -> String:
	var joined_bytes: PackedByteArray = []
	joined_bytes.append_array(save_data.get_map_bytes())
	joined_bytes.append_array(save_data.get_data_bytes())
	return _hasher.Hash(joined_bytes)


## Returns the directory path for a given save id.
func _get_save_directory(id: String) -> String:
	return _SAVES_DIRECTORY.path_join(id)
