extends Control

## Main interaction menu with tabs for managing shop

enum Tab {
	MACHINES,
	SPECIAL
}

signal menu_closed()

@onready var inventory_manager: Node = get_node("/root/Root/Gameplay/InventoryManager")
@onready var machine_manager: Node = get_node("/root/Root/Gameplay/MachineManager")
@onready var display_manager: Node = get_node("/root/Root/Gameplay/DisplayManager")
@onready var currency_manager: Node = get_node("/root/Root/Gameplay/CurrencyManager")
@onready var game_loop_manager: Node = get_node("/root/Root/Gameplay/GameLoopManager")

@onready var tab_container: TabContainer = $Panel/TabContainer
@onready var machines_list: VBoxContainer = $Panel/TabContainer/Machines/ScrollContainer/MachineList
@onready var special_list: VBoxContainer = $Panel/TabContainer/Special/ScrollContainer/SpecialList
@onready var close_button: Button = $Panel/CloseButton

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	machine_manager.machines_changed.connect(_refresh_machines)
	display_manager.plinths_changed.connect(_refresh_special)
	inventory_manager.inventory_slots_changed.connect(_refresh_special)
	currency_manager.currency_changed.connect(func(_amount):
		_refresh_machines()
		_refresh_special()
	)
	_refresh_machines()
	_refresh_special()

func open_menu() -> void:
	visible = true
	game_loop_manager.open_menu(game_loop_manager.Menu.DISPLAY)
	_refresh_machines()
	_refresh_special()

func close_menu() -> void:
	visible = false
	game_loop_manager.close_menu()
	menu_closed.emit()

func _on_close_pressed() -> void:
	close_menu()

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

func _refresh_special() -> void:
	# Clear existing items
	for child in special_list.get_children():
		child.queue_free()

	# Add inventory slot purchase option
	_create_inventory_purchase_item()

	# Add plinth purchase option
	_create_plinth_purchase_item()

func _create_plinth_purchase_item() -> void:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	# Title
	var title_label = Label.new()
	title_label.text = "Display Plinths"
	title_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = "Expand your display room to show more souls to customers"
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(500, 0)
	vbox.add_child(desc_label)

	# Info line
	var info_label = Label.new()
	info_label.text = "Owned: %d / %d" % [display_manager.owned_plinth_count, display_manager.get_max_plinths()]
	vbox.add_child(info_label)

	# Purchase button or max reached
	if display_manager.can_purchase_plinth():
		var cost = display_manager.get_next_plinth_cost()
		var buy_button = Button.new()
		buy_button.text = "Purchase Plinth (%d KP)" % cost
		buy_button.pressed.connect(_on_purchase_plinth)

		# Disable if can't afford
		if not currency_manager.can_afford(cost):
			buy_button.disabled = true
			buy_button.text = "Cannot Afford (%d KP)" % cost

		vbox.add_child(buy_button)
	else:
		var max_label = Label.new()
		max_label.text = "✓ MAX CAPACITY"
		max_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		vbox.add_child(max_label)

	special_list.add_child(panel)

func _create_inventory_purchase_item() -> void:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	# Title
	var title_label = Label.new()
	title_label.text = "Storage Capacity"
	title_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = "Expand your storage room to hold more souls"
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(500, 0)
	vbox.add_child(desc_label)

	# Info line
	var info_label = Label.new()
	info_label.text = "Capacity: %d / %d" % [inventory_manager.max_souls, inventory_manager.MAX_INVENTORY_CAPACITY]
	vbox.add_child(info_label)

	# Purchase button or max reached
	if inventory_manager.can_purchase_inventory():
		var cost = inventory_manager.get_next_inventory_cost()
		var buy_button = Button.new()
		buy_button.text = "Purchase Storage Slot (%d KP)" % cost
		buy_button.pressed.connect(_on_purchase_inventory)

		# Disable if can't afford
		if not currency_manager.can_afford(cost):
			buy_button.disabled = true
			buy_button.text = "Cannot Afford (%d KP)" % cost

		vbox.add_child(buy_button)
	else:
		var max_label = Label.new()
		max_label.text = "✓ MAX CAPACITY"
		max_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		vbox.add_child(max_label)

	special_list.add_child(panel)

func _on_purchase_inventory() -> void:
	inventory_manager.purchase_inventory_slot()

func _on_purchase_plinth() -> void:
	display_manager.purchase_plinth()
