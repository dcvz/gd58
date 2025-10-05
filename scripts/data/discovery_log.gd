class_name DiscoveryLog
extends Resource

## Tracks what is known/discovered about a soul

# What we know for certain
var known_era: bool = false
var known_death: bool = false
var known_stats: Dictionary = {}  # stat_key -> actual_value

# Discovery hints/clues (from machines or sellers)
var era_hints: Array[String] = []  # e.g. "Not Ancient", "Not Prehistoric"
var death_hints: Array[String] = []  # e.g. "Not Natural", "Not Poison"
var stat_hints: Dictionary = {}  # stat_key -> Array of hint strings

## Record that we know the era for certain
func discover_era() -> void:
	known_era = true

## Record that we know the cause of death for certain
func discover_death() -> void:
	known_death = true

## Record that we know a stat's exact value
func discover_stat(stat_key: int, value: float) -> void:
	known_stats[stat_key] = value

## Add a hint about era (e.g. "Not Ancient")
func add_era_hint(hint: String) -> void:
	if not era_hints.has(hint):
		era_hints.append(hint)

## Add a hint about cause of death (e.g. "Not Natural")
func add_death_hint(hint: String) -> void:
	if not death_hints.has(hint):
		death_hints.append(hint)

## Add a hint about a stat (e.g. "Scientific: 50-70")
func add_stat_hint(stat_key: int, hint: String) -> void:
	if not stat_hints.has(stat_key):
		stat_hints[stat_key] = []
	if not stat_hints[stat_key].has(hint):
		stat_hints[stat_key].append(hint)

## Check if we know a specific stat
func knows_stat(stat_key: int) -> bool:
	return known_stats.has(stat_key)

## Get all discovered stat keys
func get_discovered_stats() -> Array:
	return known_stats.keys()

## Check if we have any hints about a stat
func has_stat_hints(stat_key: int) -> bool:
	return stat_hints.has(stat_key) and stat_hints[stat_key].size() > 0

## Get hints for a stat
func get_stat_hints(stat_key: int) -> Array[String]:
	if stat_hints.has(stat_key):
		var hints: Array[String] = []
		hints.assign(stat_hints[stat_key])
		return hints
	return []
