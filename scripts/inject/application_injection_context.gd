class_name ApplicationInjectionContext
extends InjectionContext
## Provides the dependency injection configuration for the application.

const _EDITOR_CONFIG_FILE_PATH: String = "user://editor.cfg"

## Configures the provided binder.
func configure_bindings(binder: InjectionBinder) -> void:
	binder.bind(EditorConfigurationSource, _provide_editor_configuration_source)
	binder.bind(EditorConfigurationService, _provide_editor_configuration_service)
	binder.bind(GameFileSource, _provide_game_file_source)
	binder.bind(GameSaveDataRepository, _provide_game_save_data_repository)
	binder.bind(EditorFileSource, _provide_editor_file_source)


## Provides an EditorFileSource
func _provide_editor_file_source(injector: Injector) -> EditorFileSource:
	var protected_file_paths: PackedStringArray = PackedStringArray()
	protected_file_paths.append(_EDITOR_CONFIG_FILE_PATH)
	protected_file_paths.append("logs")
	protected_file_paths.append("shader_cache")
	protected_file_paths.append("vulkan")
	
	return FileSystemEditorFileSource.new(injector.provide(EditorConfigurationService),
			protected_file_paths)


## Provides a GameSaveDataRepository
func _provide_game_save_data_repository(injector: Injector) -> GameSaveDataRepository:
	return GameFileSourceSaveDataRepository.new(injector.provide(GameFileSource))


## Provides a GameFileSource instance.
func _provide_game_file_source(injector: Injector) -> GameFileSource:
	return InstallationGameFileSource.new(injector.provide(EditorConfigurationService))


## Provides an EditorConfigurationService instance.
func _provide_editor_configuration_service(injector: Injector) -> EditorConfigurationService:
	return EditorConfigurationService.new(injector.provide(EditorConfigurationSource))


## Provides an EditorConfigurationSource instance.
func _provide_editor_configuration_source(_injector: Injector) -> EditorConfigurationSource:
	return ConfigFileEditorConfigurationSource.new(_EDITOR_CONFIG_FILE_PATH)
