class_name SpriteViewer
extends Window

const _LOAD_ID: int = 0

var _injector: Injector = null
var _config_service: EditorConfigurationService = null

@onready var _file_popup_menu: PopupMenu = %FilePopupMenu
@onready var _sprite_file_dialog: FileDialog = %SpriteFileDialog
@onready var _sprite_container: Container = %SpriteContainer

func _ready() -> void:
	title = "Sprite Viewer"
	
	close_requested.connect(queue_free)
	_file_popup_menu.id_pressed.connect(_on_file_id_pressed)
	_sprite_file_dialog.file_selected.connect(_on_file_selected)
	
	_config_service = _injector.provide(EditorConfigurationService)


func _prompt_for_file() -> void:
	var game_directory: String = _config_service.get_game_install_directory()
	_sprite_file_dialog.root_subfolder = game_directory
	_sprite_file_dialog.popup_file_dialog()


func _view_sprite_sheet(path: String) -> void:
	var sprite_sheet: SpriteSheetFileModel = _load_sprite_sheet(path)
	if null == sprite_sheet:
		push_error("Failed to load sprite sheet \"%s\"" % path)
		return
	
	var sprite_importer: SpriteImporter = SpriteImporter.new()
	
	var max_sprite_size: Vector2i = sprite_sheet.get_max_size()
	var sprites: Array[SpriteSheetFileModel.SpriteModel] = sprite_sheet.get_sprites()
	for sprite_index in sprites.size():
		var sprite: SpriteSheetFileModel.SpriteModel = sprites[sprite_index]
		var sprite_control: Control = _create_sprite(sprite_index, max_sprite_size, sprite, sprite_importer)
		_sprite_container.add_child(sprite_control)
	
	title = "Sprite Viewer - %s" % path.get_file()


func _load_sprite_sheet(path: String) -> SpriteSheetFileModel:
	var sprite_sheet: SpriteSheetFileModel = null
	var context: ParseContext = ParseContext.from_file(path)
	if null != context:
		sprite_sheet = SpriteSheetFileModel.parse(context)
		for event in context.get_events():
			var message: String = event.get_message()
			match (event.get_level()):
				ParseContext.ContextEvent.Level.WARNING:
					push_warning(message)
				ParseContext.ContextEvent.Level.ERROR:
					push_error(message)
	
	return sprite_sheet


func _create_sprite(sprite_index: int, max_sprite_size: Vector2i, sprite: SpriteSheetFileModel.SpriteModel, sprite_importer: SpriteImporter) -> Control:
	var image: Image = sprite_importer.import(sprite)
	
	var sprite_container: SpriteContainer = SpriteContainer.new()
	sprite_container.sprite_index = sprite_index
	sprite_container.sprite_texture = ImageTexture.create_from_image(image)
	sprite_container.sprite_max_size = max_sprite_size
	sprite_container.sprite_scale = 4.0
	
	return sprite_container


func _clear_loaded_sprites() -> void:
	for child in _sprite_container.get_children():
		child.queue_free()


func _on_file_id_pressed(id: int) -> void:
	match(id):
		_LOAD_ID:
			_prompt_for_file()


func _on_file_selected(path: String) -> void:
	_clear_loaded_sprites()
	_view_sprite_sheet(path)
