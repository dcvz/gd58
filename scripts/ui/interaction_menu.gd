extends Control

## Main interaction menu with tabs for managing shop

enum Tab {
	INVENTORY,
	MACHINES,
	SPECIAL
}

signal menu_closed()

@onready var inventory_manager: Node = get_node("/root/Root/Gameplay/InventoryManager")
@onready var machine_manager: Node = get_node("/root/Root/Gameplay/MachineManager")
@onready var currency_manager: Node = get_node("/root/Root/Gameplay/CurrencyManager")
@onready var game_loop_manager: Node = get_node("/root/Root/Gameplay/GameLoopManager")

@onready var tab_container: TabContainer = $Panel/TabContainer
@onready var inventory_list: VBoxContainer = $Panel/TabContainer/Inventory/ScrollContainer/SoulList
@onready var machines_list: VBoxContainer = $Panel/TabContainer/Machines/ScrollContainer/MachineList
@onready var close_button: Button = $Panel/CloseButton

var soul_item_scene: PackedScene = preload("res://scenes/soul_inventory_item.tscn")

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	inventory_manager.inventory_changed.connect(_refresh_inventory)
	machine_manager.machines_changed.connect(_refresh_machines)
	currency_manager.currency_changed.connect(func(_amount): _refresh_machines())
	_refresh_inventory()
	_refresh_machines()

func open_menu() -> void:
	visible = true
	game_loop_manager.open_menu(game_loop_manager.Menu.DISPLAY)
	_refresh_inventory()
	_refresh_machines()

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

func _refresh_machines() -> void:
	# Clear existing items
	for child in machines_list.get_children():
		child.queue_free()

	# Get all machine types
	var all_machines = MachineData.MachineType.values()

	for machine_type in all_machines:
		var owned = machine_manager.has_machine(machine_type)
		_create_machine_item(machine_type, owned)

func _create_machine_item(machine_type: MachineData.MachineType, owned: bool) -> void:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	# Machine name
	var name_label = Label.new()
	name_label.text = MachineData.get_machine_name(machine_type)
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)

	# Machine description
	var desc_label = Label.new()
	desc_label.text = MachineData.get_machine_description(machine_type)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(500, 0)
	vbox.add_child(desc_label)

	# Info line (cost + duration)
	var info_hbox = HBoxContainer.new()
	vbox.add_child(info_hbox)

	var cost = MachineData.get_machine_cost(machine_type)
	var duration = MachineData.get_machine_duration(machine_type)

	var cost_label = Label.new()
	cost_label.text = "Cost: %d KP" % cost
	info_hbox.add_child(cost_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	info_hbox.add_child(spacer)

	var duration_label = Label.new()
	duration_label.text = "Duration: %ds" % duration
	info_hbox.add_child(duration_label)

	# Purchase/Owned status
	if owned:
		var owned_label = Label.new()
		owned_label.text = "✓ OWNED"
		owned_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		vbox.add_child(owned_label)
	else:
		var buy_button = Button.new()
		buy_button.text = "Purchase (%d KP)" % cost
		buy_button.pressed.connect(func(): _on_purchase_machine(machine_type))

		# Disable if can't afford
		if not currency_manager.can_afford(cost):
			buy_button.disabled = true
			buy_button.text = "Cannot Afford (%d KP)" % cost

		vbox.add_child(buy_button)

	machines_list.add_child(panel)

func _on_purchase_machine(machine_type: MachineData.MachineType) -> void:
	machine_manager.purchase_machine(machine_type)
