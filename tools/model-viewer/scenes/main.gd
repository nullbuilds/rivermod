extends Node3D

const _MODEL_MAX_SCALE : float = 0.5
const _MODEL_INITIAL_SCALE : float = 0.09
const _MODEL_MIN_SCALE : float = 0.03
const _MODEL_SCALE_AMOUNT : float = 0.003

@export var default_material: Material

@onready var _model: Node3D = %ModelContainer
@onready var _user_interface: UserInterface = %UserInterface
@onready var _wireframe_material : Material = preload("res://scenes/wireframe_material.tres")
@onready var _normal_vector_material : Material = preload("res://scenes/normal_vector_material.tres")

var _model_elements = null
var _selected_material = null

func _ready():
	_model.rotation_degrees.x = 180
	_set_model_scale(_MODEL_INITIAL_SCALE)


func _process(delta):
	_model.rotation_degrees.y += 50 * delta


func _input(event):
	if event.is_action('camera_zoom_in'):
		_adjust_model_scale(_MODEL_SCALE_AMOUNT)
	elif event.is_action('camera_zoom_out'):
		_adjust_model_scale(-_MODEL_SCALE_AMOUNT)


func _on_user_interface_model_file_selected(model_path: String, texture_directory: String):
	var file_context = DeserializationContext.from_file(model_path)
	var model = ModelFile.deserialize(file_context)
	var importer = ModelImporter.new(texture_directory, default_material)
	
	_model.position = Vector3.ZERO
	_update_model_elements(importer.import(model))
	_change_model_element(0)
	
	_align_model_to_plane()
	
	_user_interface.clear_message_log()
	for message in file_context.get_messages():
		var text = '%s: %s' % [model_path.get_file(), message.get_message()]
		_user_interface.log_message(text, message.get_level() == DeserializationContext.ContextMessage.Level.ERROR)


func _update_model_elements(elements: Array):
	_model_elements = elements
	_user_interface.set_available_elements(elements.size())


func _update_element_objects(objects: int):
	_user_interface.set_available_objects(objects)


func _change_model_element(element_index: int):
	_remove_model_meshes()
	if !_model_elements.is_empty():
		var element = _model_elements[element_index]
		var object_number = 0
		for object_mesh in element:
			var object = MeshInstance3D.new()
			object.name = 'Object %d' % object_number
			object.mesh = object_mesh
			_model.add_child(object)
			object_number += 1
		
		_update_element_objects(element.size())
	_update_model_materials()


func _change_visible_objects(visible_objects: PackedInt32Array):
	for i in _model.get_child_count():
		var object = _model.get_child(i)
		object.visible = visible_objects.has(i)


func _remove_model_meshes():
	for mesh in _model.get_children():
		_model.remove_child(mesh)
		mesh.queue_free()


func _adjust_model_scale(amount: float):
	_set_model_scale(_get_model_scale() + amount)


func _set_model_scale(model_scale: float):
	var clamped_scale = clamp(model_scale, _MODEL_MIN_SCALE, _MODEL_MAX_SCALE)
	_model.scale.x = clamped_scale
	_model.scale.y = clamped_scale
	_model.scale.z = clamped_scale
	
	_align_model_to_plane()


func _get_model_scale() -> float:
	return _model.scale.x


func _align_model_to_plane():
	var aabb = AABB()
	for child in _model.get_children():
		if child is MeshInstance3D:
			aabb = aabb.merge(child.get_aabb())
	
	aabb = _model.transform * aabb
	
	var aabb_offset = aabb.get_center() - Vector3(0.0, aabb.size.y / 2, 0.0)
	
	_model.position -= aabb_offset * Vector3(0.0, 1.0, 0.0)


func _on_user_interface_render_mode_selected(mode: String):
	match mode:
		'NORMALS':
			_selected_material = _normal_vector_material
		'WIREFRAME':
			_selected_material = _wireframe_material
		_:
			_selected_material = null
	
	_update_model_materials()


func _update_model_materials():
	for child in _model.get_children():
		if 'material_override' in child:
			child.material_override = _selected_material


func _on_user_interface_element_selected(element: int):
	_change_model_element(element)


func _on_user_interface_visible_objects_changed(visible_objects: PackedInt32Array):
	_change_visible_objects(visible_objects)
