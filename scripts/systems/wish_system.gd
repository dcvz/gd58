extends RefCounted
class_name WishSystem

## Centralized system for collector wishes and matching

enum WishType {
	STAT_PRESENCE,      # Just checking if stat exists (early game)
	STAT_RANGE,         # Stat within a range (mid game)
	ERA,                # Specific era match
	CAUSE_OF_DEATH,     # Specific cause of death match
	MULTI_STAT          # Multiple stats with ranges (late game)
}

## Represents a single wish from a collector
class Wish:
	var type: WishType
	var stat_key: int = -1  # For STAT_PRESENCE, STAT_RANGE
	var min_value: int = 0  # For STAT_RANGE
	var max_value: int = 100  # For STAT_RANGE
	var era: int = -1  # For ERA
	var cause_of_death: int = -1  # For CAUSE_OF_DEATH
	var multi_requirements: Array = []  # For MULTI_STAT: [{stat_key, min, max}, ...]

	func _init(wish_type: WishType):
		type = wish_type

	func get_description() -> String:
		match type:
			WishType.STAT_PRESENCE:
				return "%s (any)" % SoulData.SoulAttribute.keys()[stat_key]
			WishType.STAT_RANGE:
				return "%s: %d-%d" % [SoulData.SoulAttribute.keys()[stat_key], min_value, max_value]
			WishType.ERA:
				return "Era: %s" % SoulData.Era.keys()[era]
			WishType.CAUSE_OF_DEATH:
				return "Death: %s" % SoulData.CauseOfDeath.keys()[cause_of_death]
			WishType.MULTI_STAT:
				var parts = []
				for req in multi_requirements:
					parts.append("%s: %d-%d" % [SoulData.SoulAttribute.keys()[req.stat_key], req.min, req.max])
				return " AND ".join(parts)
		return "Unknown wish"

## Generate wishes for a collector based on current cycle
static func generate_collector_wishes(current_cycle: int) -> Array:
	var wishes: Array = []

	# Determine number of wishes (more early, fewer late)
	var num_wishes: int
	if current_cycle <= 5:
		num_wishes = randi_range(2, 3)  # Early: 2-3 wishes
	elif current_cycle <= 10:
		num_wishes = randi_range(1, 2)  # Mid: 1-2 wishes
	else:
		num_wishes = 1  # Late: 1 wish

	# Determine wish complexity based on cycle
	for i in range(num_wishes):
		var wish: Wish

		if current_cycle <= 5:
			# Early game: simple wishes (presence, basic ranges, era/cod)
			var roll = randf()
			if roll < 0.4:
				wish = _generate_stat_presence_wish()
			elif roll < 0.7:
				wish = _generate_stat_range_wish(30, 60)  # Wide ranges
			elif roll < 0.85:
				wish = _generate_era_wish()
			else:
				wish = _generate_cod_wish()
		elif current_cycle <= 10:
			# Early-mid game: more ranges, era/cod
			var roll = randf()
			if roll < 0.6:
				wish = _generate_stat_range_wish(25, 50)  # Medium ranges
			elif roll < 0.8:
				wish = _generate_era_wish()
			else:
				wish = _generate_cod_wish()
		else:
			# Late-mid game: tighter ranges, multi-stat
			var roll = randf()
			if roll < 0.3:
				wish = _generate_multi_stat_wish()
			else:
				wish = _generate_stat_range_wish(15, 30)  # Tight ranges

		wishes.append(wish)

	return wishes

static func _generate_stat_presence_wish() -> Wish:
	var wish = Wish.new(WishType.STAT_PRESENCE)
	wish.stat_key = SoulData.SoulAttribute.values()[randi() % SoulData.SoulAttribute.size()]
	return wish

static func _generate_stat_range_wish(min_spread: int, max_spread: int) -> Wish:
	var wish = Wish.new(WishType.STAT_RANGE)
	wish.stat_key = SoulData.SoulAttribute.values()[randi() % SoulData.SoulAttribute.size()]

	# Generate a random range with the specified spread
	var spread = randi_range(min_spread, max_spread)
	var center = randi_range(spread / 2, 100 - spread / 2)
	wish.min_value = max(1, center - spread / 2)
	wish.max_value = min(100, center + spread / 2)

	return wish

static func _generate_era_wish() -> Wish:
	var wish = Wish.new(WishType.ERA)
	wish.era = SoulData.Era.values()[randi() % SoulData.Era.size()]
	return wish

static func _generate_cod_wish() -> Wish:
	var wish = Wish.new(WishType.CAUSE_OF_DEATH)
	wish.cause_of_death = SoulData.CauseOfDeath.values()[randi() % SoulData.CauseOfDeath.size()]
	return wish

static func _generate_multi_stat_wish() -> Wish:
	var wish = Wish.new(WishType.MULTI_STAT)
	var num_stats = randi_range(2, 3)

	var available_stats = SoulData.SoulAttribute.values().duplicate()
	available_stats.shuffle()

	for i in range(min(num_stats, available_stats.size())):
		var spread = randi_range(15, 25)
		var center = randi_range(spread / 2, 100 - spread / 2)
		wish.multi_requirements.append({
			"stat_key": available_stats[i],
			"min": max(1, center - spread / 2),
			"max": min(100, center + spread / 2)
		})

	return wish

## Check if a wish is met by an advertised soul
## Returns {met: bool, quality_value: int, is_exact: bool}
static func check_wish_match(wish: Wish, soul: SoulData, ad_log: DiscoveryLog) -> Dictionary:
	match wish.type:
		WishType.STAT_PRESENCE:
			return _check_stat_presence(wish, soul, ad_log)
		WishType.STAT_RANGE:
			return _check_stat_range(wish, soul, ad_log)
		WishType.ERA:
			return _check_era(wish, soul, ad_log)
		WishType.CAUSE_OF_DEATH:
			return _check_cod(wish, soul, ad_log)
		WishType.MULTI_STAT:
			return _check_multi_stat(wish, soul, ad_log)

	return {"met": false, "quality_value": 0, "is_exact": false}

static func _check_stat_presence(wish: Wish, soul: SoulData, ad_log: DiscoveryLog) -> Dictionary:
	# Check if we advertise this stat exists (either as known or hinted)
	if ad_log.knows_stat(wish.stat_key) or ad_log.has_stat_hints(wish.stat_key):
		return {"met": true, "quality_value": wish.stat_key, "is_exact": ad_log.knows_stat(wish.stat_key)}
	return {"met": false, "quality_value": 0, "is_exact": false}

static func _check_stat_range(wish: Wish, soul: SoulData, ad_log: DiscoveryLog) -> Dictionary:
	# First check if soul actually has this stat
	if not soul.stats.has(wish.stat_key):
		return {"met": false, "quality_value": 0, "is_exact": false}

	# Check if advertised range overlaps with desired range
	if ad_log.knows_stat(wish.stat_key):
		# We know exact value
		var value = soul.stats[wish.stat_key]
		if value >= wish.min_value and value <= wish.max_value:
			return {"met": true, "quality_value": wish.stat_key, "is_exact": true}
	elif ad_log.has_stat_hints(wish.stat_key):
		# We have hints - check if ranges overlap
		var hints = ad_log.get_stat_hints(wish.stat_key)
		for hint in hints:
			var range_data = _parse_range_hint(hint)
			if range_data:
				# Check if ranges overlap
				if range_data.max >= wish.min_value and range_data.min <= wish.max_value:
					return {"met": true, "quality_value": wish.stat_key, "is_exact": false}

	# Early game: collectors will still buy if we advertise stat presence (even if no range info)
	# They just pay less (handled in pricing)
	# Check if we're at least advertising the stat exists
	if ad_log.knows_stat(wish.stat_key) or ad_log.has_stat_hints(wish.stat_key):
		return {"met": true, "quality_value": wish.stat_key, "is_exact": false, "presence_only": true}

	return {"met": false, "quality_value": 0, "is_exact": false}

static func _check_era(wish: Wish, soul: SoulData, ad_log: DiscoveryLog) -> Dictionary:
	if ad_log.known_era and soul.era == wish.era:
		return {"met": true, "quality_value": -1, "is_exact": true}  # -1 for era/cod
	return {"met": false, "quality_value": 0, "is_exact": false}

static func _check_cod(wish: Wish, soul: SoulData, ad_log: DiscoveryLog) -> Dictionary:
	if ad_log.known_death and soul.causeOfDeath == wish.cause_of_death:
		return {"met": true, "quality_value": -2, "is_exact": true}  # -2 for cod
	return {"met": false, "quality_value": 0, "is_exact": false}

static func _check_multi_stat(wish: Wish, soul: SoulData, ad_log: DiscoveryLog) -> Dictionary:
	var all_met = true
	var qualities_met = []

	for req in wish.multi_requirements:
		var stat_key = req.stat_key
		var met = false

		if ad_log.knows_stat(stat_key):
			var value = soul.stats[stat_key]
			if value >= req.min and value <= req.max:
				met = true
		elif ad_log.has_stat_hints(stat_key):
			var hints = ad_log.get_stat_hints(stat_key)
			for hint in hints:
				var range_data = _parse_range_hint(hint)
				if range_data and range_data.max >= req.min and range_data.min <= req.max:
					met = true
					break

		if met:
			qualities_met.append(stat_key)
		else:
			all_met = false
			break

	if all_met:
		return {"met": true, "quality_value": qualities_met, "is_exact": true}
	return {"met": false, "quality_value": 0, "is_exact": false}

static func _parse_range_hint(hint: String) -> Dictionary:
	if "-" in hint and hint != "Present":
		var parts = hint.split("-")
		if parts.size() == 2:
			var min_val = parts[0].to_int()
			var max_val = parts[1].to_int()
			if min_val >= 0 and max_val <= 100 and min_val < max_val:
				return {"min": min_val, "max": max_val}
	return {}
