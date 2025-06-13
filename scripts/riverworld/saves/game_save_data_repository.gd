class_name GameSaveDataRepository
extends Object
## Abstract repository for accessing save files from the game's installation.

## Returns the status of the last operation.
func get_error() -> Error:
	assert(false, "Not implemented")
	return Error.OK


## Returns the save data for the given slot or null if no data exists for that
## slot.
func get_save_data(_slot: int) -> GameSaveData:
	assert(false, "Not implemented")
	return null


## Sets or orverwrites the save data for the given slot.
## 
## Note that modified time will not be set. Only the save contents.
func set_save_data(_slot: int, _game_save_data: GameSaveData) -> Error:
	assert(false, "Not implemented")
	return Error.OK
