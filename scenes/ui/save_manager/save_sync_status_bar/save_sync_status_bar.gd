class_name SaveSyncStatusBar
extends MarginContainer
## Status bar for displaying the current save sync status.

## Emitted when the sync button is pressed.
signal sync_pressed()

@onready var _save_sync_status_indicator: SaveSyncStatusIndicator = %SaveSyncStatusIndicator
@onready var _save_sync_now_button: Button = %SaveSyncNowButton

## Readies the component.
func _ready() -> void:
	_save_sync_now_button.pressed.connect(_on_pressed)

## Updates the sync status.
func update_status(last_sync_time: int, sync_status: AsyncSaveManagementService.SyncStatus) -> void:
	_save_sync_status_indicator.set_status(sync_status, last_sync_time)


## Called when the sync button is pressed.
func _on_pressed() -> void:
	sync_pressed.emit()
