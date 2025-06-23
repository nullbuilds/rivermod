class_name EditorConfigurationService
extends Object
## Service for providing access to editor configurations.

const _EDITOR_CONTEXT: String = "editor"
const _SAVE_MANAGER_CONTEXT: String = "save_manager"
const _GAME_INSTALL_DIRECTORY_KEY: String = "game_install_directory"
const _AUTOMATIC_GAME_SAVE_SYNC_INTERVAL_KEY: String = "automatic_game_save_sync_interval"
const _AUTOMATIC_GAME_SAVE_SYNC_ENABLED_KEY: String = "automatic_game_save_sync_enabled"
const _EDITOR_GAME_DIRECTORY: String =  ".rivermod"

var _editor_configuration_source: EditorConfigurationSource = null
var _loaded: bool = false

## Constructs a new configuration service backed by the provided source.
func _init(editor_configuration_source: EditorConfigurationSource) -> void:
	assert(editor_configuration_source != null,
			"editor_configuration_source must not be null")
	_editor_configuration_source = editor_configuration_source


## Gets the game's install directory or empty if not set.
func get_game_install_directory() -> String:
	return _get_configuration(_EDITOR_CONTEXT, _GAME_INSTALL_DIRECTORY_KEY, "").simplify_path()


## Returns the name of the editor's own directory in a game installation.
func get_game_install_editor_directory() -> String:
	return _EDITOR_GAME_DIRECTORY


## Returns the default interval in milliseconds between automatic game save syncs.
func get_automatic_game_save_sync_interval() -> int:
	return _get_configuration(_SAVE_MANAGER_CONTEXT, _AUTOMATIC_GAME_SAVE_SYNC_INTERVAL_KEY, 200)


## Returns whether automatic game save sync'ing is enabled.
func is_automatic_game_save_sync_enabled() -> bool:
	return _get_configuration(_SAVE_MANAGER_CONTEXT, _AUTOMATIC_GAME_SAVE_SYNC_ENABLED_KEY, true)


## Sets whether automatic game save syncs are enabled.
func set_automatic_game_save_sync_enabled(enabled: bool) -> void:
	_set_configuration(_SAVE_MANAGER_CONTEXT, _AUTOMATIC_GAME_SAVE_SYNC_ENABLED_KEY, enabled)


## Sets the automatic game save sync interval in milliseconds.
func set_automatic_game_save_sync_interval(interval: int) -> void:
	var adjusted_interval: int = max(interval, 0)
	_set_configuration(_SAVE_MANAGER_CONTEXT, _AUTOMATIC_GAME_SAVE_SYNC_INTERVAL_KEY, adjusted_interval)


## Sets the game's install directory.
func set_game_install_directory(directory: String) -> void:
	_set_configuration(_EDITOR_CONTEXT, _GAME_INSTALL_DIRECTORY_KEY, directory)


## Saves the editor configuration.
func save() -> void:
	_editor_configuration_source.save()


## Loads the given configuration or sets the new default if not defined.
func _get_configuration(context: String, key: String, default: Variant = null) -> Variant:
	_load_configuration()
	return _editor_configuration_source.get_configuration(context, key, default)


## Sets the given configuration, overwriting any previously set value.
func _set_configuration(context: String, key: String, value: Variant) -> void:
	_load_configuration()
	_editor_configuration_source.set_configuration(context, key, value)


## Loads the underlying configuration if it hasn't been loaded already.
func _load_configuration() -> void:
	if not _loaded:
		_editor_configuration_source.reload()
		_loaded = true
