class_name SoulDisplayHelper
extends RefCounted

## Centralized utility for creating soul information UI elements
## Handles both fully revealed souls and partially discovered souls

## Add soul details with discovery log (shows known vs unknown/hints)
## Left side: concrete discoveries | Right side: hints and unknowns
static func add_soul_details_with_discoveries(left_container: VBoxContainer, right_container: VBoxContainer, soul: SoulData, discovery_log: DiscoveryLog) -> void:
	if not soul:
		return

	# LEFT SIDE: Known/Discovered information
	var known_label = Label.new()
	known_label.text = "Known:"
	known_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	left_container.add_child(known_label)

	# Soul name (always known)
	var name_label = Label.new()
	name_label.text = soul.name
	name_label.add_theme_font_size_override("font_size", 16)
	left_container.add_child(name_label)

	# Era (if discovered)
	if discovery_log.known_era:
		var era_label = Label.new()
		era_label.text = "Era: %s" % SoulData.Era.keys()[soul.era]
		left_container.add_child(era_label)

	# Cause of Death (if discovered)
	if discovery_log.known_death:
		var death_label = Label.new()
		death_label.text = "Death: %s" % SoulData.CauseOfDeath.keys()[soul.causeOfDeath]
		left_container.add_child(death_label)

	# Known stats
	var discovered_stats = discovery_log.get_discovered_stats()
	if discovered_stats.size() > 0:
		var stats_label = Label.new()
		stats_label.text = "Stats:"
		left_container.add_child(stats_label)

		for stat_key in discovered_stats:
			var stat_value = discovery_log.known_stats[stat_key]
			var stat_item = Label.new()
			stat_item.text = "  • %s: %d%%" % [SoulData.SoulAttribute.keys()[stat_key], int(stat_value)]
			left_container.add_child(stat_item)

	# RIGHT SIDE: Hints and unknowns
	var hints_label = Label.new()
	hints_label.text = "Clues:"
	hints_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
	right_container.add_child(hints_label)

	# Era hints or ???
	if not discovery_log.known_era:
		if discovery_log.era_hints.size() > 0:
			var era_hint_label = Label.new()
			era_hint_label.text = "Era hints:"
			right_container.add_child(era_hint_label)
			for hint in discovery_log.era_hints:
				var hint_item = Label.new()
				hint_item.text = "  • %s" % hint
				hint_item.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
				right_container.add_child(hint_item)
		else:
			var unknown_era = Label.new()
			unknown_era.text = "Era: ???"
			unknown_era.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			right_container.add_child(unknown_era)

	# Death hints or ???
	if not discovery_log.known_death:
		if discovery_log.death_hints.size() > 0:
			var death_hint_label = Label.new()
			death_hint_label.text = "Death hints:"
			right_container.add_child(death_hint_label)
			for hint in discovery_log.death_hints:
				var hint_item = Label.new()
				hint_item.text = "  • %s" % hint
				hint_item.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
				right_container.add_child(hint_item)
		else:
			var unknown_death = Label.new()
			unknown_death.text = "Death: ???"
			unknown_death.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			right_container.add_child(unknown_death)

	# Stats - show ALL stats (known count), with hints or ??? for undiscovered ones
	if soul.stats.size() > 0:
		var has_unknown_stats = false
		for stat_key in soul.stats.keys():
			if not discovery_log.knows_stat(stat_key):
				# Show hints if we have them
				if discovery_log.has_stat_hints(stat_key):
					var stat_name = SoulData.SoulAttribute.keys()[stat_key]
					var hints = discovery_log.get_stat_hints(stat_key)
					for hint in hints:
						var hint_item = Label.new()
						hint_item.text = "  • %s: %s" % [stat_name, hint]
						hint_item.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
						right_container.add_child(hint_item)
				else:
					# Show as ??? (stat exists but totally unknown)
					has_unknown_stats = true

		# Show count of completely unknown stats
		if has_unknown_stats:
			var unknown_count = 0
			for stat_key in soul.stats.keys():
				if not discovery_log.knows_stat(stat_key) and not discovery_log.has_stat_hints(stat_key):
					unknown_count += 1

			var unknown_stats_label = Label.new()
			if unknown_count == 1:
				unknown_stats_label.text = "  • 1 stat: ???"
			else:
				unknown_stats_label.text = "  • %d stats: ???" % unknown_count
			unknown_stats_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			right_container.add_child(unknown_stats_label)

## Add soul details (fully revealed - for buyers/sellers who know everything)
static func add_soul_details_to_container(container: VBoxContainer, soul: SoulData) -> void:
	if not soul:
		return

	# Soul name
	var name_label = Label.new()
	name_label.text = soul.name
	name_label.add_theme_font_size_override("font_size", 16)
	container.add_child(name_label)

	# Era
	var era_label = Label.new()
	era_label.text = "Era: %s" % SoulData.Era.keys()[soul.era]
	container.add_child(era_label)

	# Cause of Death
	var death_label = Label.new()
	death_label.text = "Death: %s" % SoulData.CauseOfDeath.keys()[soul.causeOfDeath]
	container.add_child(death_label)

	# Stats
	if soul.stats.size() > 0:
		var stats_label = Label.new()
		stats_label.text = "Stats:"
		container.add_child(stats_label)

		for stat_key in soul.stats.keys():
			var stat_value = soul.stats[stat_key]
			var stat_item = Label.new()
			stat_item.text = "  • %s: %d%%" % [SoulData.SoulAttribute.keys()[stat_key], int(stat_value)]
			container.add_child(stat_item)
	else:
		var no_stats_label = Label.new()
		no_stats_label.text = "Stats: None"
		no_stats_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		container.add_child(no_stats_label)

## Create a compact one-line summary of a soul (for tight spaces)
static func get_soul_summary(soul: SoulData) -> String:
	if not soul:
		return "Unknown Soul"

	var stats_count = soul.stats.size()
	return "%s (%s, %d stats)" % [soul.name, SoulData.Era.keys()[soul.era], stats_count]

## Create a detailed multi-line description of a soul
static func get_soul_description(soul: SoulData) -> String:
	if not soul:
		return "Unknown Soul"

	var desc = "%s\n" % soul.name
	desc += "Era: %s\n" % SoulData.Era.keys()[soul.era]
	desc += "Death: %s\n" % SoulData.CauseOfDeath.keys()[soul.causeOfDeath]

	if soul.stats.size() > 0:
		desc += "Stats:\n"
		for stat_key in soul.stats.keys():
			var stat_value = soul.stats[stat_key]
			desc += "  • %s: %d%%\n" % [SoulData.SoulAttribute.keys()[stat_key], int(stat_value)]
	else:
		desc += "Stats: None\n"

	return desc

## Create two-column layout container with discoveries (helper to reduce duplication)
## Returns the parent HBoxContainer
static func create_two_column_discovery_layout(parent_container: VBoxContainer, soul: SoulData, discovery_log: DiscoveryLog) -> void:
	var columns_hbox = HBoxContainer.new()
	parent_container.add_child(columns_hbox)

	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(230, 0)
	columns_hbox.add_child(left_vbox)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	columns_hbox.add_child(spacer)

	var right_vbox = VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(230, 0)
	columns_hbox.add_child(right_vbox)

	add_soul_details_with_discoveries(left_vbox, right_vbox, soul, discovery_log)

## Generate a "seller's knowledge" discovery log for a soul
## Sellers have imperfect knowledge - they know ranges, not exact values
## This creates a temporary DiscoveryLog with range hints for a few random stats
static func create_seller_knowledge(soul: SoulData, range_width: int = 25) -> DiscoveryLog:
	var seller_log = DiscoveryLog.new()

	# Sellers might know Era and Death (30% chance for each)
	if randf() < 0.3:
		seller_log.discover_era()

	if randf() < 0.3:
		seller_log.discover_death()

	# Sellers know a few random stats (1-3) as ranges
	var all_stat_keys = soul.stats.keys()
	if all_stat_keys.size() > 0:
		all_stat_keys.shuffle()
		var num_stats_known = randi_range(1, min(3, all_stat_keys.size()))

		for i in range(num_stats_known):
			var stat_key = all_stat_keys[i]
			var actual_value = soul.stats[stat_key]

			# Generate a range centered on the actual value
			var min_val = max(0, actual_value - range_width / 2)
			var max_val = min(100, actual_value + range_width / 2)

			var hint = "%d-%d" % [int(min_val), int(max_val)]
			seller_log.add_stat_hint(stat_key, hint)

	return seller_log
