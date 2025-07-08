class_name SaveGameCard
extends MarginContainer
## A UI card for a game save.

## Emitted when the card's menu button is pressed.
signal menu_button_pressed()

@onready var _save_name_label: Label = %SaveNameLabel
@onready var _save_date_label: Label = %SaveDateLabel
@onready var _menu_button: Button = %MenuButton
@onready var _empty_label: Label = %EmptyLabel
@onready var _content_container: VBoxContainer = %ContentContainer

## Sets the save to display.
var save: SaveArchiveManifest:
	set(value):
		save = value
		_update_visuals.call_deferred()


## Readies the component.
func _ready() -> void:
	_update_visuals()
	_menu_button.pressed.connect(_on_menu_button_pressed)


## Updates the card visuals.
func _update_visuals() -> void:
	var is_empty: bool = save == null
	
	var save_name: String = ""
	var save_date: String = ""
	
	if not is_empty:
		save_name = save.get_save_display_name()
		save_date = save.get_save_date()
	
	_save_name_label.text = save_name
	_save_date_label.text = save_date
	
	_empty_label.visible = is_empty
	_content_container.visible = !is_empty


## Called when the menu button is pressed.
func _on_menu_button_pressed() -> void:
	menu_button_pressed.emit()
