class_name SaveManagementService
extends Object
## Service for managing the game's save files. Thread safe.

## Emitted when the save assigned to a slot changes.
signal slot_save_changed(slot: int, save: SaveArchiveManifest)

## Emitted when a new save is added.
signal save_added(save: SaveArchiveManifest)

## Emitted when a save is removed.
signal save_removed(save_id: String)

const _BLANK_SLOT_SAVE_ID: String = ""

var _save_archive_repository: SaveArchiveRepository = null
var _game_save_data_repository: GameSaveDataRepository = null
var _slot_save_ids: Array[String] = []
var _archived_saves: Dictionary[String, SaveArchiveManifest] = {}
var _mutex: Mutex = Mutex.new()

## Constructs a new save management service.
func _init(save_archive_repository: SaveArchiveRepository,
		game_save_data_repository: GameSaveDataRepository) -> void:
	assert(save_archive_repository != null, "save_archive_repository must not be null")
	assert(game_save_data_repository != null, "game_save_data_repository must not be null")
	_save_archive_repository = save_archive_repository
	_game_save_data_repository = game_save_data_repository
	
	_slot_save_ids.resize(GameSaveDataRepository.SAVE_SLOTS)
	_slot_save_ids.fill(_BLANK_SLOT_SAVE_ID)


## Returns the save in each populated save slot at the time of the last sync.
func get_slot_saves() -> Dictionary[int, SaveArchiveManifest]:
	_mutex.lock()
	var saves: Dictionary[int, SaveArchiveManifest] = {}
	for slot in range(GameSaveDataRepository.SAVE_SLOTS):
		var manifest: SaveArchiveManifest = null
		var slot_save_id: String = _slot_save_ids[slot]
		if slot_save_id != _BLANK_SLOT_SAVE_ID:
			manifest = _archived_saves.get(slot_save_id)
			if manifest != null:
				saves.set(slot, manifest)
	
	_mutex.unlock()
	return saves


## Returns the details of each archived save at the time of the last
## save sync.
func get_archived_saves() -> Array[SaveArchiveManifest]:
	_mutex.lock()
	var saves: Array[SaveArchiveManifest] = _archived_saves.values()
	_mutex.unlock()
	return saves


## Assigns the given archived save to the specified slot. Forces a
## synchronization to occur.
func assign_save_to_slot(slot: int, save_id: String) -> Error:
	assert(slot >= 0 and slot < GameSaveDataRepository.SAVE_SLOTS, "slot must be a valid slot index")
	assert(save_id != null, "save_id must not be null")
	
	var error: Error = Error.OK
	_mutex.lock()
	error = synchronize()
	if error == Error.OK:
		error = _change_slot_save(slot, save_id)
	_mutex.unlock()
	return error


## Archives saves from the game's slots.
func synchronize() -> Error:
	var overal_status: Error = Error.OK
	var error: Error = Error.OK
	
	_mutex.lock()
	# Synchronize save slots
	error = _synchronize_save_slots()
	if error != Error.OK:
		overal_status = error
	
	# Synchronize save archive
	error = _synchronize_save_archive()
	if error != Error.OK:
		overal_status = error
	_mutex.unlock()
	
	return overal_status


## Deletes the given archived save and unassigns it from any save slots. Forces
## a synchronization to occur.
func delete_save(save_id: String) -> Error:
	assert(save_id != null, "save_id must not be null")
	assert(!save_id.is_empty(), "save_id must not be empty")
	
	var error: Error = Error.OK
	_mutex.lock()
	
	error = synchronize()
	if error == Error.OK:
		error = _save_archive_repository.delete_save(save_id)
		if error == Error.ERR_DOES_NOT_EXIST or error == Error.OK:
			error = Error.OK
			var slot_update_error: Error = Error.OK
			for slot in range(GameSaveDataRepository.SAVE_SLOTS):
				var slot_save_id: String = _slot_save_ids[slot]
				if slot_save_id == save_id:
					slot_update_error = _change_slot_save(slot, _BLANK_SLOT_SAVE_ID)
					if slot_update_error != Error.OK:
						error = slot_update_error
	
	_mutex.unlock()
	return error


## Archives the saves in each save slot and updates the internal cache.
func _synchronize_save_slots() -> Error:
	var overal_status: Error = Error.OK
	var error: Error = Error.OK
	
	for slot in range(GameSaveDataRepository.SAVE_SLOTS):
		var save_id: String = _BLANK_SLOT_SAVE_ID
		var save_data: GameSaveData = _game_save_data_repository.get_save_data(slot)
		error = _game_save_data_repository.get_error()
		if error != Error.OK or save_data == null:
			overal_status = error
			_update_slot_save_id(slot, save_id)
			continue
		
		var manifest: SaveArchiveManifest = _save_archive_repository.archive(save_data)
		error = _save_archive_repository.get_error()
		if error == Error.OK:
			save_id = manifest.get_id()
		else:
			overal_status = error
		_update_slot_save_id(slot, save_id)
	
	return overal_status


## Updates the internal cache of archived saves.
func _synchronize_save_archive() -> Error:
	# Get archived saves
	var error: Error = Error.OK
	var saves: Array[SaveArchiveManifest] = _save_archive_repository.get_archived_saves()
	error = _save_archive_repository.get_error()
	if error != Error.OK:
		return error
	
	# Build new cache
	var old_archived_saves: Dictionary[String, SaveArchiveManifest] = _archived_saves.duplicate()
	var new_archived_saves: Dictionary[String, SaveArchiveManifest] = {}
	for save in saves:
		new_archived_saves.set(save.get_id(), save)
	
	# Update cache
	_archived_saves = new_archived_saves
	
	# Compare saves and emit updates
	var all_save_ids: Array[String] = []
	all_save_ids.append_array(new_archived_saves.keys())
	all_save_ids.append_array(old_archived_saves.keys())
	
	for save_id in all_save_ids:
		if not old_archived_saves.has(save_id):
			save_added.emit(_archived_saves.get(save_id))
		elif not new_archived_saves.has(save_id):
			save_removed.emit(save_id)
	
	return error

## Updates the save for a given save slot and internal data caches.
func _change_slot_save(slot: int, save_id: String) -> Error:
	var error: Error = Error.OK
	
	var save_data: GameSaveData = null
	if save_id != _BLANK_SLOT_SAVE_ID:
		save_data = _save_archive_repository.get_archived_save_data(save_id)
		error = _save_archive_repository.get_error()
		if error != Error.OK:
			return error
	
	error = _game_save_data_repository.set_save_data(slot, save_data)
	if error != Error.OK:
		return error
	
	_slot_save_ids[slot] = save_id
	if save_id == _BLANK_SLOT_SAVE_ID:
		_archived_saves.erase(save_id)
	
	return error


## Updates the internal cache for a save slot.
func _update_slot_save_id(slot: int, save_id: String) -> void:
	var current_id: String = _slot_save_ids[slot]
	if save_id != current_id:
		_slot_save_ids[slot] = save_id
		var save: SaveArchiveManifest = _archived_saves.get(save_id)
		slot_save_changed.emit(slot, save)
