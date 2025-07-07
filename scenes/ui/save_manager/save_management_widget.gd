class_name SaveManagementWidget
extends MarginContainer
## Widget for managing the game's save files.

const _SAVE_POPUP_DELETE_SAVE_ID: int = GameSaveDataRepository.SAVE_SLOTS
const _SAVE_SLOT_CLEAR_SLOT_ID: int = 0
const _SAVE_SLOT_DELETE_SAVE_ID: int = 1

var _injector: Injector = null
var _save_manager: AsyncSaveManagementService = null
var _selected_save_id: String = ""
var _selected_slot_index: int = -1
@onready var _save_list: SaveList = %SaveList
@onready var _save_slot_list: SaveSlotList = %SaveSlotList
@onready var _save_sync_status_bar: SaveSyncStatusBar = %SaveSyncStatusBar
@onready var _save_popup_menu: PopupMenu = %SavePopupMenu
@onready var _save_slot_popup_menu: PopupMenu = %SaveSlotPopupMenu
@onready var _save_delete_popup: SaveDeletePopup = %SaveDeletePopup

## Readies the widget.
func _ready() -> void:
	assert(_injector != null, "Class must be injected")
	_save_manager = _injector.provide(AsyncSaveManagementService)
	_save_manager.save_added.connect(_on_save_added)
	_save_manager.save_removed.connect(_on_save_removed)
	_save_manager.slot_save_changed.connect(_on_save_slot_changed)
	_save_manager.sync_status_changed.connect(_on_sync_status_changed)
	
	_save_sync_status_bar.sync_pressed.connect(_on_sync_pressed)
	
	_save_list.card_menu_button_pressed.connect(_on_save_card_menu_button_pressed)
	_save_slot_list.slot_save_menu_button_pressed.connect(_on_slot_save_menu_button_pressed)
	_save_delete_popup.delete_confirmed.connect(_on_save_delete_confirmed)
	
	_setup_save_popup()
	_setup_save_slot_popup()
	
	_populate_saves()


## Adds a new save card.
func _add_save_card(save: SaveArchiveManifest) -> void:
	_save_list.add_save(save)


## Removes a save card.
func _remove_card(save_id: String) -> void:
	_save_list.remove_save(save_id)


## Populates the UI with existing saves.
func _populate_saves() -> void:
	for save in _save_manager.get_archived_saves():
		_add_save_card(save)
	
	var save_slots: Dictionary[int, SaveArchiveManifest] = _save_manager.get_slot_saves()
	for slot_index in save_slots:
		_update_slot(slot_index, save_slots[slot_index])
	
	_synchronize_saves()


## Updates a slotted save.
func _update_slot(slot_index: int, save: SaveArchiveManifest) -> void:
	_save_slot_list.set_slot_save(slot_index, save)


## Schedules synchronization of the saves.
func _synchronize_saves() -> void:
	_save_manager.synchronize()


## Sets-up the save popup.
func _setup_save_popup() -> void:
	for slot_index in range(GameSaveDataRepository.SAVE_SLOTS):
		var text: String = "Assign to Slot %d" % slot_index
		_save_popup_menu.add_item(text, slot_index)
		
	_save_popup_menu.add_separator()
	
	_save_popup_menu.add_item("Delete", _SAVE_POPUP_DELETE_SAVE_ID)
	
	_save_popup_menu.id_pressed.connect(_on_save_popup_pressed)


## Sets-up the save slot popup.
func _setup_save_slot_popup() -> void:
	_save_slot_popup_menu.add_item("Clear slot", _SAVE_SLOT_CLEAR_SLOT_ID)
	
	_save_slot_popup_menu.add_separator()
	
	_save_slot_popup_menu.add_item("Delete save", _SAVE_SLOT_DELETE_SAVE_ID)
	
	_save_slot_popup_menu.id_pressed.connect(_on_save_slot_popup_pressed)


## Prompts the user if they want to delete a save.
func _prompt_and_delete_save(save_id: String) -> void:
	var save: SaveArchiveManifest = _save_manager.get_archived_save(save_id)
	if save != null:
		_save_delete_popup.save_name = save.get_save_display_name()
		_save_delete_popup.popup_centered()


## Called when a new save archive is added.
func _on_save_added(save: SaveArchiveManifest) -> void:
	_add_save_card(save)


## Called when a save archive is removed.
func _on_save_removed(save_id: String) -> void:
	_remove_card(save_id)


## Called when the save in save slot changes.
func _on_save_slot_changed(slot: int, save: SaveArchiveManifest) -> void:
	_update_slot(slot, save)


## Called when the save sync status changes.
func _on_sync_status_changed(status: AsyncSaveManagementService.SyncStatus,
		last_sync_time: int) -> void:
	_save_sync_status_bar.update_status(last_sync_time, status)


## Called when the sync button is pressed.
func _on_sync_pressed() -> void:
	_synchronize_saves()


## Called when a save card's menu button is pressed.
func _on_save_card_menu_button_pressed(save_id: String) -> void:
	_selected_slot_index = -1
	_selected_save_id = save_id
	
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	_save_popup_menu.popup(Rect2i(mouse_position, Vector2i.ZERO))


## Called when a save slot's menu button is pressed.
func _on_slot_save_menu_button_pressed(slot_index: int,
		save_id: String) -> void:
	_selected_slot_index = slot_index
	_selected_save_id = save_id
	
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	_save_slot_popup_menu.popup(Rect2i(mouse_position, Vector2i.ZERO))


## Called when a save popup item is pressed.
func _on_save_popup_pressed(id: int) -> void:
	if id < GameSaveDataRepository.SAVE_SLOTS:
		_save_manager.assign_save_to_slot(id, _selected_save_id)
	elif id == _SAVE_POPUP_DELETE_SAVE_ID:
		_prompt_and_delete_save(_selected_save_id)
	else:
		assert(false, "Invalid save popup id %d" % id)


## Called when a save slot popup item is pressed.
func _on_save_slot_popup_pressed(id: int) -> void:
	if id == _SAVE_SLOT_CLEAR_SLOT_ID:
		_save_manager.assign_save_to_slot(_selected_slot_index, "")
	elif id == _SAVE_SLOT_DELETE_SAVE_ID:
		_prompt_and_delete_save(_selected_save_id)
	else:
		assert(false, "Invalid save slot popup id %d" % id)


## Called when a user confirms deletion of a save.
func _on_save_delete_confirmed() -> void:
	_save_manager.delete_save(_selected_save_id)
