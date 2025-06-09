## Abstract source for editor configuration settings.
class_name EditorConfigurationSource
extends Object

## Gets the given configuration value or returns the default if not defined.
## 
## When an existing value is not present, the provided default will be set as
## the value going forward unless it too is null.
func get_configuration(_context: String, _key: String, _default: Variant = null) -> Variant:
	assert(false, "Not implemented")
	return null


## Sets the specificied configuration key to the given value.
func set_configuration(_context: String, _key: String, _value: Variant) -> void:
	assert(false, "Not implemented")


## Persists the configuration values.
func save() -> void:
	assert(false, "Not implemented")


## Loads the configuration values overwriting any that conflict.
func reload() -> void:
	assert(false, "Not implemented")
