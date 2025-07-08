class_name AsyncSaveManagementService
extends Object
## Wrapper for the SaveManagementService which performs save management
## operations asynchronously.

## Emitted when the sync status changes.
signal sync_status_changed(status: SyncStatus, last_sync_time: int)

## Emitted when the save assigned to a slot changes.
signal slot_save_changed(slot: int, save: SaveArchiveManifest)

## Emitted when a new save is added.
signal save_added(save: SaveArchiveManifest)

## Emitted when a save is removed.
signal save_removed(save_id: String)

## Indicates the current sync status for the saves.
enum SyncStatus {
	STOPPED,        ## Synchronization is not currently occurring
	SYNCHRONIZED,   ## All saves have been synchronized
	DESYNCHRONIZED, ## Saves have not yet been synchronized
	FAILED          ## One or more sync operations failed
}

const _SYNCHRONIZER_LOOP_DELAY_MILLIS: int = 100
const _INVALID_TASK_ID: int = -1
const _TASK_DESCRIPTION: String = "Save game synchronizer"

var _save_management_service: SaveManagementService = null
var _editor_config_service: EditorConfigurationService = null
var _synchronizer_mutex: Mutex = Mutex.new()
var _pending_operations: Array[Callable] = []
var _pending_operations_mutex: Mutex = Mutex.new()
var _scheduler_mutex: Mutex = Mutex.new()
var _terminate_thread: bool = false
var _last_sync_time: int = -1
var _last_sync_attempt_time: int = -1
var _task_id: int = -1

## Constructs a new async save management service.
func _init(save_management_service: SaveManagementService,
		editor_config_service: EditorConfigurationService) -> void:
	assert(save_management_service != null, "save_management_service must not be null")
	assert(editor_config_service != null, "editor_config_service must not be null")
	
	_save_management_service = save_management_service
	_editor_config_service = editor_config_service
	
	_save_management_service.slot_save_changed.connect(_on_slot_save_changed)
	_save_management_service.save_added.connect(_on_save_added)
	_save_management_service.save_removed.connect(_on_save_removed)


## Starts the synchronizer.
func start() -> void:
	_scheduler_mutex.lock()
	
	if _task_id == _INVALID_TASK_ID:
		_synchronizer_mutex.lock()
		_terminate_thread = false
		_synchronizer_mutex.unlock()
		
		_task_id = WorkerThreadPool.add_task(_synchronizer_thread, true, _TASK_DESCRIPTION)
	
	_scheduler_mutex.unlock()


## Stops the synchronizer and terminates background threads.
func stop() -> void:
	_scheduler_mutex.lock()
	
	if _task_id != _INVALID_TASK_ID:
		_synchronizer_mutex.lock()
		_terminate_thread = true
		_synchronizer_mutex.unlock()
	
		WorkerThreadPool.wait_for_task_completion(_task_id)
		_task_id = _INVALID_TASK_ID
	
	_scheduler_mutex.unlock()


## Returns the save in each populated save slot at the time of the last sync.
func get_slot_saves() -> Dictionary[int, SaveArchiveManifest]:
	_synchronizer_mutex.lock()
	var slots: Dictionary[int, SaveArchiveManifest] = _save_management_service.get_slot_saves()
	_synchronizer_mutex.unlock()
	return slots


## Returns the details of each archived save at the time of the last
## save sync.
func get_archived_saves() -> Array[SaveArchiveManifest]:
	_synchronizer_mutex.lock()
	var saves: Array[SaveArchiveManifest] = _save_management_service.get_archived_saves()
	_synchronizer_mutex.unlock()
	return saves


## Returns the manifest for a save with the given id.
func get_archived_save(save_id: String) -> SaveArchiveManifest:
	_synchronizer_mutex.lock()
	var save: SaveArchiveManifest = _save_management_service.get_archived_save(save_id)
	_synchronizer_mutex.unlock()
	return save


## Triggers a manual sync.
## 
## Will be applied asynchronously.
func synchronize() -> void:
	var operation: Callable = _save_management_service.synchronize
	_queue_operation(operation)


## Assigns a save to a slot.
## 
## Will be applied asynchronously.
func assign_save_to_slot(slot: int, save_id: String) -> void:
	assert(slot >= 0 and slot < GameSaveDataRepository.SAVE_SLOTS,
			"slot must be in the range [0, %d]" % GameSaveDataRepository.SAVE_SLOTS)
	assert(save_id != null, "save_id must not be null")
	var operation: Callable = _save_management_service.assign_save_to_slot.bind(slot, save_id)
	_queue_operation(operation)


## Deletes a save.
## 
## Will be applied asynchronously.
func delete_save(save_id: String) -> void:
	assert(save_id != null, "save_id must not be null")
	assert(!save_id.is_empty(), "save_id must not be empty")
	var operation: Callable = _save_management_service.delete_save.bind(save_id)
	_queue_operation(operation)


## Main method for synchronizer thread.
func _synchronizer_thread() -> void:
	while true:
		_synchronizer_mutex.lock()
		
		if _terminate_thread:
			sync_status_changed.emit.call_deferred(SyncStatus.STOPPED, _last_sync_time)
			_synchronizer_mutex.unlock()
			break
		
		_perform_operation()
		
		_synchronizer_mutex.unlock()
		
		# Wait a few milliseconds to not abuse resources
		OS.delay_msec(_SYNCHRONIZER_LOOP_DELAY_MILLIS)


## Performs the next sync operation.
func _perform_operation() -> void:
	var current_time: int = int(Time.get_ticks_msec())
	var sync_interval: int = _editor_config_service.get_automatic_game_save_sync_interval()
	var _next_sync_time: int = _last_sync_attempt_time + sync_interval
	
	var pending_operation: Callable = _pop_next_operation()
	if pending_operation.is_null() \
			and _editor_config_service.is_automatic_game_save_sync_enabled() \
			and _next_sync_time <= current_time:
		pending_operation = _save_management_service.synchronize
	
	if not pending_operation.is_null():
		_last_sync_attempt_time = current_time
		var status: SyncStatus = SyncStatus.FAILED
		var result: Error = pending_operation.call()
		if result == Error.OK:
			status = SyncStatus.SYNCHRONIZED
			_last_sync_time = int(Time.get_unix_time_from_system())
		
		sync_status_changed.emit.call_deferred(status, _last_sync_time)


## Queues an operation for the synchronizer thread.
func _queue_operation(operation: Callable) -> void:
	_pending_operations_mutex.lock()
	_pending_operations.append(operation)
	_pending_operations_mutex.unlock()


## Pops the next operation for the synchronizer thread.
func _pop_next_operation() -> Callable:
	_pending_operations_mutex.lock()
	var operation: Callable = Callable()
	if not _pending_operations.is_empty():
		operation = _pending_operations.pop_front()
	_pending_operations_mutex.unlock()
	return operation


## Called when the save assigned to a slot changes.
func _on_slot_save_changed(slot: int, save: SaveArchiveManifest) -> void:
	slot_save_changed.emit.call_deferred(slot, save)


## Called when a save is added.
func _on_save_added(save: SaveArchiveManifest) -> void:
	save_added.emit.call_deferred(save)


## Called when a save is removed.
func _on_save_removed(save_id: String) -> void:
	save_removed.emit.call_deferred(save_id)
