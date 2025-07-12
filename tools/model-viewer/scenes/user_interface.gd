class_name UserInterface
extends CanvasLayer

signal model_file_selected(model_path: String, texture_directory: String)
signal element_selected(element: int)
signal visible_objects_changed(visible_objects: PackedInt32Array)
signal render_mode_selected(mode: String)

const _MODEL_DIRECTORY: String = 'xxx'
const _TEXTURE_DIRECTORY: String = 'GIFS'
const _MODEL_EXTENSION: String = '.xxx'
const _RENDER_MODE_TEXTURE: String = 'TEXTURE'
const _RENDER_MODE_NORMALS: String = 'NORMALS'
const _RENDER_MODE_WIREFRAME: String = 'WIREFRAME'
const _GAME_DIRECTORY_PARAMETER : String = '--game-directory'

var _game_directory: String = ''
var _texture_directory: String = ''

@onready var _model_option_button: OptionButton = %ModelOptionButton
@onready var _render_mode_option_buttom: OptionButton = %RenderModeOptionButton
@onready var _element_option_button: OptionButton = %ElementOptionButton
@onready var _object_item_list: ItemList = %ObjectItemList
@onready var _message_log_text_box: RichTextLabel = %MessageLogTextBox

# TODO move preferences logic to the main class since there may be preferences
# (like window size) that apply to components the UI does not control
# TODO move texture file path to the main class since this shouldn't be
# responsible for knowing the game's file structure

func _ready():
	_model_option_button.disabled = true
	_element_option_button.disabled = true
	
	_render_mode_option_buttom.add_item('Texture', 0)
	_render_mode_option_buttom.set_item_metadata(0, _RENDER_MODE_TEXTURE)
	_render_mode_option_buttom.add_item('Normals', 1)
	_render_mode_option_buttom.set_item_metadata(1, _RENDER_MODE_NORMALS)
	_render_mode_option_buttom.add_item('Wireframe', 2)
	_render_mode_option_buttom.set_item_metadata(2, _RENDER_MODE_WIREFRAME)
	_render_mode_option_buttom.select(0)
	
	var game_directory: String = _get_game_directory()
	_change_game_directory(game_directory)


func log_message(message: String, is_error: bool):
	var color = Color.FIREBRICK if is_error else Color.GRAY
	
	_message_log_text_box.append_text('[color=%s]%s\n' % [color.to_html(false), message])


func clear_message_log():
	_message_log_text_box.clear()


func set_available_elements(elements: int):
	_element_option_button.clear()
	
	for i in elements:
		_element_option_button.add_item('Element %d' % i, i)
	
	_element_option_button.select(0)
	
	_element_option_button.disabled = elements == 1


func set_available_objects(objects: int):
	_object_item_list.clear()
	
	for i in objects:
		_object_item_list.add_item('Object %d' % i)
		_object_item_list.select(i, false)


func _get_game_directory() -> String:
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	
	var directory: String = ''
	for argument in user_args:
		if argument.begins_with(_GAME_DIRECTORY_PARAMETER):
			directory = argument.replace(_GAME_DIRECTORY_PARAMETER + '=', '')
			break
	
	return directory


func _refresh_model_list(model_directory: String):
	var files = DirAccess.get_files_at(model_directory)
	
	_model_option_button.clear()
	var model_index = 0
	for file in files:
		if file.to_lower().ends_with(_MODEL_EXTENSION):
			var short_path = file.to_snake_case().replace(_MODEL_EXTENSION, '')
			var absolute_path = model_directory + '/' + file
			var descriptive_name = '%s (%s)' % [short_path, Translator.translate(short_path)]
			_model_option_button.add_item(descriptive_name, model_index)
			_model_option_button.set_item_metadata(model_index, absolute_path)
			model_index += 1
	
	_model_option_button.select(-1)
	_model_option_button.disabled = false


func _on_game_directory_dialog_dir_selected(dir: String):
	_change_game_directory(dir)


func _on_model_option_button_item_selected(index: int):
	var model_path = _model_option_button.get_item_metadata(index)
	model_file_selected.emit(model_path, _texture_directory)


func _on_render_mode_button_item_selected(index):
	var render_mode = _render_mode_option_buttom.get_item_metadata(index)
	render_mode_selected.emit(render_mode)


func _change_game_directory(new_game_directory: String):
	var new_texture_directory = new_game_directory + '/' + _TEXTURE_DIRECTORY
	var new_model_directory = new_game_directory + '/' + _MODEL_DIRECTORY
	
	if DirAccess.dir_exists_absolute(new_texture_directory) and DirAccess.dir_exists_absolute(new_model_directory):
		_game_directory = new_game_directory
		_texture_directory = new_texture_directory
		_refresh_model_list(new_model_directory)


func _on_copy_messages_button_pressed():
	DisplayServer.clipboard_set(_message_log_text_box.get_parsed_text())


func _on_element_option_button_item_selected(index: int):
	element_selected.emit(index)


func _on_object_item_list_multi_selected(_index: int, _selected: bool):
	visible_objects_changed.emit(_object_item_list.get_selected_items())
