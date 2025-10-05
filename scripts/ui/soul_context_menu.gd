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
	# Clear existing buttons
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

	# Display on Plinth button
	var display_btn = Button.new()
	display_btn.text = "Display on Plinth"
	display_btn.pressed.connect(_on_display_pressed)
	vbox.add_child(display_btn)

	# Use Machine button
	var machine_btn = Button.new()
	machine_btn.text = "Use Machine"
	machine_btn.pressed.connect(_on_machine_pressed)
	vbox.add_child(machine_btn)

	# View Details button
	var details_btn = Button.new()
	details_btn.text = "View Details"
	details_btn.pressed.connect(_on_details_pressed)
	vbox.add_child(details_btn)

	var separator2 = HSeparator.new()
	vbox.add_child(separator2)

	# Discard Soul button
	var discard_btn = Button.new()
	discard_btn.text = "Discard Soul"
	discard_btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	discard_btn.pressed.connect(_on_discard_pressed)
	vbox.add_child(discard_btn)

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

func _on_details_pressed() -> void:
	if current_soul:
		# Show detailed soul information popup
		_show_soul_details_popup()
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

func _show_soul_details_popup() -> void:
	# Create a detailed popup showing all discovered information about the soul
	var popup = AcceptDialog.new()
	popup.title = current_soul.name
	popup.dialog_text = ""
	popup.min_size = Vector2(500, 400)
	add_child(popup)

	# Build detailed info
	var content_vbox = VBoxContainer.new()
	popup.add_child(content_vbox)

	# Get discoveries first
	var discovery_manager = get_node("/root/Root/Gameplay/DiscoveryManager")
	var discovery_log = discovery_manager.get_discovery_log(current_soul.id)

	# Basic info - only show what we know
	var info_label = Label.new()
	var info_text = "Soul ID: %s\n" % current_soul.id.substr(0, 8)

	if discovery_log.known_era:
		var era_name = SoulData.Era.keys()[current_soul.era]
		info_text += "Era: %s\n" % era_name
	else:
		info_text += "Era: Unknown\n"

	if discovery_log.known_death:
		var death_name = SoulData.CauseOfDeath.keys()[current_soul.causeOfDeath]
		info_text += "Cause of Death: %s" % death_name
	else:
		info_text += "Cause of Death: Unknown"

	info_label.text = info_text
	content_vbox.add_child(info_label)

	var separator = HSeparator.new()
	content_vbox.add_child(separator)

	# Add two-column layout for discoveries
	SoulDisplayHelper.create_two_column_discovery_layout(content_vbox, current_soul, discovery_log)

	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

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
