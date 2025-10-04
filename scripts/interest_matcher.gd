extends Node

## Centralized system for matching shade interests to souls
## This is the SINGLE SOURCE OF TRUTH for interest matching logic

enum InterestType {
	ERA,              # Specific era
	CAUSE_OF_DEATH,   # Specific cause of death
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

	match type:
		InterestType.ERA:
			return soul.era == interest.get("value")

		InterestType.CAUSE_OF_DEATH:
			return soul.causeOfDeath == interest.get("value")

		InterestType.STAT_ABOVE:
			var stat = interest.get("stat")
			var threshold = interest.get("threshold", 85)
			return soul.stats.get(stat, 0) >= threshold

		InterestType.STAT_BELOW:
			var stat = interest.get("stat")
			var threshold = interest.get("threshold", 25)
			return soul.stats.get(stat, 0) <= threshold

		InterestType.STAT_BETWEEN:
			var stat = interest.get("stat")
			var min_val = interest.get("min", 25)
			var max_val = interest.get("max", 85)
			var soul_value = soul.stats.get(stat, 0)
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
		InterestType.STAT_ABOVE,
		InterestType.STAT_BELOW,
		InterestType.STAT_BETWEEN
	]

	var type = interest_types[randi() % interest_types.size()]

	match type:
		InterestType.ERA:
			return {
				"type": type,
				"value": randi() % SoulData.Era.size()
			}

		InterestType.CAUSE_OF_DEATH:
			return {
				"type": type,
				"value": randi() % SoulData.CauseOfDeath.size()
			}

		InterestType.STAT_ABOVE:
			var stat = randi() % SoulData.SoulAttribute.size()
			return {
				"type": type,
				"stat": stat,
				"threshold": 85
			}

		InterestType.STAT_BELOW:
			var stat = randi() % SoulData.SoulAttribute.size()
			return {
				"type": type,
				"stat": stat,
				"threshold": 25
			}

		InterestType.STAT_BETWEEN:
			var stat = randi() % SoulData.SoulAttribute.size()
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
