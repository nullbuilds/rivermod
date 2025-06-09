class_name ConfigFileEditorConfigurationSource
extends EditorConfigurationSource
## Obtains editor configuration settings from a file.

var _config_file: ConfigFile = ConfigFile.new()
var _config_file_path: String = ""

## Creates a new configuration source from the given config file.
func _init(config_file_path: String) -> void:
	assert(!config_file_path.is_valid_filename(),
			"config_file_path must be a valid file name; was \"%s\"" % [config_file_path])
	_config_file_path = config_file_path


## Gets the given configuration value or returns the default if not defined.
## 
## When an existing value is not present, the provided default will be set as
## the value going forward unless it too is null.
func get_configuration(context: String, key: String, default: Variant = null) -> Variant:
	var value: Variant = _config_file.get_value(context, key, default)
	
	if value == default:
		set_configuration(context, key, default)
	
	return value


## Sets the specificied configuration key to the given value.
func set_configuration(context: String, key: String, value: Variant) -> void:
	_config_file.set_value(context, key, value)


## Persists the configuration values.
func save() -> void:
	var global_config_path: String = ProjectSettings.globalize_path(_config_file_path)
	
	print("Saving editor configuration to \"%s\"" % [global_config_path])
	var error: Error = _config_file.save(_config_file_path)
	if Error.OK != error:
		printerr("Failed to save editor config file at \"%s\"" % [global_config_path])


## Loads the configuration values overwriting any that conflict.
func reload() -> void:
	var global_config_path: String = ProjectSettings.globalize_path(_config_file_path)
	
	print("Loading editor configuration from \"%s\"" % [global_config_path])
	if not FileAccess.file_exists(_config_file_path):
		print("Unable to load editor configuration; no such file \"%s\"" % [global_config_path])
		return
	
	var error: Error = _config_file.load(_config_file_path)
	if Error.OK != error:
		printerr("Failed to load editor config file at \"%s\"" % [global_config_path])
