class_name MainMenuBar
extends MarginContainer
## The editor's main menu bar.

## Emitted when the user selects the help documentation option.
signal editor_help_documentation_pressed()

## Emitted when the user selects the editor configuration option.
signal editor_configure_pressed()

## Emitted when the user chooses the option to change the game directory.
signal editor_game_directory_pressed()

## Emitted when the user selects the modding resources option.
signal modding_resources_pressed()

## Emitted when the user selects the about option.
signal about_pressed()

## Emitted when the user chooses to open the map viewer.
signal map_viewer_pressed()

## Emitted when the user chooses to open the model viewer.
signal model_viewer_pressed()

const _EDITOR_GAME_DIRECTORY_ID: int = 0
const _EDITOR_CONFIGURE_ID: int = 1
const _TOOL_MAP_VIEWER: int = 0
const _TOOL_MODEL_VIEWER: int = 1
const _HELP_DOCUMENTATION_ID: int = 0
const _HELP_MODDING_RESOURCES_ID: int = 1
const _HELP_ABOUT_ID: int = 2

@onready var _editor_popup_menu: PopupMenu = %EditorPopupMenu
@onready var _tools_popup_menu: PopupMenu = %ToolsPopupMenu
@onready var _help_popup_menu: PopupMenu = %HelpPopupMenu

## Readies the component.
func _ready() -> void:
	_editor_popup_menu.id_pressed.connect(_on_editor_id_pressed)
	_tools_popup_menu.id_pressed.connect(_on_tools_id_pressed)
	_help_popup_menu.id_pressed.connect(_on_help_id_pressed)


## Called when an editor menu item is pressed.
func _on_editor_id_pressed(id: int) -> void:
	match(id):
		_EDITOR_GAME_DIRECTORY_ID:
			editor_game_directory_pressed.emit()
		_EDITOR_CONFIGURE_ID:
			editor_configure_pressed.emit()


## Called when a tools menu item is pressed.
func _on_tools_id_pressed(id: int) -> void:
	match(id):
		_TOOL_MAP_VIEWER:
			map_viewer_pressed.emit()
		_TOOL_MODEL_VIEWER:
			model_viewer_pressed.emit()


## Called when a help menu item is pressed.
func _on_help_id_pressed(id: int) -> void:
	match(id):
		_HELP_DOCUMENTATION_ID:
			editor_help_documentation_pressed.emit()
		_HELP_MODDING_RESOURCES_ID:
			modding_resources_pressed.emit()
		_HELP_ABOUT_ID:
			about_pressed.emit()
