class_name SaveSlotList
extends MarginContainer
## A UI representation of all save slots.

## Emitted when a save card's menu button is pressed.
signal slot_save_menu_button_pressed(slot_index: int, save_id: String)

var _save_slots: Array[SaveSlot]
@onready var _slot_scene: PackedScene = preload("res://scenes/ui/save_manager/save_slot_list/save_slot/save_slot.tscn")
@onready var _slot_container: VBoxContainer = %SlotContainer

## Readies the component.
func _ready() -> void:
	for slot_index in range(GameSaveDataRepository.SAVE_SLOTS):
		var slot: SaveSlot = _slot_scene.instantiate()
		slot.slot_index = slot_index
		_save_slots.append(slot)
		_slot_container.add_child(slot)


## Sets or unsets the save for a given slot.
func set_slot_save(slot: int, save: SaveArchiveManifest) -> void:
	assert(slot >= 0 and slot < GameSaveDataRepository.SAVE_SLOTS, "slot must be a valid save slot index")
	if _save_slots[slot].save_menu_button_pressed.is_connected(_on_menu_button_pressed):
		_save_slots[slot].save_menu_button_pressed.disconnect(_on_menu_button_pressed)
	_save_slots[slot].save = save
	
	if save != null:
		_save_slots[slot].save_menu_button_pressed.connect(_on_menu_button_pressed.bind(slot, save.get_id()))


## Called when the slot's save card menu button is pressed.
func _on_menu_button_pressed(slot_index: int, save_id: String) -> void:
	slot_save_menu_button_pressed.emit(slot_index, save_id)
