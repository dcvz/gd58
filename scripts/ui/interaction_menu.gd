extends Control

## Main interaction menu with tabs for managing shop

enum Tab {
	INVENTORY,
	ANALYZE,
	SPECIAL
}

signal menu_closed()

@onready var inventory_manager: Node = get_node("/root/Root/Gameplay/InventoryManager")
@onready var game_loop_manager: Node = get_node("/root/Root/Gameplay/GameLoopManager")

@onready var tab_container: TabContainer = $Panel/TabContainer
@onready var inventory_list: VBoxContainer = $Panel/TabContainer/Inventory/ScrollContainer/SoulList
@onready var close_button: Button = $Panel/CloseButton

var soul_item_scene: PackedScene = preload("res://scenes/soul_inventory_item.tscn")

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	inventory_manager.inventory_changed.connect(_refresh_inventory)
	_refresh_inventory()

func open_menu() -> void:
	visible = true
	game_loop_manager.open_menu(game_loop_manager.Menu.DISPLAY)
	_refresh_inventory()

func close_menu() -> void:
	visible = false
	game_loop_manager.close_menu()
	menu_closed.emit()

func _on_close_pressed() -> void:
	close_menu()

func _refresh_inventory() -> void:
	# Clear existing items
	for child in inventory_list.get_children():
		child.queue_free()

	# Get all souls from inventory
	var all_souls = inventory_manager.get_all_souls()
	var display_slots = inventory_manager.display_slots

	# Add soul items
	for soul in all_souls:
		var item = soul_item_scene.instantiate()
		inventory_list.add_child(item)

		var is_on_display = display_slots.has(soul.id)
		item.setup(soul, is_on_display)
		item.toggle_display_requested.connect(_on_toggle_display)

func _on_toggle_display(soul_id: String, is_currently_displayed: bool) -> void:
	if is_currently_displayed:
		inventory_manager.remove_from_display(soul_id)
	else:
		if inventory_manager.has_available_display_slot():
			inventory_manager.add_to_display(soul_id)
		else:
			print("No available display slots!")
