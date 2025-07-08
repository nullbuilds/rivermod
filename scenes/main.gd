class_name Main
extends Node
## The editor main scnee.

const _DOCUMENTATION_URL: String = "https://github.com/nullbuilds/rivermod/wiki"

var _injector: Injector = null
var _config_service: EditorConfigurationService = null
var _save_manager: AsyncSaveManagementService = null
var _game_file_source: GameFileSource = null
@onready var _content_container: MarginContainer = %ContentContainer
@onready var _main_menu_bar: MainMenuBar = %MainMenuBar
@onready var _save_manager_scene: PackedScene = preload("res://scenes/ui/save_manager/save_management_widget.tscn")

## Construct the main scene.
func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	
	_main_menu_bar.editor_game_directory_pressed.connect(_on_change_game_directory_pressed)
	_main_menu_bar.editor_help_documentation_pressed.connect(_on_open_editor_help_documentation)
	
	_injector = Injector.create(ApplicationInjectionContext.new())
	_config_service = _injector.provide(EditorConfigurationService)
	_save_manager = _injector.provide(AsyncSaveManagementService)
	_game_file_source = _injector.provide(GameFileSource)
	
	# Start services
	_start_services()
	
	# Construct UI
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


## Opens the online help documentation.
func _open_help_documentation() -> void:
	OS.shell_open(_DOCUMENTATION_URL)


## Prompts the user to select a new game directory.
func _prompt_for_new_game_directory() -> void:
	get_tree().paused = true
	DisplayServer.file_dialog_show("Select game directory", "%HOMEDRIVE%", "",
			true, DisplayServer.FILE_DIALOG_MODE_OPEN_DIR, [],
			_on_game_directory_selected)


## Informs the user their selected game directory is invalid.
func _show_invalid_game_directory_dialog() -> void:
	DisplayServer.dialog_show("Invalid game directory",
			"Please select the root directory of your Riverworld " + \
			"installation (the directory containing the game executables).",
			["Ok"], _on_invalid_game_directory_dialog_dismissed)


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


## Called when the user requests to change the game directory
func _on_change_game_directory_pressed() -> void:
	_prompt_for_new_game_directory()


## Called when the user requests to view the editor help documentation.
func _on_open_editor_help_documentation() -> void:
	_open_help_documentation()


## Called when the user selects a new game directory.
func _on_game_directory_selected(status: bool,
		selected_paths: PackedStringArray, _selected_filter_index: int) -> void:
	var path: String = ""
	if status and not selected_paths.is_empty():
		path = selected_paths.get(0)
	
	_update_game_directory(path)


## Called when the user dismisses the invalid game directory dialog.
func _on_invalid_game_directory_dialog_dismissed(_selection: int) -> void:
	_prompt_for_new_game_directory()
