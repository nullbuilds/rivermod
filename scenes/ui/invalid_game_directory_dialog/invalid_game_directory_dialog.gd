class_name InvalidGameDirectoryDialog
extends Window
## Dialog shown when the user selects an invalid game directory.

## Emitted when the dialog is dismissed.
signal dismissed()

@onready var _okay_button: Button = %OkayButton

## Readies the component.
func _ready() -> void:
	hide()
	force_native = true

	close_requested.connect(_on_ok_pressed)
	_okay_button.pressed.connect(_on_ok_pressed)


## Called when the user chooses to dismiss the window.
func _on_ok_pressed() -> void:
	print("huh?")
	hide()
	dismissed.emit()
