class_name SaveDeletePopup
extends PopupPanel
## Popup to confirm if a save should be deleted.

## Emitted when the user confirms the choice to delete a save.
signal delete_confirmed()

@onready var _header_label: Label = %HeaderLabel
@onready var _cancel_button: Button = %CancelButton
@onready var _delete_button: Button = %DeleteButton

## Sets the name of the save to delete.
var save_name: String:
	set(value):
		save_name = value
		_update_visuals.call_deferred()


## Readies the components.
func _ready() -> void:
	_update_visuals()
	_delete_button.pressed.connect(_on_delete_button_pressed)
	_cancel_button.pressed.connect(_on_cancel_button_pressed)


## Updates the popup visuals.
func _update_visuals() -> void:
	_header_label.text = "Delete save \"%s\"?" % save_name


## Confirms the save should be deleted.
func _confirm_delete() -> void:
	delete_confirmed.emit()
	_hide_popup()


## Hides the popup.
func _hide_popup() -> void:
	visible = false


## Called when the delete button is pressed.
func _on_delete_button_pressed() -> void:
	_confirm_delete()


## Called when the cancel button is pressed.
func _on_cancel_button_pressed() -> void:
	_hide_popup()
