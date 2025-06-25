class_name SaveArchiveManifest
extends Object
## Represents a save archive manifest.

const _CURRENT_FORMAT_REVISION: int = 1
const _FORMAT_REVISION_KEY: String = "format_revision"
const _ID_KEY: String = "id"
const _SAVE_NAME_KEY: String = "name"
const _CREATED_AT_KEY: String = "created_at"
const _UTC_OFFSET_MINUTES_KEY: String = "utc_offset"

## Deserializes a SaveArchiveManifest from a JSON string or null if the string
## could not be parsed.
static func deserialize(json: String) -> SaveArchiveManifest:
	var parser: JSON = JSON.new()
	
	if parser.parse(json) != Error.OK:
		return null
	
	var format_revision: int = parser.data[_FORMAT_REVISION_KEY]
	if format_revision > _CURRENT_FORMAT_REVISION:
		printerr("Failed to deserialize save manifest; manifest was " + \
				"created using a later revision; expected %d; was %d" % \
				[_CURRENT_FORMAT_REVISION, format_revision])
		return null
	
	var id: String = parser.data[_ID_KEY]
	var save_name: String = parser.data[_SAVE_NAME_KEY]
	var created_at_timestamp: int = parser.data[_CREATED_AT_KEY]
	var utc_offset_minutes: int = parser.data[_UTC_OFFSET_MINUTES_KEY]
	
	return SaveArchiveManifest.new(id, save_name, created_at_timestamp,
			utc_offset_minutes)


var _id: String = ""
var _save_name: String = ""
var _created_at_timestamp: int = -1
var _utc_offset_minutes: int = -1

## Constructs a new manifest.
func _init(id: String, save_name: String, created_at_timestamp: int,
		utc_offset_minutes: int) -> void:
	assert(id != null, "id must not be null")
	assert(save_name != null, "save_name must not be null")
	assert(created_at_timestamp > 0, "created_at_timestamp must be greater than zero")
	_id = id
	_save_name = save_name
	_created_at_timestamp = created_at_timestamp
	_utc_offset_minutes = utc_offset_minutes


## Returns the save's unique id.
func get_id() -> String:
	return _id


## Gets the archived save's name.
func get_save_name() -> String:
	return _save_name


## Gets the archived save's name as the game would display it.
func get_save_display_name() -> String:
	return _save_name.replace(" ", "")


## Gets the number of seconds since the Unix epoch when the save was created.
func get_created_at_timestamp() -> int:
	return _created_at_timestamp


## Gets the UTC offset at the time the save was created.
func get_utc_offset_minutes() -> int:
	return _utc_offset_minutes


## Serializes the manifest to a JSON string.
func serialize() -> String:
	var data: Dictionary = {}
	data[_FORMAT_REVISION_KEY] = _CURRENT_FORMAT_REVISION
	data[_ID_KEY] = _id
	data[_SAVE_NAME_KEY] = _save_name
	data[_CREATED_AT_KEY] = _created_at_timestamp
	data[_UTC_OFFSET_MINUTES_KEY] = _utc_offset_minutes
	
	return JSON.stringify(data, "  ")
