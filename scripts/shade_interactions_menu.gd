extends Control

## Menu for handling shade interactions (buyers and sellers)

# Load InterestMatcher for formatting interests
const InterestMatcher = preload("res://scripts/interest_matcher.gd")

var interaction_manager: Node
var game_loop_manager: Node
var interaction_list: VBoxContainer
var close_button: Button

func _ready() -> void:
	await get_tree().process_frame

	# Get references
	interaction_manager = get_node("/root/Root/Gameplay/InteractionManager")
	game_loop_manager = get_node("/root/Root/Gameplay/GameLoopManager")
	interaction_list = $Panel/VBoxContainer/ScrollContainer/InteractionList
	close_button = $Panel/VBoxContainer/CloseButton

	# Connect signals
	close_button.pressed.connect(_on_close_pressed)
	interaction_manager.interaction_added.connect(_on_interaction_added)
	interaction_manager.interaction_removed.connect(_on_interaction_removed)

	# Initial population
	_refresh_list()

func show_menu() -> void:
	visible = true
	game_loop_manager.is_simulation_paused = true
	_refresh_list()

func hide_menu() -> void:
	visible = false
	game_loop_manager.is_simulation_paused = false

func _on_close_pressed() -> void:
	hide_menu()

func _refresh_list() -> void:
	# Clear existing items
	for child in interaction_list.get_children():
		child.queue_free()

	# Add all pending interactions
	var interactions = interaction_manager.get_pending_interactions()
	if interactions.size() == 0:
		var label = Label.new()
		label.text = "No pending interactions"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		interaction_list.add_child(label)
		return

	for i in range(interactions.size()):
		var interaction = interactions[i]
		_create_interaction_item(interaction, i)

func _create_interaction_item(interaction: Dictionary, index: int) -> void:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	# Header
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)

	var type_label = Label.new()
	type_label.text = "%s #%d" % [interaction.type.capitalize(), index + 1]
	type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(type_label)

	# Details based on type
	if interaction.type == "buyer":
		# Display all interests using centralized formatter
		var interests = interaction.get("interests", [])
		if interests.size() > 0:
			var wants_label = Label.new()
			wants_label.text = "Wants:"
			vbox.add_child(wants_label)

			for interest in interests:
				var interest_label = Label.new()
				interest_label.text = "  • %s" % InterestMatcher.format_interest_for_display(interest)
				vbox.add_child(interest_label)

		# Action buttons
		var button_hbox = HBoxContainer.new()
		vbox.add_child(button_hbox)

		var sell_button = Button.new()
		sell_button.text = "Sell Soul"
		sell_button.pressed.connect(func(): _handle_buyer_transaction(index, interaction))
		button_hbox.add_child(sell_button)

		var reject_button = Button.new()
		reject_button.text = "Reject"
		reject_button.pressed.connect(func(): _reject_interaction(index))
		button_hbox.add_child(reject_button)

	elif interaction.type == "seller":
		var soul_to_sell = interaction.get("soul_to_sell")
		if soul_to_sell:
			# Soul name
			var name_label = Label.new()
			name_label.text = "Selling: %s" % soul_to_sell.name
			vbox.add_child(name_label)

			# Era
			var era_label = Label.new()
			era_label.text = "Era: %s" % SoulData.Era.keys()[soul_to_sell.era]
			vbox.add_child(era_label)

			# Cause of Death
			var death_label = Label.new()
			death_label.text = "Cause of Death: %s" % SoulData.CauseOfDeath.keys()[soul_to_sell.causeOfDeath]
			vbox.add_child(death_label)

			# Stats
			if soul_to_sell.stats.size() > 0:
				var stats_label = Label.new()
				stats_label.text = "Stats:"
				vbox.add_child(stats_label)

				for stat_key in soul_to_sell.stats.keys():
					var stat_value = soul_to_sell.stats[stat_key]
					var stat_item = Label.new()
					stat_item.text = "  - %s: %d%%" % [SoulData.SoulAttribute.keys()[stat_key], int(stat_value)]
					vbox.add_child(stat_item)
			else:
				var no_stats_label = Label.new()
				no_stats_label.text = "Stats: None"
				vbox.add_child(no_stats_label)

		# Action buttons
		var button_hbox = HBoxContainer.new()
		vbox.add_child(button_hbox)

		var buy_button = Button.new()
		buy_button.text = "Buy Soul"
		buy_button.pressed.connect(func(): _handle_seller_transaction(index, interaction))
		button_hbox.add_child(buy_button)

		var reject_button = Button.new()
		reject_button.text = "Reject"
		reject_button.pressed.connect(func(): _reject_interaction(index))
		button_hbox.add_child(reject_button)

	interaction_list.add_child(panel)

func _handle_buyer_transaction(index: int, interaction: Dictionary) -> void:
	print("Handling buyer transaction for interaction %d" % index)

	# Get the plinth the buyer selected
	var selected_plinth = interaction.get("selected_soul_plinth")
	if selected_plinth and selected_plinth.displayed_soul:
		var soul_to_sell = selected_plinth.displayed_soul
		var inventory_manager = get_node("/root/Root/Gameplay/InventoryManager")

		# Remove soul from inventory (also removes from display)
		inventory_manager.remove_soul(soul_to_sell.id)
		print("Sold soul: %s (%s)" % [soul_to_sell.name, soul_to_sell.id])

		# Remove all other interactions requesting this same soul
		_remove_interactions_for_soul(soul_to_sell.id, index)

	# Remove this interaction
	interaction_manager.remove_interaction(index)

func _handle_seller_transaction(index: int, interaction: Dictionary) -> void:
	print("Handling seller transaction for interaction %d" % index)
	var soul_to_sell = interaction.get("soul_to_sell")
	if soul_to_sell:
		# Add soul to inventory
		var inventory_manager = get_node("/root/Root/Gameplay/InventoryManager")
		inventory_manager.add_soul(soul_to_sell)
		print("Bought soul: %s" % soul_to_sell.name)
	# Remove the interaction
	interaction_manager.remove_interaction(index)

func _reject_interaction(index: int) -> void:
	print("Rejecting interaction %d" % index)
	interaction_manager.remove_interaction(index)

func _on_interaction_added(_interaction: Dictionary) -> void:
	if visible:
		_refresh_list()

func _on_interaction_removed(_interaction: Dictionary) -> void:
	if visible:
		_refresh_list()

func _remove_interactions_for_soul(soul_id: String, exclude_index: int) -> void:
	"""Remove all interactions that reference a specific soul (except the one at exclude_index)"""
	var interactions = interaction_manager.get_pending_interactions()
	var indices_to_remove: Array[int] = []

	# Find all interactions that reference this soul
	for i in range(interactions.size()):
		if i == exclude_index:
			continue

		var interaction = interactions[i]
		if interaction.type == "buyer":
			var plinth = interaction.get("selected_soul_plinth")
			if plinth and plinth.displayed_soul and plinth.displayed_soul.id == soul_id:
				indices_to_remove.append(i)

	# Remove in reverse order to maintain correct indices
	indices_to_remove.reverse()
	for idx in indices_to_remove:
		print("Removing duplicate buyer request for sold soul")
		interaction_manager.remove_interaction(idx)
