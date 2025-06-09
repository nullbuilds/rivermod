## Provides the dependency injection configuration for the application.
class_name ApplicationInjectionContext
extends InjectionContext

const _EDITOR_CONFIG_FILE_PATH: String = "user://editor.cfg"

## Configures the provided binder.
func configure_bindings(binder: InjectionBinder) -> void:
	binder.bind(EditorConfigurationSource, _provide_editor_configuration_source)


## Provides an EditorConfigurationSource instance.
func _provide_editor_configuration_source(_injector: Injector) -> EditorConfigurationSource:
	return ConfigFileEditorConfigurationSource.new(_EDITOR_CONFIG_FILE_PATH)
