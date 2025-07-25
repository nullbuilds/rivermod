class_name Main
extends Node
## The editor main scnee.

var _injector: Injector = null
var _config_service: EditorConfigurationService = null
var _save_manager: AsyncSaveManagementService = null
var _game_file_source: GameFileSource = null
var _config_app_dialog: ConfigAppDialog = null
var _external_tools_service: ExternalToolsService = null
@onready var _content_container: MarginContainer = %ContentContainer
@onready var _main_menu_bar: MainMenuBar = %MainMenuBar
@onready var _about_app_dialog: AboutAppDialog = %AboutAppDialog
@onready var _invalid_game_directory_dialog: InvalidGameDirectoryDialog = %InvalidGameDirectoryDialog
@onready var _config_app_dialog_scene: PackedScene = preload("res://scenes/ui/config_app_dialog/config_app_dialog.tscn")
@onready var _save_manager_scene: PackedScene = preload("res://scenes/ui/save_manager/save_management_widget.tscn")

## Construct the main scene.
func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	
	# Setup signals
	_main_menu_bar.editor_game_directory_pressed.connect(_on_change_game_directory_pressed)
	_main_menu_bar.editor_help_documentation_pressed.connect(_on_open_editor_help_documentation_pressed)
	_main_menu_bar.modding_resources_pressed.connect(_on_open_modding_resources_pressed)
	_main_menu_bar.about_pressed.connect(_on_about_pressed)
	_main_menu_bar.editor_configure_pressed.connect(_on_configure_pressed)
	_main_menu_bar.map_viewer_pressed.connect(_on_map_viewer_pressed)
	_main_menu_bar.model_viewer_pressed.connect(_on_model_viewer_pressed)
	_invalid_game_directory_dialog.dismissed.connect(_on_invalid_game_directory_dialog_dismissed)
	
	# Setup dependency injection
	_injector = Injector.create(ApplicationInjectionContext.new())
	_config_service = _injector.provide(EditorConfigurationService)
	_save_manager = _injector.provide(AsyncSaveManagementService)
	_game_file_source = _injector.provide(GameFileSource)
	_external_tools_service = _injector.provide(ExternalToolsService)
	_config_app_dialog = _injector.provide_scene(_config_app_dialog_scene)
	
	# Start services
	_start_services()
	
	# Construct UI
	add_child(_config_app_dialog)
	_content_container.add_child(_injector.provide_scene(_save_manager_scene))


## Updates the editor to ensure a game directory is always set.
func _process(_delta: float) -> void:
	# Verify a game directory has been selected.
	if _config_service.get_game_install_directory().is_empty():
		_prompt_for_new_game_directory()


## Handles incoming notifications.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_close_application(0)


## Close the application and return the given exit code.
func _close_application(exit_code: int) -> void:
	_stop_services()
	
	get_tree().quit(exit_code)


## Cleans-up the services before leaving the scene.
func _exit_tree() -> void:
	# Failing to do this will cause the application to get stuck forever waiting
	# for background threads if you attempt to exit after reloading the scene
	# tree.
	_stop_services()


## Starts the required services.
func _start_services() -> void:
	_save_manager.start()


## Stops running services.
func _stop_services() -> void:
	_save_manager.stop()
	_external_tools_service.stop()


## Opens the online editor help documentation.
func _open_help_documentation() -> void:
	OS.shell_open(ProjectSettings.get_setting("rivermod/help_link"))


## Opens the online modding resources.
func _open_modding_resources() -> void:
	OS.shell_open(ProjectSettings.get_setting("rivermod/modding_resources_link"))


## Shows a popup about the editor.
func _show_about_details() -> void:
	_about_app_dialog.show()


## Shows a dialog to configure the editor.
func _show_configure_dialog() -> void:
	_config_app_dialog.show()


## Prompts the user to select a new game directory.
func _prompt_for_new_game_directory() -> void:
	get_tree().paused = true
	DisplayServer.file_dialog_show("Select game directory", "%HOMEDRIVE%", "",
			true, DisplayServer.FILE_DIALOG_MODE_OPEN_DIR, [],
			_on_game_directory_selected)


## Informs the user their selected game directory is invalid.
func _show_invalid_game_directory_dialog() -> void:
	_invalid_game_directory_dialog.show()


## Updates the game directory to the given user-provided value.
func _update_game_directory(new_directory: String) -> void:
	if not new_directory.is_empty():
		if _game_file_source.is_install_directory(new_directory):
			_config_service.set_game_install_directory(new_directory)
			_config_service.save()
			
			get_tree().paused = false
			get_tree().reload_current_scene.call_deferred()
		else:
			_show_invalid_game_directory_dialog()
	else:
		get_tree().paused = false


## Launches the map viewer.
func _launch_map_viewer() -> void:
	_external_tools_service.launch_map_viewer()


## Launches the map viewer.
func _launch_model_viewer() -> void:
	_external_tools_service.launch_model_viewer()


## Called when the user requests to change the game directory
func _on_change_game_directory_pressed() -> void:
	_prompt_for_new_game_directory()


## Called when the user requests to view the editor help documentation.
func _on_open_editor_help_documentation_pressed() -> void:
	_open_help_documentation()


## Called when the user requests to view the modding resources.
func _on_open_modding_resources_pressed() -> void:
	_open_modding_resources()


## Called when the user requests to view the app's information.
func _on_about_pressed() -> void:
	_show_about_details()


## Called when the user requests to configure the application.
func _on_configure_pressed() -> void:
	_show_configure_dialog()


## Called when the user selects a new game directory.
func _on_game_directory_selected(status: bool,
		selected_paths: PackedStringArray, _selected_filter_index: int) -> void:
	var path: String = ""
	if status and not selected_paths.is_empty():
		path = selected_paths.get(0)
	
	_update_game_directory(path)


## Called when the user dismisses the invalid game directory dialog.
func _on_invalid_game_directory_dialog_dismissed() -> void:
	_prompt_for_new_game_directory()


## Called when the user chooses to open the map viewer.
func _on_map_viewer_pressed() -> void:
	_launch_map_viewer()


## Called when the user chooses to open the model viewer.
func _on_model_viewer_pressed() -> void:
	_launch_model_viewer()
