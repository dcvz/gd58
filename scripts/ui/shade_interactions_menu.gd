extends Control

## Menu for handling shade interactions (buyers and sellers)


var interaction_manager: Node
var game_loop_manager: Node
var interaction_list: VBoxContainer
var close_button: Button

# Auto-refresh timer for countdown updates
var refresh_timer: float = 0.0
const REFRESH_INTERVAL: float = 0.5  # Update every half second

func _process(delta: float) -> void:
	if not visible:
		return

	# Periodically refresh to update countdown timers
	refresh_timer += delta
	if refresh_timer >= REFRESH_INTERVAL:
		refresh_timer = 0.0
		_refresh_list()

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
	interaction_manager.interaction_expired.connect(_on_interaction_expired)

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
	# Clear existing items immediately to prevent duplicate clicks
	for child in interaction_list.get_children():
		child.free()

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

	# Header with countdown timer
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)

	var type_label = Label.new()
	type_label.text = "%s #%d" % [interaction.type.capitalize(), index + 1]
	type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(type_label)

	# Countdown timer
	var days_remaining = interaction_manager.get_days_remaining(interaction)
	var timer_label = Label.new()
	if days_remaining >= 1.0:
		timer_label.text = "⏱ %.1f days" % days_remaining
		timer_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	elif days_remaining >= 0.5:
		timer_label.text = "⏱ %.1f days" % days_remaining
		timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))  # Yellow warning
	else:
		timer_label.text = "⏱ %.1f days" % days_remaining
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # Red urgent
	header_hbox.add_child(timer_label)

	# Details based on type
	if interaction.type == "buyer":
		# Show soul being sold using centralized helper
		var plinth = interaction.get("selected_soul_plinth")
		if plinth and plinth.displayed_soul:
			var soul = plinth.displayed_soul

			var selling_label = Label.new()
			selling_label.text = "Your Soul:"
			selling_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))  # Gold
			vbox.add_child(selling_label)

			# Show discoveries with two-column layout (known vs clues)
			var discovery_manager = get_node("/root/Root/Gameplay/DiscoveryManager")
			var discovery_log = discovery_manager.get_discovery_log(soul.id)
			SoulDisplayHelper.create_two_column_discovery_layout(vbox, soul, discovery_log)

			# Add separator
			var separator = HSeparator.new()
			vbox.add_child(separator)

		# Display buyer interests
		var interests = interaction.get("interests", [])
		if interests.size() > 0:
			var matching_mode = interaction.get("matching_mode", InterestMatcher.MatchingMode.ALL)
			var mode_text = "ANY" if matching_mode == InterestMatcher.MatchingMode.ANY else "ALL"
			var mode_color = Color(0.3, 1.0, 0.5) if matching_mode == InterestMatcher.MatchingMode.ANY else Color(1.0, 0.6, 0.2)

			var wants_label = Label.new()
			wants_label.text = "Buyer wants [%s]:" % mode_text
			wants_label.add_theme_color_override("font_color", mode_color)
			vbox.add_child(wants_label)

			for interest in interests:
				var interest_label = Label.new()
				interest_label.text = "  • %s" % InterestMatcher.format_interest_for_display(interest)
				vbox.add_child(interest_label)

		# Display offer price
		var offer_price = interaction.get("offer_price", 0)
		var price_label = Label.new()
		price_label.text = "Offering: %d KP" % offer_price
		price_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))  # Green
		vbox.add_child(price_label)

		# Action buttons
		var button_hbox = HBoxContainer.new()
		vbox.add_child(button_hbox)

		var sell_button = Button.new()
		sell_button.text = "Sell Soul (%d KP)" % offer_price
		sell_button.pressed.connect(func(): _handle_buyer_transaction(index, interaction))
		button_hbox.add_child(sell_button)

		var reject_button = Button.new()
		reject_button.text = "Reject"
		reject_button.pressed.connect(func(): _reject_interaction(index))
		button_hbox.add_child(reject_button)

	elif interaction.type == "seller":
		var soul_to_sell = interaction.get("soul_to_sell")
		if soul_to_sell:
			var selling_label = Label.new()
			selling_label.text = "Seller's Soul:"
			selling_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))  # Blue
			vbox.add_child(selling_label)

			# Show seller's limited knowledge (ranges, not exact values)
			# Seller knowledge is generated when the interaction is created
			var seller_log = interaction.get("seller_knowledge")
			if seller_log:
				SoulDisplayHelper.create_two_column_discovery_layout(vbox, soul_to_sell, seller_log)
			else:
				# Fallback if seller_knowledge not set (shouldn't happen)
				var empty_log = DiscoveryLog.new()
				SoulDisplayHelper.create_two_column_discovery_layout(vbox, soul_to_sell, empty_log)

			# Show active job status if any (centralized)
			MachineUIHelper.add_job_status_if_active(vbox, soul_to_sell.id)

			# Add separator
			var separator = HSeparator.new()
			vbox.add_child(separator)

		# Display asking price
		var asking_price = interaction.get("asking_price", 0)
		var price_label = Label.new()
		price_label.text = "Asking: %d KP" % asking_price
		price_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))  # Orange
		vbox.add_child(price_label)

		# Action buttons
		var button_hbox = HBoxContainer.new()
		vbox.add_child(button_hbox)

		var buy_button = Button.new()
		buy_button.text = "Buy Soul (%d KP)" % asking_price
		buy_button.pressed.connect(func(): _handle_seller_transaction(index, interaction))
		button_hbox.add_child(buy_button)

		var machine_button = Button.new()
		machine_button.text = "Use Machine"
		machine_button.pressed.connect(func(): _show_seller_machine_menu(soul_to_sell))
		button_hbox.add_child(machine_button)

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
		var offer_price = interaction.get("offer_price", 0)
		var inventory_manager = get_node("/root/Root/Gameplay/InventoryManager")
		var currency_manager = get_node("/root/Root/Gameplay/CurrencyManager")

		# Add currency from sale and track the sale
		currency_manager.add_kp(offer_price)
		currency_manager.record_soul_sale()
		print("Sold soul: %s (%s) for %d KP" % [soul_to_sell.name, soul_to_sell.id, offer_price])

		# Remove soul from inventory (also removes from display)
		inventory_manager.remove_soul(soul_to_sell.id)

		# Remove all other interactions requesting this same soul
		_remove_interactions_for_soul(soul_to_sell.id, index)

	# Remove this interaction
	interaction_manager.remove_interaction(index)

func _handle_seller_transaction(index: int, interaction: Dictionary) -> void:
	print("Handling seller transaction for interaction %d" % index)
	var soul_to_sell = interaction.get("soul_to_sell")
	var asking_price = interaction.get("asking_price", 0)
	var currency_manager = get_node("/root/Root/Gameplay/CurrencyManager")

	if soul_to_sell:
		# Check if we can afford it
		if currency_manager.can_afford(asking_price):
			# Spend currency and track the purchase
			if currency_manager.spend_kp(asking_price):
				currency_manager.record_soul_purchase()
				# Add soul to inventory
				var inventory_manager = get_node("/root/Root/Gameplay/InventoryManager")
				inventory_manager.add_soul(soul_to_sell)

				# Transfer seller's knowledge to player's discovery log
				var discovery_manager = get_node("/root/Root/Gameplay/DiscoveryManager")
				var seller_knowledge = interaction.get("seller_knowledge")
				if seller_knowledge:
					# Transfer what the seller knew to the player
					var player_log = discovery_manager.get_discovery_log(soul_to_sell.id)

					# Transfer era/death knowledge
					if seller_knowledge.known_era:
						player_log.discover_era()

					if seller_knowledge.known_death:
						player_log.discover_death()

					# Transfer stat hints
					for stat_key in seller_knowledge.stat_hints.keys():
						var hints = seller_knowledge.get_stat_hints(stat_key)
						for hint in hints:
							player_log.add_stat_hint(stat_key, hint)

					print("Bought soul: %s for %d KP (inherited seller's knowledge)" % [soul_to_sell.name, asking_price])
				else:
					print("Bought soul: %s for %d KP (seller had no knowledge cached)" % [soul_to_sell.name, asking_price])
			else:
				print("Failed to spend KP!")
				return
		else:
			print("Cannot afford soul! Need %d KP" % asking_price)
			return

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

func _on_interaction_expired(_interaction: Dictionary) -> void:
	print("Interaction expired and removed from queue")
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

func _show_seller_machine_menu(soul: SoulData) -> void:
	# Use centralized helper
	MachineUIHelper.show_machine_selection_popup(self, soul, func(_machine_type):
		# Refresh to show job status
		_refresh_list()
	)
