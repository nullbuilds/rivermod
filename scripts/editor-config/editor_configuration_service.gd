## Service for providing access to editor configurations.
class_name EditorConfigurationService
extends Object

const _EDITOR_CONTEXT: String = "editor"
const _GAME_INSTALL_DIRECTORY_KEY: String = "game_install_directory"

var _editor_configuration_source: EditorConfigurationSource = null
var _loaded: bool = false

## Constructs a new configuration service backed by the provided source.
func _init(editor_configuration_source: EditorConfigurationSource) -> void:
	assert(editor_configuration_source != null,
			"editor_configuration_source must not be null")
	_editor_configuration_source = editor_configuration_source


## Gets the game's install directory or empty if not set.
func get_game_install_directory() -> String:
	return _get_configuration(_EDITOR_CONTEXT, _GAME_INSTALL_DIRECTORY_KEY, "")


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
