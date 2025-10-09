extends Control

## Context menu that appears when clicking a soul in storage
var current_soul: SoulData = null
var inventory_manager: Node
var display_manager: Node

# UI node references (from scene)
@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/MainVBox/TitleLabel
@onready var left_vbox: VBoxContainer = $Panel/MainVBox/ColumnsHBox/LeftVBox
@onready var right_vbox: VBoxContainer = $Panel/MainVBox/ColumnsHBox/RightVBox
@onready var job_status_container: VBoxContainer = $Panel/MainVBox/JobStatusContainer
@onready var advertisement_section: AdvertisementSection = $Panel/MainVBox/AdvertisementSection
@onready var display_button: Button = $Panel/MainVBox/ButtonsHBox/DisplayButton
@onready var storage_button: Button = $Panel/MainVBox/ButtonsHBox/StorageButton
@onready var analyze_button: Button = $Panel/MainVBox/ButtonsHBox/AnalyzeButton
@onready var discard_button: Button = $Panel/MainVBox/ButtonsHBox/DiscardButton

func _ready() -> void:
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
	if not current_soul:
		return

	# Update title
	title_label.text = current_soul.name

	# Clear dynamic content containers
	_clear_container(left_vbox)
	_clear_container(right_vbox)
	_clear_container(job_status_container)

	# Get discovery log
	var discovery_manager = get_node("/root/Root/Gameplay/DiscoveryManager")
	var discovery_log = discovery_manager.get_discovery_log(current_soul.id)

	# Populate with discovery-aware display
	SoulDisplayHelper.add_soul_details_with_discoveries(left_vbox, right_vbox, current_soul, discovery_log)

	# Show active job status if any
	MachineUIHelper.add_job_status_if_active(job_status_container, current_soul.id)

	# Configure advertisement section (component handles everything internally!)
	var is_on_display = inventory_manager.display_slots.has(current_soul.id)
	advertisement_section.visible = is_on_display

	if is_on_display:
		advertisement_section.populate_for_soul(current_soul, discovery_log)

	# Update button visibility based on display status
	display_button.visible = not is_on_display
	storage_button.visible = is_on_display

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

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

func _on_send_to_storage_pressed() -> void:
	if current_soul and inventory_manager:
		# Remove from display (will automatically go to storage)
		inventory_manager.remove_from_display(current_soul.id)
		print("[ContextMenu] Sent '%s' to storage" % current_soul.name)
		hide_menu()

func _on_machine_pressed() -> void:
	if current_soul:
		# Check if soul is on display
		var is_on_display = inventory_manager.display_slots.has(current_soul.id)

		# If on display, send to storage first (machines work on storage souls)
		if is_on_display:
			inventory_manager.remove_from_display(current_soul.id)
			print("[ContextMenu] Moved '%s' to storage for analysis" % current_soul.name)

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
