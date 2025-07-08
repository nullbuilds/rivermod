class_name EditorConfigurationSource
extends Object
## Abstract source for editor configuration settings.

## Gets the given configuration value or returns the default if not defined.
## 
## When an existing value is not present, the provided default will be set as
## the value going forward unless it too is null.
@warning_ignore("unused_parameter")
func get_configuration(context: String, key: String, default: Variant = null) -> Variant:
	assert(false, "Not implemented")
	return null


## Sets the specificied configuration key to the given value.
@warning_ignore("unused_parameter")
func set_configuration(context: String, key: String, value: Variant) -> void:
	assert(false, "Not implemented")


## Persists the configuration values.
func save() -> void:
	assert(false, "Not implemented")


## Loads the configuration values overwriting any that conflict.
func reload() -> void:
	assert(false, "Not implemented")
