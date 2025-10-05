class_name InterestMatcher
extends RefCounted

## Centralized system for matching shade interests to souls
## This is the SINGLE SOURCE OF TRUTH for interest matching logic

enum InterestType {
	ERA,              # Specific era
	CAUSE_OF_DEATH,   # Specific cause of death
	HAS_STAT,         # Just wants soul to have this stat (any value)
	STAT_ABOVE,       # Stat value >= threshold
	STAT_BELOW,       # Stat value <= threshold
	STAT_BETWEEN      # Stat value between min and max
}

## Check if a soul matches ALL criteria in an interest list
static func soul_matches_interests(soul: SoulData, interests: Array) -> bool:
	if interests.size() == 0:
		return false

	for interest in interests:
		if not _matches_single_interest(soul, interest):
			return false

	return true

## Check if a soul matches a single interest criterion
static func _matches_single_interest(soul: SoulData, interest: Dictionary) -> bool:
	var type = interest.get("type", InterestType.ERA)

	# For stat-based interests, soul must actually have the stat
	if type in [InterestType.HAS_STAT, InterestType.STAT_ABOVE, InterestType.STAT_BELOW, InterestType.STAT_BETWEEN]:
		var stat = interest.get("stat")
		if not soul.stats.has(stat):
			return false

	match type:
		InterestType.ERA:
			return soul.era == interest.get("value")

		InterestType.CAUSE_OF_DEATH:
			return soul.causeOfDeath == interest.get("value")

		InterestType.HAS_STAT:
			# Just needs to have the stat (already checked above)
			return true

		InterestType.STAT_ABOVE:
			var stat = interest.get("stat")
			var threshold = interest.get("threshold", 85)
			return soul.stats[stat] >= threshold

		InterestType.STAT_BELOW:
			var stat = interest.get("stat")
			var threshold = interest.get("threshold", 25)
			return soul.stats[stat] <= threshold

		InterestType.STAT_BETWEEN:
			var stat = interest.get("stat")
			var min_val = interest.get("min", 25)
			var max_val = interest.get("max", 85)
			var soul_value = soul.stats[stat]
			return soul_value >= min_val and soul_value <= max_val

	return false

## Generate random interests for a shade (80% single, 20% multiple)
static func generate_random_interests() -> Array:
	var interests: Array = []

	# 80% chance of single interest, 20% chance of 2 interests
	var num_interests = 1 if randf() < 0.8 else 2

	for i in range(num_interests):
		interests.append(_generate_single_interest())

	return interests

## Generate a single random interest
static func _generate_single_interest() -> Dictionary:
	var interest_types = [
		InterestType.ERA,
		InterestType.CAUSE_OF_DEATH,
		InterestType.HAS_STAT,
		InterestType.STAT_ABOVE,
		InterestType.STAT_BELOW,
		InterestType.STAT_BETWEEN
	]

	var type = interest_types.pick_random()

	match type:
		InterestType.ERA:
			return {
				"type": type,
				"value": randi_range(0, SoulData.Era.size() - 1)
			}

		InterestType.CAUSE_OF_DEATH:
			return {
				"type": type,
				"value": randi_range(0, SoulData.CauseOfDeath.size() - 1)
			}

		InterestType.HAS_STAT:
			var stat = randi_range(0, SoulData.SoulAttribute.size() - 1)
			return {
				"type": type,
				"stat": stat
			}

		InterestType.STAT_ABOVE:
			var stat = randi_range(0, SoulData.SoulAttribute.size() - 1)
			return {
				"type": type,
				"stat": stat,
				"threshold": 85
			}

		InterestType.STAT_BELOW:
			var stat = randi_range(0, SoulData.SoulAttribute.size() - 1)
			return {
				"type": type,
				"stat": stat,
				"threshold": 25
			}

		InterestType.STAT_BETWEEN:
			var stat = randi_range(0, SoulData.SoulAttribute.size() - 1)
			return {
				"type": type,
				"stat": stat,
				"min": 25,
				"max": 85
			}

	return {}

## Format interest for display (human-readable)
static func format_interest_for_display(interest: Dictionary) -> String:
	var type = interest.get("type", InterestType.ERA)

	match type:
		InterestType.ERA:
			var era = interest.get("value", 0)
			return "Era: %s" % SoulData.Era.keys()[era]

		InterestType.CAUSE_OF_DEATH:
			var cod = interest.get("value", 0)
			return "Cause of Death: %s" % SoulData.CauseOfDeath.keys()[cod]

		InterestType.HAS_STAT:
			var stat = interest.get("stat", 0)
			return "Has %s" % SoulData.SoulAttribute.keys()[stat]

		InterestType.STAT_ABOVE:
			var stat = interest.get("stat", 0)
			var threshold = interest.get("threshold", 85)
			return "%s >= %d" % [SoulData.SoulAttribute.keys()[stat], threshold]

		InterestType.STAT_BELOW:
			var stat = interest.get("stat", 0)
			var threshold = interest.get("threshold", 25)
			return "%s <= %d" % [SoulData.SoulAttribute.keys()[stat], threshold]

		InterestType.STAT_BETWEEN:
			var stat = interest.get("stat", 0)
			var min_val = interest.get("min", 25)
			var max_val = interest.get("max", 85)
			return "%s between %d-%d" % [SoulData.SoulAttribute.keys()[stat], min_val, max_val]

	return "Unknown interest"

## Check if advertised soul properties match buyer interests
## advertised_soul: Dictionary from AdvertisementManager.create_advertised_soul()
## actual_soul: SoulData (for stat values when advertised)
## interests: Array of interest dictionaries
static func advertised_soul_matches_interests(advertised_soul: Dictionary, actual_soul: SoulData, interests: Array) -> bool:
	# All interests must match for buyer to be interested
	for interest in interests:
		if not _advertised_matches_single_interest(advertised_soul, actual_soul, interest):
			return false
	return true

## Check if a single interest matches advertised properties
static func _advertised_matches_single_interest(advertised_soul: Dictionary, actual_soul: SoulData, interest: Dictionary) -> bool:
	var type = interest.get("type", InterestType.ERA)

	match type:
		InterestType.ERA:
			# Must advertise era AND it must match
			if not advertised_soul.get("has_era", false):
				return false
			return advertised_soul.get("era") == interest.get("value")

		InterestType.CAUSE_OF_DEATH:
			# Must advertise death AND it must match
			if not advertised_soul.get("has_death", false):
				return false
			return advertised_soul.get("death") == interest.get("value")

		InterestType.HAS_STAT:
			var stat = interest.get("stat")
			# Must advertise this stat at ANY level (presence, range, or exact)
			return advertised_soul.get("stats", {}).has(stat)

		InterestType.STAT_ABOVE:
			var stat = interest.get("stat")
			var threshold = interest.get("threshold", 85)
			if not advertised_soul.get("stats", {}).has(stat):
				return false

			var stat_ad = advertised_soul.get("stats")[stat]
			var level = stat_ad.get("level")

			match level:
				SoulAdvertisement.AdvertLevel.ADVERTISE_PRESENCE:
					# Can't verify threshold from presence only
					return false
				SoulAdvertisement.AdvertLevel.ADVERTISE_RANGE:
					# Only matches if min >= threshold (entire range is above)
					return stat_ad.get("min", 0) >= threshold
				SoulAdvertisement.AdvertLevel.ADVERTISE_EXACT:
					# Check exact value
					return stat_ad.get("exact", 0) >= threshold

		InterestType.STAT_BELOW:
			var stat = interest.get("stat")
			var threshold = interest.get("threshold", 25)
			if not advertised_soul.get("stats", {}).has(stat):
				return false

			var stat_ad = advertised_soul.get("stats")[stat]
			var level = stat_ad.get("level")

			match level:
				SoulAdvertisement.AdvertLevel.ADVERTISE_PRESENCE:
					# Can't verify threshold from presence only
					return false
				SoulAdvertisement.AdvertLevel.ADVERTISE_RANGE:
					# Only matches if max <= threshold (entire range is below)
					return stat_ad.get("max", 100) <= threshold
				SoulAdvertisement.AdvertLevel.ADVERTISE_EXACT:
					# Check exact value
					return stat_ad.get("exact", 0) <= threshold

		InterestType.STAT_BETWEEN:
			var stat = interest.get("stat")
			var min_val = interest.get("min", 25)
			var max_val = interest.get("max", 85)
			if not advertised_soul.get("stats", {}).has(stat):
				return false

			var stat_ad = advertised_soul.get("stats")[stat]
			var level = stat_ad.get("level")

			match level:
				SoulAdvertisement.AdvertLevel.ADVERTISE_PRESENCE:
					# Can't verify range from presence only
					return false
				SoulAdvertisement.AdvertLevel.ADVERTISE_RANGE:
					# Ranges overlap if: ad_min <= interest_max AND ad_max >= interest_min
					var ad_min = stat_ad.get("min", 0)
					var ad_max = stat_ad.get("max", 100)
					return ad_min <= max_val and ad_max >= min_val
				SoulAdvertisement.AdvertLevel.ADVERTISE_EXACT:
					# Check exact value is in range
					var exact = stat_ad.get("exact", 0)
					return exact >= min_val and exact <= max_val

	return false
