extends RefCounted
class_name CollectorPricing

## Pricing system for collectors making offers on souls

## Calculate what a collector will offer for a soul
## Takes into account their wishes and what's advertised about the soul
static func calculate_offer(soul: SoulData, ad_log: DiscoveryLog, wishes: Array) -> int:
	var total_price = 0
	var wishes_met = 0
	var wished_qualities = {}  # Track which qualities are part of wishes

	# First, identify which qualities are part of wishes
	for wish in wishes:
		var match_result = WishSystem.check_wish_match(wish, soul, ad_log)
		if match_result.met:
			wishes_met += 1

			# Track which qualities are wished for
			if wish.type == WishSystem.WishType.STAT_PRESENCE or wish.type == WishSystem.WishType.STAT_RANGE:
				wished_qualities[wish.stat_key] = {
					"wish": wish,
					"is_exact": match_result.is_exact
				}
			elif wish.type == WishSystem.WishType.MULTI_STAT:
				for stat_key in match_result.quality_value:
					wished_qualities[stat_key] = {
						"wish": wish,
						"is_exact": true
					}
			elif wish.type == WishSystem.WishType.ERA:
				wished_qualities["era"] = {"wish": wish, "is_exact": true}
			elif wish.type == WishSystem.WishType.CAUSE_OF_DEATH:
				wished_qualities["cod"] = {"wish": wish, "is_exact": true}

	# Calculate value for Era
	if ad_log.known_era:
		var rarity = QualityValuation.get_era_rarity(soul.era)
		var base_value = QualityValuation.get_fundamental_value(rarity)

		if wished_qualities.has("era"):
			total_price += int(base_value * 1.5)
		else:
			total_price += int(base_value * 0.7)
	else:
		# Unknown era
		if wished_qualities.has("era"):
			total_price += int(15 * 1.5)
		else:
			total_price += int(15 * 0.7)

	# Calculate value for Cause of Death
	if ad_log.known_death:
		var rarity = QualityValuation.get_cod_rarity(soul.causeOfDeath)
		var base_value = QualityValuation.get_fundamental_value(rarity)

		if wished_qualities.has("cod"):
			total_price += int(base_value * 1.5)
		else:
			total_price += int(base_value * 0.7)
	else:
		# Unknown cod
		if wished_qualities.has("cod"):
			total_price += int(15 * 1.5)
		else:
			total_price += int(15 * 0.7)

	# Calculate value for each stat
	for stat_key in soul.stats.keys():
		var stat_value = soul.stats[stat_key]
		var is_wished = wished_qualities.has(stat_key)

		if ad_log.knows_stat(stat_key):
			# Fully known stat
			var base_value = QualityValuation.get_stat_value(stat_value)

			if is_wished:
				var wish_data = wished_qualities[stat_key]
				var wish = wish_data.wish

				if wish.type == WishSystem.WishType.STAT_RANGE:
					# Calculate spread between desired and actual
					var desired_min = wish.min_value
					var desired_max = wish.max_value
					var spread = max(abs(stat_value - desired_min), abs(stat_value - desired_max))
					var spread_factor = (spread * 0.01) + 1.0

					total_price += int(base_value * 1.5 * spread_factor)
				else:
					# STAT_PRESENCE or part of MULTI_STAT
					total_price += int(base_value * 1.5)
			else:
				total_price += int(base_value * 0.7)

		elif ad_log.has_stat_hints(stat_key):
			# Stat with hints
			var hints = ad_log.get_stat_hints(stat_key)

			if is_wished:
				var wish_data = wished_qualities[stat_key]
				var wish = wish_data.wish

				if wish.type == WishSystem.WishType.STAT_RANGE:
					# Get the advertised range
					var ad_range = _get_hint_range(hints)

					if ad_range:
						# Calculate spread between desired and advertised ranges
						var desired_min = wish.min_value
						var desired_max = wish.max_value
						var ad_min = ad_range.min
						var ad_max = ad_range.max

						# Spread is the maximum distance between ranges
						var spread = max(
							abs(ad_min - desired_min),
							abs(ad_max - desired_max),
							abs(ad_min - desired_max),
							abs(ad_max - desired_min)
						)
						var spread_factor = (spread * 0.01) + 1.0

						var base_value = QualityValuation.get_stat_hint_value(hints)
						total_price += int(base_value * 1.5 * spread_factor)
					else:
						# No valid range, fallback
						total_price += int(QualityValuation.get_stat_hint_value(hints) * 1.5)
				else:
					# STAT_PRESENCE or part of MULTI_STAT
					total_price += int(QualityValuation.get_stat_hint_value(hints) * 1.5)
			else:
				total_price += int(QualityValuation.get_stat_hint_value(hints) * 0.7)

		else:
			# Unknown stat
			if is_wished:
				# Collector wants this stat but we haven't researched it
				# Flat 25-45 KP valuation (risk pricing)
				total_price += randi_range(25, 45)
			else:
				total_price += int(15 * 0.7)

	# Apply multi-wish bonus multiplier
	if wishes_met >= 2:
		var multiplier = 1.0
		match wishes_met:
			2:
				multiplier = 1.5
			3:
				multiplier = 3.0
			4:
				multiplier = 5.0
			_:
				if wishes_met >= 5:
					multiplier = 10.0

		total_price = int(total_price * multiplier)

	return max(1, total_price)  # Ensure at least 1 KP

static func _get_hint_range(hints: Array) -> Dictionary:
	if hints.size() == 0:
		return {}

	var overlap_min = 0
	var overlap_max = 100

	for hint in hints:
		var range_data = _parse_range_hint(hint)
		if range_data:
			overlap_min = max(overlap_min, range_data.min)
			overlap_max = min(overlap_max, range_data.max)

	if overlap_min > overlap_max:
		return {}

	return {"min": overlap_min, "max": overlap_max}

static func _parse_range_hint(hint: String) -> Dictionary:
	if "-" in hint and hint != "Present":
		var parts = hint.split("-")
		if parts.size() == 2:
			var min_val = parts[0].to_int()
			var max_val = parts[1].to_int()
			if min_val >= 0 and max_val <= 100 and min_val < max_val:
				return {"min": min_val, "max": max_val}
	return {}
