class_name GameFileSourceSaveDataRepository
extends GameSaveDataRepository
## Repository for accessing game save data from a game file source. Thread-safe.

const _SAVE_MINIMUM_DELAY_SECONDS: int = 5
const _MAX_SAVE_TIME_DIFFERENCE: int = 1

var _error: Error = Error.OK
var _game_file_source: GameFileSource = null
var _mutex: Mutex = Mutex.new()

## Constructs an instance of the save data repo.
func _init(game_file_source: GameFileSource) -> void:
	assert(game_file_source != null, "game_file_source must not be null")
	_game_file_source = game_file_source


## Returns the status of the last operation.
func get_error() -> Error:
	return _error


## Returns the save data for the given slot or null if no data exists for that
## slot or there was an error reading the slot.
func get_save_data(slot: int) -> GameSaveData:
	assert(slot >= 0 and slot <= 9, "slot must be in the range [0, 9]")
	
	var game_save_data: GameSaveData = null
	var map_file_name: String = GameFileSource.get_map_save_file_name(slot)
	var data_file_name: String = GameFileSource.get_data_save_file_name(slot)
	
	_mutex.lock()
	
	# Verify the files exist
	if not _game_file_source.has_file(data_file_name) or \
			not _game_file_source.has_file(map_file_name):
		_error = Error.ERR_FILE_NOT_FOUND
		_mutex.unlock()
		return game_save_data
	
	# Get the modified time for the save game.
	var save_time: int = _get_save_last_modified_time(slot)
	if _error != Error.OK:
		_mutex.unlock()
		return game_save_data
	
	# Ensure the save was modified at least x seconds ago to help protect
	# against accidentally reading the files while the game is still writing to
	# them (ie finished writing one and hasn't yet started writing the next).
	# This doesn't guarantee the player won't save mid-operation but it does add
	# some limited protection.
	var current_time: int = int(Time.get_unix_time_from_system())
	if save_time + _SAVE_MINIMUM_DELAY_SECONDS >= current_time:
		_error = Error.ERR_FILE_ALREADY_IN_USE
		_mutex.unlock()
		return game_save_data
	
	# Read the map save bytes
	var map_bytes: PackedByteArray = _game_file_source.read_file(map_file_name)
	_error = _game_file_source.get_error()
	if _error != Error.OK:
		_mutex.unlock()
		return game_save_data
	
	# Read the data save bytes
	var data_bytes: PackedByteArray = _game_file_source.read_file(data_file_name)
	_error = _game_file_source.get_error()
	if _error != Error.OK:
		_mutex.unlock()
		return game_save_data
	
	game_save_data = GameSaveData.new(save_time, map_bytes, data_bytes)
	_error = Error.OK
	_mutex.unlock()
	return game_save_data


## Sets or orverwrites the save data for the given slot.
## 
## Note that modified time will not be set. Only the save contents.
func set_save_data(slot: int, game_save_data: GameSaveData) -> Error:
	assert(slot >= 0 and slot <= 9, "slot must be in the range [0, 9]")
	assert(game_save_data != null, "game_save_data must not be null")
	
	_mutex.lock()
	
	var map_file_name: String = GameFileSource.get_map_save_file_name(slot)
	_error = _game_file_source.write_file(map_file_name, game_save_data.get_map_bytes())
	if _error != Error.OK:
		_mutex.unlock()
		return _error
	
	var data_file_name: String = GameFileSource.get_data_save_file_name(slot)
	_error = _game_file_source.write_file(data_file_name, game_save_data.get_data_bytes())
	if _error != Error.OK:
		_mutex.unlock()
		return _error
	
	_error = Error.OK
	_mutex.unlock()
	return Error.OK


## Returns the max save time of the two files comprising a save game in seconds
## since the Unix epoch. Returns -1 if the operation failed.
func _get_save_last_modified_time(slot: int) -> int:
	# Get the write time for the map save file
	var map_file_name: String = GameFileSource.get_map_save_file_name(slot)
	var map_last_modified: int = _game_file_source.get_file_modified_time(map_file_name)
	_error = _game_file_source.get_error()
	if _error != Error.OK:
		return -1
	
	# Get the write time for the data save file
	var data_file_name: String = GameFileSource.get_data_save_file_name(slot)
	var data_last_modified: int = _game_file_source.get_file_modified_time(data_file_name)
	_error = _game_file_source.get_error()
	if _error != Error.OK:
		return -1
	
	# Verify both files were written within x seconds of each other. If not, we
	# may be attempting to fetch their data while the game is writing to them or
	# reading corrupted files.
	if absi(map_last_modified - data_last_modified) > _MAX_SAVE_TIME_DIFFERENCE:
		_error = Error.ERR_FILE_ALREADY_IN_USE
		return -1
	
	# Important to use max here rather than min since we need to know the most
	# recent time a file was modified to avoid returning files while the game is
	# modifying them.
	return maxi(data_last_modified, map_last_modified)
