class_name SaveSlot
extends MarginContainer
## UI representation of a save slot.

## Emitted when the associated save card's menu button is pressed.
signal save_menu_button_pressed()

@onready var _slot_index_label: Label = %SlotIndexLabel
@onready var _save_game_card: SaveGameCard = %SaveGameCard

## Sets the slot index.
var slot_index: int:
	set(value):
		slot_index = value
		_update_visuals.call_deferred()


## Sets the save to display.
var save: SaveArchiveManifest:
	set(value):
		save = value
		_update_visuals.call_deferred()


## Readies the slot.
func _ready() -> void:
	_save_game_card.menu_button_pressed.connect(_on_menu_button_pressed)
	_update_visuals()


## Updates the visuals.
func _update_visuals() -> void:
	_save_game_card.save = save
	_slot_index_label.text = str(slot_index)


## Called when the save card's menu button is pressed.
func _on_menu_button_pressed() -> void:
	save_menu_button_pressed.emit()
