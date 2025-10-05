extends Control

## Context menu that appears when clicking a soul in storage

var current_soul: SoulData = null
var panel: PanelContainer
var vbox: VBoxContainer
var inventory_manager: Node
var display_manager: Node

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block clicks when hidden

	# Create UI
	panel = PanelContainer.new()
	add_child(panel)

	vbox = VBoxContainer.new()
	panel.add_child(vbox)

	# Get manager references
	await get_tree().process_frame
	inventory_manager = get_node("/root/Root/Gameplay/InventoryManager")
	display_manager = get_node("/root/Root/Gameplay/DisplayManager")

	# Connect to click manager
	var click_manager = get_node("/root/Root/Gameplay/ClickManager")
	if click_manager:
		click_manager.soul_clicked.connect(_on_soul_clicked)

func _on_soul_clicked(soul: SoulData, world_position: Vector3) -> void:
	show_for_soul(soul, get_viewport().get_mouse_position())

func show_for_soul(soul: SoulData, screen_position: Vector2) -> void:
	current_soul = soul
	_rebuild_menu()

	# Position at mouse
	panel.position = screen_position

	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP

func _rebuild_menu() -> void:
	# Clear existing content
	for child in vbox.get_children():
		child.queue_free()

	if not current_soul:
		return

	# Title
	var title = Label.new()
	title.text = current_soul.name
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	var separator1 = HSeparator.new()
	vbox.add_child(separator1)

	# Get discovery log
	var discovery_manager = get_node("/root/Root/Gameplay/DiscoveryManager")
	var discovery_log = discovery_manager.get_discovery_log(current_soul.id)

	# Create two-column layout: Known (left) | Clues (right)
	var columns_hbox = HBoxContainer.new()
	columns_hbox.custom_minimum_size = Vector2(500, 0)
	vbox.add_child(columns_hbox)

	# Left column: Known/Discovered
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(230, 0)
	columns_hbox.add_child(left_vbox)

	# Spacer between columns
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	columns_hbox.add_child(spacer)

	# Right column: Hints/Unknowns
	var right_vbox = VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(230, 0)
	columns_hbox.add_child(right_vbox)

	# Populate with discovery-aware display
	SoulDisplayHelper.add_soul_details_with_discoveries(left_vbox, right_vbox, current_soul, discovery_log)

	# Show active job status if any
	MachineUIHelper.add_job_status_if_active(vbox, current_soul.id)

	# Add advertisement controls if soul is on display
	if inventory_manager.display_slots.has(current_soul.id):
		_add_advertisement_controls(vbox, discovery_log)

	var separator2 = HSeparator.new()
	vbox.add_child(separator2)

	# Action buttons
	var buttons_hbox = HBoxContainer.new()
	vbox.add_child(buttons_hbox)

	# Display on Plinth button
	var display_btn = Button.new()
	display_btn.text = "Display on Plinth"
	display_btn.pressed.connect(_on_display_pressed)
	buttons_hbox.add_child(display_btn)

	# Use Machine button
	var machine_btn = Button.new()
	machine_btn.text = "Use Machine"
	machine_btn.pressed.connect(_on_machine_pressed)
	buttons_hbox.add_child(machine_btn)

	# Discard Soul button
	var discard_btn = Button.new()
	discard_btn.text = "Discard"
	discard_btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	discard_btn.pressed.connect(_on_discard_pressed)
	buttons_hbox.add_child(discard_btn)

func hide_menu() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_soul = null

func _on_display_pressed() -> void:
	if current_soul and inventory_manager:
		var success = inventory_manager.add_to_display(current_soul.id)
		if success:
			print("[ContextMenu] Added '%s' to display" % current_soul.name)
		else:
			print("[ContextMenu] Failed to add to display (slots full or already displayed)")
		hide_menu()

func _on_machine_pressed() -> void:
	if current_soul:
		# Show machine selection popup
		MachineUIHelper.show_machine_selection_popup(self, current_soul)
		hide_menu()

func _on_discard_pressed() -> void:
	if current_soul:
		# Show confirmation dialog before discarding
		_show_discard_confirmation()
		hide_menu()

func _input(event: InputEvent) -> void:
	# Close menu on any click outside
	if visible and event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Check if click is outside our panel
			var mouse_pos = get_viewport().get_mouse_position()
			var rect = Rect2(panel.global_position, panel.size)
			if not rect.has_point(mouse_pos):
				hide_menu()

func _add_advertisement_controls(container: VBoxContainer, discovery_log: DiscoveryLog) -> void:
	# Use the same advertisement controls as soul_inventory_item.gd
	var separator = HSeparator.new()
	container.add_child(separator)

	var ad_header = Label.new()
	ad_header.text = "ADVERTISE PROPERTIES (what buyers see)"
	ad_header.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	container.add_child(ad_header)

	var advertisement_manager = get_node("/root/Root/Gameplay/AdvertisementManager")
	var ad = advertisement_manager.get_advertisement(current_soul.id)

	var indent_hbox = HBoxContainer.new()
	container.add_child(indent_hbox)

	var indent = Control.new()
	indent.custom_minimum_size = Vector2(40, 0)
	indent_hbox.add_child(indent)

	var controls_vbox = VBoxContainer.new()
	indent_hbox.add_child(controls_vbox)

	# Era checkbox
	if discovery_log.known_era:
		var era_check = CheckBox.new()
		era_check.text = "Era: %s" % SoulData.Era.keys()[current_soul.era]
		era_check.button_pressed = ad.advertise_era
		era_check.toggled.connect(func(pressed: bool):
			ad.set_advertise_era(pressed)
			advertisement_manager.advertisement_changed.emit(current_soul.id)
		)
		controls_vbox.add_child(era_check)

	# Death checkbox
	if discovery_log.known_death:
		var death_check = CheckBox.new()
		death_check.text = "Cause of Death: %s" % SoulData.CauseOfDeath.keys()[current_soul.causeOfDeath]
		death_check.button_pressed = ad.advertise_death
		death_check.toggled.connect(func(pressed: bool):
			ad.set_advertise_death(pressed)
			advertisement_manager.advertisement_changed.emit(current_soul.id)
		)
		controls_vbox.add_child(death_check)

	# Stats
	var stats_to_show = {}

	for stat_key in discovery_log.get_discovered_stats():
		stats_to_show[stat_key] = {
			"type": "exact",
			"value": current_soul.stats[stat_key]
		}

	for stat_key in current_soul.stats.keys():
		if not stats_to_show.has(stat_key) and discovery_log.has_stat_hints(stat_key):
			stats_to_show[stat_key] = {
				"type": "hint",
				"hints": discovery_log.get_stat_hints(stat_key)
			}

	if stats_to_show.size() > 0:
		var stats_label = Label.new()
		stats_label.text = "Stats:"
		controls_vbox.add_child(stats_label)

		for stat_key in stats_to_show.keys():
			var stat_info = stats_to_show[stat_key]
			var stat_name = SoulData.SoulAttribute.keys()[stat_key]

			if stat_info["type"] == "exact":
				var stat_value = stat_info["value"]
				var stat_check = CheckBox.new()
				stat_check.text = "  %s: %d (exact)" % [stat_name, int(stat_value)]
				stat_check.button_pressed = ad.get_stat_advert_level(stat_key) == SoulAdvertisement.AdvertLevel.ADVERTISE_EXACT
				stat_check.toggled.connect(func(pressed: bool):
					if pressed:
						ad.advertise_stat_exact(stat_key, stat_value)
					else:
						ad.unadvertise_stat(stat_key)
					advertisement_manager.advertisement_changed.emit(current_soul.id)
				)
				controls_vbox.add_child(stat_check)
			else:
				var hints = stat_info["hints"]
				var range_hint = _parse_range_hint(hints)

				if range_hint:
					var stat_check = CheckBox.new()
					stat_check.text = "  %s: %d-%d (range)" % [stat_name, range_hint.min, range_hint.max]
					stat_check.button_pressed = ad.get_stat_advert_level(stat_key) == SoulAdvertisement.AdvertLevel.ADVERTISE_RANGE
					stat_check.toggled.connect(func(pressed: bool):
						if pressed:
							ad.advertise_stat_range(stat_key, range_hint.min, range_hint.max)
						else:
							ad.unadvertise_stat(stat_key)
						advertisement_manager.advertisement_changed.emit(current_soul.id)
					)
					controls_vbox.add_child(stat_check)
				else:
					var stat_check = CheckBox.new()
					stat_check.text = "  %s (presence only)" % stat_name
					stat_check.button_pressed = ad.get_stat_advert_level(stat_key) == SoulAdvertisement.AdvertLevel.ADVERTISE_PRESENCE
					stat_check.toggled.connect(func(pressed: bool):
						if pressed:
							ad.advertise_stat_presence(stat_key)
						else:
							ad.unadvertise_stat(stat_key)
						advertisement_manager.advertisement_changed.emit(current_soul.id)
					)
					controls_vbox.add_child(stat_check)

func _parse_range_hint(hints: Array) -> Dictionary:
	for hint in hints:
		if "-" in hint and hint != "Present":
			var parts = hint.split("-")
			if parts.size() == 2:
				var min_val = parts[0].to_int()
				var max_val = parts[1].to_int()
				if min_val >= 0 and max_val <= 100 and min_val < max_val:
					return {"min": min_val, "max": max_val}
	return {}

func _show_discard_confirmation() -> void:
	# Show confirmation dialog before permanently removing soul
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "Permanently discard '%s'?\n\nThis cannot be undone." % current_soul.name
	confirm.ok_button_text = "Discard"
	confirm.cancel_button_text = "Keep"
	add_child(confirm)

	var soul_id_to_discard = current_soul.id
	confirm.confirmed.connect(func():
		if inventory_manager:
			inventory_manager.remove_soul(soul_id_to_discard)
			print("[ContextMenu] Discarded soul: %s" % soul_id_to_discard)
		confirm.queue_free()
	)
	confirm.canceled.connect(func(): confirm.queue_free())

	confirm.popup_centered()
