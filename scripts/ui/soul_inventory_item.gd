extends VBoxContainer

## Individual soul item in the inventory list with expandable details


signal toggle_display_requested(soul_id: String, is_currently_displayed: bool)

var soul_data: SoulData
var is_on_display: bool = false
var is_expanded: bool = false

# UI Elements (created dynamically)
var header_container: HBoxContainer
var name_label: Label
var era_label: Label
var expand_button: Button
var display_button: Button
var details_container: VBoxContainer

func _ready() -> void:
	# Create header row
	header_container = HBoxContainer.new()
	header_container.custom_minimum_size = Vector2(0, 40)
	add_child(header_container)

	# Expand button (▶/▼)
	expand_button = Button.new()
	expand_button.text = "▶"
	expand_button.custom_minimum_size = Vector2(30, 0)
	expand_button.pressed.connect(_on_expand_pressed)
	header_container.add_child(expand_button)

	# Name label
	name_label = Label.new()
	name_label.custom_minimum_size = Vector2(150, 0)
	header_container.add_child(name_label)

	# Era label
	era_label = Label.new()
	era_label.custom_minimum_size = Vector2(120, 0)
	header_container.add_child(era_label)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_container.add_child(spacer)

	# Display button
	display_button = Button.new()
	display_button.custom_minimum_size = Vector2(150, 0)
	display_button.pressed.connect(_on_button_pressed)
	header_container.add_child(display_button)

	# Details container (hidden by default)
	details_container = VBoxContainer.new()
	details_container.visible = false
	add_child(details_container)

func setup(soul: SoulData, on_display: bool) -> void:
	soul_data = soul
	is_on_display = on_display

	name_label.text = soul.name
	era_label.text = str(SoulData.Era.keys()[soul.era])

	_update_button_text()

func _update_button_text() -> void:
	if is_on_display:
		display_button.text = "Remove from Sale"
	else:
		display_button.text = "Put for Sale"

func _on_button_pressed() -> void:
	toggle_display_requested.emit(soul_data.id, is_on_display)

func _on_expand_pressed() -> void:
	is_expanded = !is_expanded

	if is_expanded:
		expand_button.text = "▼"
		details_container.visible = true
		_populate_details()
	else:
		expand_button.text = "▶"
		details_container.visible = false

func _populate_details() -> void:
	# Clear existing details
	for child in details_container.get_children():
		child.free()

	# Get discovery log
	var discovery_manager = get_node("/root/Root/Gameplay/DiscoveryManager")
	var discovery_log = discovery_manager.get_discovery_log(soul_data.id)

	# Create two-column layout: Known (left) | Clues (right)
	var columns_hbox = HBoxContainer.new()
	columns_hbox.custom_minimum_size = Vector2(500, 0)
	details_container.add_child(columns_hbox)

	# Left indent
	var indent = Control.new()
	indent.custom_minimum_size = Vector2(40, 0)
	columns_hbox.add_child(indent)

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
	SoulDisplayHelper.add_soul_details_with_discoveries(left_vbox, right_vbox, soul_data, discovery_log)
