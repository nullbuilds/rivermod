class_name SpriteContainer
extends MarginContainer

const _TRANSPARENT_BACKGROUND_COLOR_A: Color = Color("808080")
const _TRANSPARENT_BACKGROUND_COLOR_B: Color = Color("C0C0C0")

@export var sprite_texture: ImageTexture = null:
	set(value):
		sprite_texture = value
		
		if not is_node_ready():
			await ready
		
		_sprite_texture_rect.texture = sprite_texture


@export var sprite_index: int = 0:
	set(value):
		sprite_index = value
		
		if not is_node_ready():
			await ready
		
		_index_label.text = str(sprite_index)


@export var sprite_scale: float = 1.0:
	set(value):
		sprite_scale = value
		
		if not is_node_ready():
			await ready
		
		_sprite_texture_rect.custom_minimum_size = sprite_texture.get_size() * sprite_scale
		_sprite_display_container.custom_minimum_size = sprite_max_size * sprite_scale


@export var sprite_max_size: Vector2i = Vector2i.ZERO:
	set(value):
		sprite_max_size = value
		
		if not is_node_ready():
			await ready
		
		_sprite_display_container.custom_minimum_size = sprite_max_size * sprite_scale
		_sprite_background_rect.custom_minimum_size = sprite_max_size * sprite_scale
		_sprite_background_rect.texture = _generate_background_texture(sprite_max_size)


var _sprite_texture_rect: TextureRect = TextureRect.new()
var _sprite_background_rect: TextureRect = TextureRect.new()
var _sprite_display_container: Container = MarginContainer.new()
var _index_label: Label = Label.new()

func _ready() -> void:
	_sprite_texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_sprite_texture_rect.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_sprite_texture_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	_sprite_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_sprite_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	_sprite_background_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_sprite_background_rect.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_sprite_background_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	_sprite_background_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_sprite_background_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	_index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	var label_panel: PanelContainer = PanelContainer.new()
	label_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	label_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_panel.add_child(_index_label, false, Node.INTERNAL_MODE_FRONT)
	
	var sprite_dimension_container: PanelContainer = PanelContainer.new()
	sprite_dimension_container.theme_type_variation = "SpriteDimensionsPanelContainer"
	sprite_dimension_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sprite_dimension_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sprite_dimension_container.add_child(_sprite_texture_rect, false, Node.INTERNAL_MODE_FRONT)
	
	_sprite_display_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_sprite_display_container.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_sprite_display_container.add_child(_sprite_background_rect, false, Node.INTERNAL_MODE_FRONT)
	_sprite_display_container.add_child(sprite_dimension_container, false, Node.INTERNAL_MODE_FRONT)
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	vbox.add_child(label_panel)
	vbox.add_child(_sprite_display_container)
	
	add_child(vbox, false, Node.INTERNAL_MODE_FRONT)


# Generates a repeating pattern to indicate transparent pixels
func _generate_background_texture(texture_size: Vector2i) -> Texture2D:
	# TODO Extremely inefficient, find a way to use a repeating texture on GPU
	# instead - temporarily solves the problem of the tiled textures not
	# supporting scaling
	var image: Image = Image.create_empty(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	for row in texture_size.y:
		for column in texture_size.x:
			var color: Color = _TRANSPARENT_BACKGROUND_COLOR_B
			if (row + column) % 2 == 0:
				color = _TRANSPARENT_BACKGROUND_COLOR_A
			image.set_pixel(column, row, color)
	return ImageTexture.create_from_image(image)
