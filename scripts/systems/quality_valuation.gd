extends RefCounted
class_name QualityValuation

## Centralized system for determining base value of soul qualities

## Get rarity tier for era/cod based on actual distribution in generation
static func get_era_rarity(era: int) -> String:
	# Based on RarityTables weighted distribution
	match era:
		SoulData.Era.CLASSICAL:
			return "Uncommon"
		SoulData.Era.ANCIENT:
			return "Rare"
		SoulData.Era.PREHISTORIC:
			return "Very Rare"
		SoulData.Era.MODERN:
			return "Common"
	return "Common"

static func get_cod_rarity(cod: int) -> String:
	# Based on RarityTables weighted distribution
	match cod:
		SoulData.CauseOfDeath.NATURAL:
			return "Common"
		SoulData.CauseOfDeath.ACCIDENT:
			return "Common"
		SoulData.CauseOfDeath.BATTLE:
			return "Uncommon"
		SoulData.CauseOfDeath.ILLNESS:
			return "Common"
		SoulData.CauseOfDeath.POISON:
			return "Uncommon"
		SoulData.CauseOfDeath.MURDERED:
			return "Rare"
		SoulData.CauseOfDeath.DROWNED:
			return "Uncommon"
		SoulData.CauseOfDeath.STARVED:
			return "Rare"
		SoulData.CauseOfDeath.FROZEN:
			return "Rare"
	return "Common"

## Get value for a fundamental quality (era or cod)
static func get_fundamental_value(rarity: String) -> int:
	match rarity:
		"Common":
			return 5
		"Uncommon":
			return 15
		"Rare":
			return 30
		"Very Rare":
			return 50
	return 5

## Get value for a stat based on its value
static func get_stat_value(stat_value: int) -> int:
	if stat_value >= 1 and stat_value <= 15:
		return 5
	elif stat_value >= 16 and stat_value <= 30:
		return 10
	elif stat_value >= 31 and stat_value <= 45:
		return 25
	elif stat_value >= 46 and stat_value <= 60:
		return 35
	elif stat_value >= 61 and stat_value <= 75:
		return 50
	elif stat_value >= 76 and stat_value <= 85:
		return 75
	elif stat_value >= 86 and stat_value <= 90:
		return 90
	elif stat_value >= 91 and stat_value <= 95:
		return 110
	elif stat_value >= 96 and stat_value <= 98:
		return 130
	elif stat_value >= 99 and stat_value <= 100:
		return 170
	return 5

## Get value for a stat with hint ranges
## Returns the base stat value divided by uncertainty penalty
static func get_stat_hint_value(hints: Array) -> int:
	if hints.size() == 0:
		return 25  # No hints, just presence

	# Find overlapping range from all hints
	var overlap_min = 0
	var overlap_max = 100

	for hint in hints:
		var range_data = _parse_range_hint(hint)
		if range_data:
			overlap_min = max(overlap_min, range_data.min)
			overlap_max = min(overlap_max, range_data.max)

	# If no valid overlap, treat as presence only
	if overlap_min > overlap_max:
		return 25

	# Calculate average of the range
	var avg_value = (overlap_min + overlap_max) / 2

	# Get base value for that average
	var base_value = get_stat_value(avg_value)

	# Calculate uncertainty penalty
	var range_spread = overlap_max - overlap_min
	var uncertainty_factor = (range_spread * 0.01) + 1.0

	# Return penalized value
	return int(base_value / uncertainty_factor)

static func _parse_range_hint(hint: String) -> Dictionary:
	if "-" in hint and hint != "Present":
		var parts = hint.split("-")
		if parts.size() == 2:
			var min_val = parts[0].to_int()
			var max_val = parts[1].to_int()
			if min_val >= 0 and max_val <= 100 and min_val < max_val:
				return {"min": min_val, "max": max_val}
	return {}

## Calculate total base value of a soul based on what's known about it
static func calculate_soul_base_value(soul: SoulData, discovery_log: DiscoveryLog) -> int:
	var total_value = 0

	# Era value
	if discovery_log.known_era:
		var rarity = get_era_rarity(soul.era)
		total_value += get_fundamental_value(rarity)
	else:
		total_value += 15  # Unknown era base value

	# Cause of death value
	if discovery_log.known_death:
		var rarity = get_cod_rarity(soul.causeOfDeath)
		total_value += get_fundamental_value(rarity)
	else:
		total_value += 15  # Unknown cod base value

	# Stat values
	for stat_key in soul.stats.keys():
		if discovery_log.knows_stat(stat_key):
			# Fully known stat
			total_value += get_stat_value(soul.stats[stat_key])
		elif discovery_log.has_stat_hints(stat_key):
			# Stat with hints
			var hints = discovery_log.get_stat_hints(stat_key)
			total_value += get_stat_hint_value(hints)
		else:
			# Unknown stat
			total_value += 15  # Unknown quality base value

	return total_value
