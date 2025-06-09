class_name ApplicationInjectionContext
extends InjectionContext
## Provides the dependency injection configuration for the application.

const _EDITOR_CONFIG_FILE_PATH: String = "user://editor.cfg"

## Configures the provided binder.
func configure_bindings(binder: InjectionBinder) -> void:
	binder.bind(EditorConfigurationSource, _provide_editor_configuration_source)
	binder.bind(EditorConfigurationService, _provide_editor_configuration_service)


## Provides an EditorConfigurationService instance.
func _provide_editor_configuration_service(injector: Injector) -> EditorConfigurationService:
	return EditorConfigurationService.new(injector.provide(EditorConfigurationSource))


## Provides an EditorConfigurationSource instance.
func _provide_editor_configuration_source(_injector: Injector) -> EditorConfigurationSource:
	return ConfigFileEditorConfigurationSource.new(_EDITOR_CONFIG_FILE_PATH)
