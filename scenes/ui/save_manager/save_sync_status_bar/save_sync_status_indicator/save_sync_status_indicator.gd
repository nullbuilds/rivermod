class_name SaveSyncStatusIndicator
extends MarginContainer
## UI component for displaying the current game save sync status.

@onready var _status_label: Label = %StatusLabel

## Readies the component.
func _ready() -> void:
	set_status(AsyncSaveManagementService.SyncStatus.DESYNCHRONIZED, -1)


## Sets the sync status.
func set_status(status: AsyncSaveManagementService.SyncStatus,
		last_sync_time: int) -> void:
	
	var utc_offset: int = Time.get_time_zone_from_system().bias
	var date_string: String = TimeUtils.get_local_time(last_sync_time,
			utc_offset)
	
	match(status):
		AsyncSaveManagementService.SyncStatus.STOPPED:
			_status_label.text = "SYNCED AT %s" % date_string
		AsyncSaveManagementService.SyncStatus.SYNCHRONIZED:
			_status_label.text = "SYNCED AT %s" % date_string
		AsyncSaveManagementService.SyncStatus.DESYNCHRONIZED:
			_status_label.text = "SYNCHRONIZING SAVES"
		AsyncSaveManagementService.SyncStatus.FAILED:
			_status_label.text = "FAILED TO SYNC SAVES!"
		_:
			_status_label.text = "UNKNOWN SYNC STATUS"
