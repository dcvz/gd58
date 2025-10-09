extends VBoxContainer
class_name AdvertisementSection

## Self-contained advertisement controls section
## Just pass it soul data and it handles everything internally

@onready var era_checkbox: AdvertCheckBox = $ContentMargin/ControlsVBox/EraCheckbox
@onready var death_checkbox: AdvertCheckBox = $ContentMargin/ControlsVBox/DeathCheckbox
@onready var stats_label: Label = $ContentMargin/ControlsVBox/StatsLabel
@onready var stats_container: VBoxContainer = $ContentMargin/ControlsVBox/StatsContainer

const CHECKBOX_SCENE = preload("res://scenes/ui/components/advert_checkbox.tscn")

var current_soul: SoulData = null
var advertisement_manager: Node = null

func _ready() -> void:
	# Get manager reference
	await get_tree().process_frame
	advertisement_manager = get_node_or_null("/root/Root/Gameplay/AdvertisementManager")

	# Connect checkbox signals
	era_checkbox.toggled_with_data.connect(_on_checkbox_toggled)
	death_checkbox.toggled_with_data.connect(_on_checkbox_toggled)

## Main public API - call this to populate the section
func populate_for_soul(soul: SoulData, discovery_log: DiscoveryLog) -> void:
	current_soul = soul

	if not advertisement_manager:
		push_error("AdvertisementManager not found!")
		return

	var ad = advertisement_manager.get_advertisement(soul.id)

	# Configure era checkbox
	era_checkbox.visible = discovery_log.known_era
	if discovery_log.known_era:
		var era_name = SoulData.Era.keys()[soul.era]
		era_checkbox.setup("Era: %s" % era_name, {"type": "era"})
		era_checkbox.set_checked_silent(ad.advertise_era)

	# Configure death checkbox
	death_checkbox.visible = discovery_log.known_death
	if discovery_log.known_death:
		var death_name = SoulData.CauseOfDeath.keys()[soul.causeOfDeath]
		death_checkbox.setup("Cause of Death: %s" % death_name, {"type": "death"})
		death_checkbox.set_checked_silent(ad.advertise_death)

	# Configure stats
	_populate_stats(soul, discovery_log, ad)

func _populate_stats(soul: SoulData, discovery_log: DiscoveryLog, ad: SoulAdvertisement) -> void:
	# Clear existing stat checkboxes
	for child in stats_container.get_children():
		child.queue_free()

	# Gather stats to show
	var stats_to_show = {}

	for stat_key in discovery_log.get_discovered_stats():
		stats_to_show[stat_key] = {
			"type": "exact",
			"value": soul.stats[stat_key]
		}

	for stat_key in soul.stats.keys():
		if not stats_to_show.has(stat_key) and discovery_log.has_stat_hints(stat_key):
			stats_to_show[stat_key] = {
				"type": "hint",
				"hints": discovery_log.get_stat_hints(stat_key)
			}

	# Show/hide stats section
	stats_label.visible = stats_to_show.size() > 0

	# Create stat checkboxes
	for stat_key in stats_to_show.keys():
		var stat_info = stats_to_show[stat_key]
		var stat_name = SoulData.SoulAttribute.keys()[stat_key]

		var checkbox: AdvertCheckBox = CHECKBOX_SCENE.instantiate()
		var user_data = {"type": "stat", "stat_key": stat_key}

		if stat_info["type"] == "exact":
			var stat_value = stat_info["value"]
			checkbox.setup("  %s: %d (exact)" % [stat_name, int(stat_value)], user_data.duplicate())
			user_data["advert_type"] = "exact"
			user_data["value"] = stat_value
			checkbox.user_data = user_data
			checkbox.set_checked_silent(
				ad.get_stat_advert_level(stat_key) == SoulAdvertisement.AdvertLevel.ADVERTISE_EXACT
			)
		else:
			var hints = stat_info["hints"]
			var range_hint = _parse_range_hint(hints)

			if range_hint:
				checkbox.setup("  %s: %d-%d (range)" % [stat_name, range_hint.min, range_hint.max], user_data.duplicate())
				user_data["advert_type"] = "range"
				user_data["min"] = range_hint.min
				user_data["max"] = range_hint.max
				checkbox.user_data = user_data
				checkbox.set_checked_silent(
					ad.get_stat_advert_level(stat_key) == SoulAdvertisement.AdvertLevel.ADVERTISE_RANGE
				)
			else:
				checkbox.setup("  %s (presence only)" % stat_name, user_data.duplicate())
				user_data["advert_type"] = "presence"
				checkbox.user_data = user_data
				checkbox.set_checked_silent(
					ad.get_stat_advert_level(stat_key) == SoulAdvertisement.AdvertLevel.ADVERTISE_PRESENCE
				)

		# Connect signal
		checkbox.toggled_with_data.connect(_on_checkbox_toggled)
		stats_container.add_child(checkbox)

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

# Universal signal handler - all checkboxes use same callback
func _on_checkbox_toggled(is_pressed: bool, data: Dictionary) -> void:
	if not current_soul or not advertisement_manager:
		return

	var ad = advertisement_manager.get_advertisement(current_soul.id)
	var checkbox_type = data.get("type", "")

	match checkbox_type:
		"era":
			ad.set_advertise_era(is_pressed)
		"death":
			ad.set_advertise_death(is_pressed)
		"stat":
			var stat_key = data["stat_key"]
			if is_pressed:
				var advert_type = data.get("advert_type", "")
				match advert_type:
					"exact":
						ad.advertise_stat_exact(stat_key, data["value"])
					"range":
						ad.advertise_stat_range(stat_key, data["min"], data["max"])
					"presence":
						ad.advertise_stat_presence(stat_key)
			else:
				ad.unadvertise_stat(stat_key)

	advertisement_manager.advertisement_changed.emit(current_soul.id)
