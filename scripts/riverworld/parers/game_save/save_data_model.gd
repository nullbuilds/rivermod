class_name SaveDataModel
extends Object
## Encapsulates the data for a Riverworld data save file.

static var _save_name_regex: RegEx = RegEx.create_from_string("[ a-zA-Z0-9]{1,16}")

var _save_name: String = ""

## Parses the given context as a data save file or returns null if the file
## could not be parsed.
static func parse(context: ParseContext) -> SaveDataModel:
	assert(context != null, "context must not be null")
	
	var unknown_field: int = context.next_u32le()
	if unknown_field != 1:
		context.log_warning("First unknown field is expected to always be 1; was %d" % unknown_field)
	
	var save_name_length: int = context.next_u32le()
	var save_name: String = context.next_fixed_length_string(save_name_length)
	if _save_name_regex.search(save_name) == null:
		context.log_warning("Save name contains unexpected characters; was \"%s\"" % save_name)
	
	var save_data: SaveDataModel = SaveDataModel.new()
	save_data._save_name = save_name
	
	return save_data


## Returns the user-defined name for the save file including characters the game
## does not display.
func get_save_name() -> String:
	return _save_name
