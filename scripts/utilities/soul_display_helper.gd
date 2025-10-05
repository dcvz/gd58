class_name SoulDisplayHelper
extends RefCounted

## Centralized utility for creating soul information UI elements
## Used by inventory, interactions menu, and anywhere souls are displayed

## Add soul details (name, era, death, stats) to a VBoxContainer
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
