class_name SaveList
extends MarginContainer
## UI widget for listing saves.

## Emitted when a save card's menu button is pressed.
signal card_menu_button_pressed(save_id: String)

var _save_ids: Array[String] = []
@onready var _card_scene: PackedScene = preload("res://scenes/ui/save_manager/save_game_card/save_game_card.tscn")
@onready var _card_container: VBoxContainer = %CardContainer

## Adds a save card to the list.
func add_save(save: SaveArchiveManifest) -> void:
	if not _save_ids.has(save.get_id()):
		var card: SaveGameCard = _card_scene.instantiate()
		card.save = save
		
		var save_id: String = save.get_id()
		_save_ids.append(save_id)
		_card_container.add_child(card)
		card.menu_button_pressed.connect(_on_card_button_pressed.bind(save_id))
		_sort_card(card)


## Removes a save card from the list.
func remove_save(save_id: String) -> void:
	if _save_ids.has(save_id):
		var nodes: Array[Node] = _card_container.get_children()
		for node in nodes:
			var card: SaveGameCard = node as SaveGameCard
			if card.save.get_id() == save_id:
				_card_container.remove_child(card)
		_save_ids.erase(save_id)


## Sorts a card within the list.
func _sort_card(card: SaveGameCard) -> void:
	var card_created_at: int = card.save.get_created_at_timestamp()
	var cards: Array[Node] = _card_container.get_children()
	for index in range(cards.size()):
		if card_created_at >= cards[index].save.get_created_at_timestamp():
			_card_container.move_child(card, index)
			break


## Called when a save card's button is pressed.
func _on_card_button_pressed(save_id: String) -> void:
	card_menu_button_pressed.emit(save_id)
