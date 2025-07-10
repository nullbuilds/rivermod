class_name AboutAppDialog
extends Window
## Dialog window for showing editor details.

@onready var _close_button: Button = %CloseButton
@onready var _version_label: RichTextLabel = %VersionLabel
@onready var _copyright_label: RichTextLabel = %CopyrightLabel
@onready var _credits_label: RichTextLabel = %CreditsLabel

## Readies the component.
func _ready() -> void:
	hide()
	force_native = true
	
	var version: String = ProjectSettings.get_setting("application/config/version", "<unknown>")
	var github_link: String = ProjectSettings.get_setting("rivermod/github_link")
	var copyright: String = ProjectSettings.get_setting("rivermod/copyright")
	var author_link: String = ProjectSettings.get_setting("rivermod/author_link")
	var usage_credits: PackedStringArray = ProjectSettings.get_setting("rivermod/usage_credits")
	
	_version_label.text = "Rivermod v%s\nHomepage: %s" % [version, github_link]
	_copyright_label.text = "© %s\nHomepage: %s" % [copyright, author_link]
	_credits_label.text = "Uses:"
	for credit in usage_credits:
		_credits_label.text += "\n* %s" % credit
	
	close_requested.connect(_on_close_pressed)
	_close_button.pressed.connect(_on_close_pressed)


## Called when the user chooses to close the window.
func _on_close_pressed() -> void:
	hide()
