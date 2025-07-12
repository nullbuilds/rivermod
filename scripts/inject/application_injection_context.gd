class_name ApplicationInjectionContext
extends InjectionContext
## Provides the dependency injection configuration for the application.

const _EDITOR_CONFIG_FILE_PATH: String = "user://editor.cfg"

## Configures the provided binder.
func configure_bindings(binder: InjectionBinder) -> void:
	binder.bind(EditorConfigurationService, _provide_editor_configuration_service)
	binder.bind(GameFileSource, _provide_game_file_source)
	binder.bind(EditorFileSource, _provide_editor_file_source)
	binder.bind(AsyncSaveManagementService, _provide_async_save_management_service)
	binder.bind(ExternalToolsService, _provide_external_tools_service)


## Provides an AsyncSaveManagementService.
func _provide_async_save_management_service(injector: Injector) -> AsyncSaveManagementService:
	var editor_file_source: EditorFileSource = injector.provide(EditorFileSource)
	var save_archive: SaveArchiveRepository = FileSystemSaveArchiveRepository.new(editor_file_source)
	
	var game_file_source: GameFileSource = injector.provide(GameFileSource)
	var game_save_repo: GameSaveDataRepository = GameFileSourceSaveDataRepository.new(game_file_source)
	
	var save_management_service: SaveManagementService = SaveManagementService.new(save_archive, game_save_repo)
	
	var config_service: EditorConfigurationService = injector.provide(EditorConfigurationService)
	
	return AsyncSaveManagementService.new(save_management_service, config_service)


## Provides an EditorFileSource.
func _provide_editor_file_source(injector: Injector) -> EditorFileSource:
	var protected_file_paths: PackedStringArray = PackedStringArray()
	protected_file_paths.append(_EDITOR_CONFIG_FILE_PATH)
	protected_file_paths.append("logs")
	protected_file_paths.append("shader_cache")
	protected_file_paths.append("vulkan")
	
	var config_service: EditorConfigurationService = injector.provide(EditorConfigurationService)
	
	return FileSystemEditorFileSource.new(config_service, protected_file_paths)


## Provides a GameFileSource instance.
func _provide_game_file_source(injector: Injector) -> GameFileSource:
	var config_service: EditorConfigurationService = injector.provide(EditorConfigurationService)
	return InstallationGameFileSource.new(config_service)


## Provides an EditorConfigurationService instance.
func _provide_editor_configuration_service(_injector: Injector) -> EditorConfigurationService:
	var config_source: EditorConfigurationSource = ConfigFileEditorConfigurationSource.new(_EDITOR_CONFIG_FILE_PATH)
	return EditorConfigurationService.new(config_source)


## Provides a ExternalToolsService instance.
func _provide_external_tools_service(injector: Injector) -> ExternalToolsService:
	var config_service: EditorConfigurationService = injector.provide(EditorConfigurationService)
	return ExternalToolsService.new(config_service)
