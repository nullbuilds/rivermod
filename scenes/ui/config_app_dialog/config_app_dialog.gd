class_name ConfigAppDialog
extends Window
## Dialog to configure the application.

var _injector: Injector = null
var _config_service: EditorConfigurationService = null
@onready var _close_button: Button = %CloseButton
@onready var _save_button: Button = %SaveButton
@onready var _auto_sync_check_button: CheckButton = %AutoSyncCheckButton
@onready var _auto_sync_interval_spin_box: SpinBox = %AutoSyncIntervalSpinBox

## Readies the component.
func _ready() -> void:
	hide()
	force_native = true
	
	_config_service = _injector.provide(EditorConfigurationService)
	
	close_requested.connect(_on_close_pressed)
	focus_entered.connect(_on_focus_entered)
	_close_button.pressed.connect(_on_close_pressed)
	_save_button.pressed.connect(_on_save_pressed)


## Loads the config settings into the UI.
func _load() -> void:
	var automatic_sync_enabled: bool = _config_service.is_automatic_game_save_sync_enabled()
	_auto_sync_check_button.button_pressed = automatic_sync_enabled
	
	var automatic_sync_interval: int = _config_service.get_automatic_game_save_sync_interval()
	_auto_sync_interval_spin_box.value = automatic_sync_interval


## Saves the current UI settings.
func _save() -> void:
	var automatic_sync_enabled: bool = _auto_sync_check_button.button_pressed
	_config_service.set_automatic_game_save_sync_enabled(automatic_sync_enabled)
	
	var automatic_sync_interval: int = int(_auto_sync_interval_spin_box.value)
	_config_service.set_automatic_game_save_sync_interval(automatic_sync_interval)
	
	_config_service.save()


## Called when the user chooses to close the window.
func _on_close_pressed() -> void:
	hide()


## Called when the dialog gets focus.
func _on_focus_entered() -> void:
	_load()


## Called when the user chooses to save the settings.
func _on_save_pressed() -> void:
	_save()
	hide()
