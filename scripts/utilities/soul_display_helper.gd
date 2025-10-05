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

	# Era hints
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
			unknown_era.text = "Era: Unknown"
			unknown_era.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			right_container.add_child(unknown_era)

	# Death hints
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
			unknown_death.text = "Death: Unknown"
			unknown_death.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			right_container.add_child(unknown_death)

	# Stat hints (only show if we have hints, otherwise don't reveal the stat exists)
	for stat_key in soul.stats.keys():
		if not discovery_log.knows_stat(stat_key):
			if discovery_log.has_stat_hints(stat_key):
				var stat_name = SoulData.SoulAttribute.keys()[stat_key]
				var hints = discovery_log.get_stat_hints(stat_key)
				for hint in hints:
					var hint_item = Label.new()
					hint_item.text = "  • %s: %s" % [stat_name, hint]
					hint_item.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
					right_container.add_child(hint_item)

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
