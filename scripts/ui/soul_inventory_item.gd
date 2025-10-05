extends VBoxContainer

## Individual soul item in the inventory list with expandable details


signal toggle_display_requested(soul_id: String, is_currently_displayed: bool)

var soul_data: SoulData
var is_on_display: bool = false
var is_expanded: bool = false
var refresh_timer: float = 0.0

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

	# Use Machine button
	var machine_button = Button.new()
	machine_button.text = "Use Machine"
	machine_button.custom_minimum_size = Vector2(120, 0)
	machine_button.pressed.connect(_on_machine_button_pressed)
	header_container.add_child(machine_button)

	# Details container (hidden by default)
	details_container = VBoxContainer.new()
	details_container.visible = false
	add_child(details_container)

	# Connect to machine manager signals
	var machine_manager = get_node("/root/Root/Gameplay/MachineManager")
	machine_manager.job_completed.connect(_on_job_completed)

	# Connect to advertisement manager signals
	var advertisement_manager = get_node("/root/Root/Gameplay/AdvertisementManager")
	advertisement_manager.advertisement_changed.connect(_on_advertisement_changed)

func _process(delta: float) -> void:
	# Refresh details periodically if expanded and job is running
	if is_expanded:
		var machine_manager = get_node("/root/Root/Gameplay/MachineManager")
		if machine_manager.is_soul_being_analyzed(soul_data.id):
			refresh_timer += delta
			if refresh_timer >= 0.5:  # Refresh every half second
				refresh_timer = 0.0
				_populate_details()

func _on_job_completed(job: MachineJob) -> void:
	# Refresh if this job was for our soul
	if job.soul_id == soul_data.id and is_expanded:
		_populate_details()

func _on_advertisement_changed(soul_id: String) -> void:
	# Refresh if advertisement changed for our soul and we're expanded
	if soul_id == soul_data.id and is_expanded:
		_populate_details()

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

func _on_machine_button_pressed() -> void:
	_show_machine_selection_popup()

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

	# Show active job status if any (centralized)
	MachineUIHelper.add_job_status_if_active(details_container, soul_data.id)

	# Add advertisement controls (only show if soul is on display)
	if is_on_display:
		_add_advertisement_controls(details_container, discovery_log)

func _show_machine_selection_popup() -> void:
	# Use centralized helper
	MachineUIHelper.show_machine_selection_popup(self, soul_data, func(_machine_type):
		# Refresh after machine starts
		if is_expanded:
			_populate_details()
	)

func _add_advertisement_controls(container: VBoxContainer, discovery_log: DiscoveryLog) -> void:
	# Separator
	var separator = HSeparator.new()
	container.add_child(separator)

	# Advertisement header
	var ad_header = Label.new()
	ad_header.text = "ADVERTISE PROPERTIES (what buyers see)"
	ad_header.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	container.add_child(ad_header)

	# Get or create advertisement
	var advertisement_manager = get_node("/root/Root/Gameplay/AdvertisementManager")
	var ad = advertisement_manager.get_advertisement(soul_data.id)

	# Indent container
	var indent_hbox = HBoxContainer.new()
	container.add_child(indent_hbox)

	var indent = Control.new()
	indent.custom_minimum_size = Vector2(40, 0)
	indent_hbox.add_child(indent)

	var controls_vbox = VBoxContainer.new()
	indent_hbox.add_child(controls_vbox)

	# Era checkbox (only if we know it)
	if discovery_log.known_era:
		var era_check = CheckBox.new()
		era_check.text = "Era: %s" % SoulData.Era.keys()[soul_data.era]
		era_check.button_pressed = ad.advertise_era
		era_check.toggled.connect(func(pressed: bool):
			ad.set_advertise_era(pressed)
			advertisement_manager.advertisement_changed.emit(soul_data.id)
		)
		controls_vbox.add_child(era_check)

	# Death checkbox (only if we know it)
	if discovery_log.known_death:
		var death_check = CheckBox.new()
		death_check.text = "Cause of Death: %s" % SoulData.CauseOfDeath.keys()[soul_data.causeOfDeath]
		death_check.button_pressed = ad.advertise_death
		death_check.toggled.connect(func(pressed: bool):
			ad.set_advertise_death(pressed)
			advertisement_manager.advertisement_changed.emit(soul_data.id)
		)
		controls_vbox.add_child(death_check)

	# Stats - show for both discovered (exact) and hinted (presence/range)
	var stats_to_show = {}  # stat_key -> {type: "exact"/"hint", value/hints}

	# Collect discovered stats (exact values)
	for stat_key in discovery_log.get_discovered_stats():
		stats_to_show[stat_key] = {
			"type": "exact",
			"value": soul_data.stats[stat_key]
		}

	# Collect stats with hints (presence or range)
	for stat_key in soul_data.stats.keys():
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
				# Exact value known - checkbox to advertise exact
				var stat_value = stat_info["value"]
				var stat_check = CheckBox.new()
				stat_check.text = "  %s: %d (exact)" % [stat_name, int(stat_value)]
				stat_check.button_pressed = ad.get_stat_advert_level(stat_key) == SoulAdvertisement.AdvertLevel.ADVERTISE_EXACT
				stat_check.toggled.connect(func(pressed: bool):
					if pressed:
						ad.advertise_stat_exact(stat_key, stat_value)
					else:
						ad.unadvertise_stat(stat_key)
					advertisement_manager.advertisement_changed.emit(soul_data.id)
				)
				controls_vbox.add_child(stat_check)

			else:
				# Only hints known - check if it's a range or just presence
				var hints = stat_info["hints"]
				var hint_text = ", ".join(hints)

				# Check if we have a range hint (format: "45-75")
				var range_hint = _parse_range_hint(hints)

				if range_hint:
					# Range hint - checkbox to advertise range
					var stat_check = CheckBox.new()
					stat_check.text = "  %s: %d-%d (range)" % [stat_name, range_hint.min, range_hint.max]
					stat_check.button_pressed = ad.get_stat_advert_level(stat_key) == SoulAdvertisement.AdvertLevel.ADVERTISE_RANGE
					stat_check.toggled.connect(func(pressed: bool):
						if pressed:
							ad.advertise_stat_range(stat_key, range_hint.min, range_hint.max)
						else:
							ad.unadvertise_stat(stat_key)
						advertisement_manager.advertisement_changed.emit(soul_data.id)
					)
					controls_vbox.add_child(stat_check)
				else:
					# Presence only - checkbox to advertise presence
					var stat_check = CheckBox.new()
					stat_check.text = "  %s (presence only)" % stat_name
					stat_check.button_pressed = ad.get_stat_advert_level(stat_key) == SoulAdvertisement.AdvertLevel.ADVERTISE_PRESENCE
					stat_check.toggled.connect(func(pressed: bool):
						if pressed:
							ad.advertise_stat_presence(stat_key)
						else:
							ad.unadvertise_stat(stat_key)
						advertisement_manager.advertisement_changed.emit(soul_data.id)
					)
					controls_vbox.add_child(stat_check)


## Parse range hints from hint array (e.g., ["45-75"])
## Returns {min: int, max: int} or empty dict if no range found
func _parse_range_hint(hints: Array) -> Dictionary:
	for hint in hints:
		# Check if hint is in "X-Y" format
		if "-" in hint and hint != "Present":
			var parts = hint.split("-")
			if parts.size() == 2:
				var min_val = parts[0].to_int()
				var max_val = parts[1].to_int()
				if min_val >= 0 and max_val <= 100 and min_val < max_val:
					return {"min": min_val, "max": max_val}
	return {}
