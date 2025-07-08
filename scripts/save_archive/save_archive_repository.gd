class_name SaveArchiveRepository
extends Object
## Abstract archive of game save files.

## Gets the status of the last operation.
func get_error() -> Error:
	assert(false, "Not implemented")
	return Error.OK


## Archives the given save data and returns its manifest.
@warning_ignore("unused_parameter")
func archive(save_data: GameSaveData) -> SaveArchiveManifest:
	assert(false, "Not implemented")
	return null


## Get the manifests of all archived saves.
func get_archived_saves() -> Array[SaveArchiveManifest]:
	assert(false, "Not implemented")
	return []


## Gets the save data for the given id.
@warning_ignore("unused_parameter")
func get_archived_save_data(id: String) -> GameSaveData:
	assert(false, "Not implemented")
	return null


## Deletes the save with the given id.
@warning_ignore("unused_parameter")
func delete_save(id: String) -> Error:
	assert(false, "Not implemented")
	return Error.OK
