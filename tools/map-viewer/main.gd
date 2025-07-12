class_name Main
extends Node3D

const _MAP_CELL_SIZE: float = 1.0
const _MAP_HEIGHT_SCALE: float = 0.2
const _GAME_DIRECTORY_PARAMETER: String = '--game-directory'

var _left_mesh: MeshInstance3D = null
var _right_mesh: MeshInstance3D = null
var _game_directory: String = ''

@onready var _script_select_option_button: OptionButton = %ScriptSelectButton
@onready var _map_select_option_button: OptionButton = %MapSelectButton
@onready var _fog_of_war_toggle_button: CheckButton = %FogOfWarToggleButton
@onready var _wrap_edges_toggle_button: CheckButton = %WrapEdgesButton
@onready var _render_mode_option_button: OptionButton = %RenderModeOptionButton
@onready var _map_container: Node3D = %MapContainer
@onready var _minimap: TextureRect = %Minimap
@onready var _fog_of_war: TextureRect = %FogOfWar
@onready var _wireframe_material: Material = preload("res://wireframe_material.tres")
@onready var _grid_material: Material = preload("res://grid_material.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	_game_directory = _get_game_directory()
	
	if DirAccess.dir_exists_absolute(_game_directory):
		_refresh_map_list()
	else:
		_script_select_option_button.disabled = true
		_map_select_option_button.disabled = true
	
	_render_mode_option_button.add_item('Texture')
	_render_mode_option_button.set_item_metadata(0, null)
	_render_mode_option_button.add_item('Grid')
	_render_mode_option_button.set_item_metadata(1, _grid_material)
	_render_mode_option_button.add_item('Wireframe')
	_render_mode_option_button.set_item_metadata(2, _wireframe_material)
	_render_mode_option_button.selected = 0
	_change_map_material(null)


func _get_game_directory() -> String:
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	
	var directory: String = ''
	for argument in user_args:
		if argument.begins_with(_GAME_DIRECTORY_PARAMETER):
			directory = argument.replace(_GAME_DIRECTORY_PARAMETER + '=', '')
			break
	
	return directory


func _refresh_map_list():
	var files = DirAccess.get_files_at(_game_directory)
	
	_script_select_option_button.clear()
	_map_select_option_button.clear()
	var script_index = 0
	var map_index = 0
	for file in files:
		var short_path = file.to_lower()
		var absolute_path = _game_directory.path_join(file)
		if _is_map_file(file):
			_map_select_option_button.add_item(short_path, map_index)
			_map_select_option_button.set_item_metadata(map_index, absolute_path)
			map_index += 1
		elif _is_level_script_file(file):
			_script_select_option_button.add_item(short_path, script_index)
			_script_select_option_button.set_item_metadata(script_index, absolute_path)
			script_index += 1
	
	_script_select_option_button.select(-1)
	_script_select_option_button.disabled = false
	_map_select_option_button.select(-1)
	_map_select_option_button.disabled = false


func _change_map(map_file_path: String, script_file_path: String):
	var context = DeserializationContext.from_file(map_file_path)
	var map_file = MapFile.deserialize(context)
	
	var parse_context = ScriptFile.ScriptParseContext.from_file(script_file_path)
	var script_file = ScriptFile.deserialize(parse_context)
	
	var importer = MapImporter.new(_game_directory)
	
	for child in _map_container.get_children():
		_map_container.remove_child(child)
		child.queue_free()
	
	var mesh = importer.import_mesh(map_file, script_file, _MAP_CELL_SIZE, \
			_MAP_HEIGHT_SCALE)
	
	var center_mesh = MeshInstance3D.new()
	center_mesh.mesh = mesh
	_map_container.add_child(center_mesh)
	
	var offset = MapFile.MAP_SIZE * _MAP_CELL_SIZE
	
	_left_mesh = MeshInstance3D.new()
	_left_mesh.mesh = mesh
	_left_mesh.position = Vector3(-offset, 0.0, _MAP_CELL_SIZE)
	_map_container.add_child(_left_mesh)
	
	_right_mesh = MeshInstance3D.new()
	_right_mesh.mesh = mesh
	_right_mesh.position = Vector3(offset, 0.0, -_MAP_CELL_SIZE)
	_map_container.add_child(_right_mesh)
	
	_display_wrapped_edges(_wrap_edges_toggle_button.button_pressed)
	
	_fog_of_war.texture = ImageTexture.create_from_image(importer.get_fog_of_war_mask(map_file, Color(1.0, 1.0, 1.0, 0.0), Color(0.0, 0.0, 0.0, 1.0)))
	_minimap.texture = ImageTexture.create_from_image(importer.get_minimap(map_file))
	_update_map_visibility()


func _change_map_material(material: Material):
	_set_override_material(material)


func _is_map_file(file: String) -> bool:
	var filename = file.get_file().to_lower()
	if filename.begins_with('map') and filename.ends_with('.sav'):
		return true
	elif filename.begins_with('totalmap'):
		return true

	return false


func _is_level_script_file(file: String) -> bool:
	var filename = file.get_file().to_lower()
	return filename.ends_with('.asm')


func _update_map_visibility():
	_fog_of_war.visible = _fog_of_war_toggle_button.button_pressed


func _display_wrapped_edges(display: bool):
	if _left_mesh:
		_left_mesh.visible = display
	
	if _right_mesh:
		_right_mesh.visible = display


func _set_override_material(material: Material):
	for child in _map_container.get_children():
		if child is MeshInstance3D:
			child.material_override = material


func _on_map_select_button_item_selected(index: int):
	var map_file = _map_select_option_button.get_item_metadata(index)
	var script_file = _script_select_option_button.get_selected_metadata()
	if script_file:
		_change_map(map_file, script_file)


func _on_fog_of_war_toggle_button_toggled(_toggled_on: bool):
	_update_map_visibility()


func _on_render_mode_option_button_item_selected(index: int):
	_change_map_material(_render_mode_option_button.get_item_metadata(index))


func _on_wrap_edges_button_toggled(toggled_on: bool):
	_display_wrapped_edges(toggled_on)


func _on_script_select_button_item_selected(index: int):
	var map_file = _map_select_option_button.get_selected_metadata()
	var script_file = _script_select_option_button.get_item_metadata(index)
	if map_file:
		_change_map(map_file, script_file)
