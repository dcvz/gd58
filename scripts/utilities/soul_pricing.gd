class_name SoulPricing
extends RefCounted

## Centralized soul pricing and valuation system
## Calculates prices based on stat rarity and customer interest matching
## Uses RarityTables for consistent rarity definitions

# Customer interest multipliers
const PERFECT_MATCH_MULTIPLIER = 1.0  # Customer wants this specific attribute
const NO_INTEREST_MULTIPLIER = 0.4    # Customer doesn't care about this attribute
const MULTI_INTEREST_BONUS = 1.3      # Bonus when soul matches multiple interests

## Calculate the inherent value of a soul based on its stat rarities
static func calculate_base_value(soul: SoulData) -> int:
	var total_value = 0

	# Add value based on era rarity
	total_value += RarityTables.get_era_value(soul.era)

	# Add value based on cause of death rarity
	total_value += RarityTables.get_death_value(soul.causeOfDeath)

	# Add value for each stat in the stats dictionary
	for stat_key in soul.stats.keys():
		var stat_value = soul.stats[stat_key]
		total_value += RarityTables.get_stat_value(int(stat_value))

	return total_value

## Calculate what a customer would offer/pay for a soul
## Buyers pay PREMIUM when soul matches their interests (120-150% of base value)
static func calculate_customer_offer(soul: SoulData, customer_interests: Array) -> int:
	var base_value = calculate_base_value(soul)

	# Safety: ensure base value is at least 10 KP
	base_value = maxi(base_value, 10)

	if customer_interests.size() == 0:
		# No interests means lowball offer (60-80% of base value)
		return maxi(int(base_value * randf_range(0.6, 0.8)), 15)

	# Buyer found what they want! They'll pay premium
	# Single interest: 120-140% of base value
	# Multiple interests: 130-150% of base value (even better match!)
	var premium_min = 1.2
	var premium_max = 1.4

	if customer_interests.size() > 1:
		premium_min = 1.3
		premium_max = 1.5

	# Add buyer desperation factor
	var premium = randf_range(premium_min, premium_max)
	var offer = int(base_value * premium)

	return maxi(offer, 25)  # Minimum offer of 25 KP

## Calculate how much you should pay a seller for their soul
static func calculate_seller_asking_price(soul: SoulData, seller_interests: Array) -> int:
	# Sellers ask below market price to move inventory quickly
	# This creates profit opportunities: buy at 85-95%, sell at 120-150%
	var base_price = calculate_base_value(soul)

	# Safety: ensure base price is at least 10 KP
	base_price = maxi(base_price, 10)

	# Sellers are eager to sell (85-95% of base value)
	var variation = randf_range(0.85, 0.95)
	return maxi(int(base_price * variation), 15)  # Minimum 15 KP

## Calculate value based on advertised properties only
static func calculate_advertised_value(advertised_soul: Dictionary, actual_soul: SoulData) -> int:
	var total_value = 0

	# Add value for advertised era
	if advertised_soul.get("has_era", false):
		total_value += RarityTables.get_era_value(advertised_soul.get("era"))

	# Add value for advertised death
	if advertised_soul.get("has_death", false):
		total_value += RarityTables.get_death_value(advertised_soul.get("death"))

	# Add value for advertised stats based on advertisement level
	var advertised_stats = advertised_soul.get("stats", {})
	for stat_key in advertised_stats.keys():
		var stat_ad = advertised_stats[stat_key]
		var level = stat_ad.get("level", SoulAdvertisement.AdvertLevel.NOT_ADVERTISED)

		match level:
			SoulAdvertisement.AdvertLevel.ADVERTISE_PRESENCE:
				# Presence only: assume middle value (50)
				# Worth less because uncertain
				total_value += RarityTables.get_stat_value(50) * 0.5  # 50% penalty for uncertainty

			SoulAdvertisement.AdvertLevel.ADVERTISE_RANGE:
				# Range: use midpoint of advertised range
				# Worth less than exact but more than presence
				var min_val = stat_ad.get("min", 0)
				var max_val = stat_ad.get("max", 100)
				var midpoint = (min_val + max_val) / 2.0
				total_value += RarityTables.get_stat_value(int(midpoint)) * 0.75  # 25% penalty for uncertainty

			SoulAdvertisement.AdvertLevel.ADVERTISE_EXACT:
				# Exact value: full value
				var exact = stat_ad.get("exact", 50)
				total_value += RarityTables.get_stat_value(int(exact))

	return total_value

## Calculate buyer offer based on advertised properties
static func calculate_advertised_offer(advertised_soul: Dictionary, actual_soul: SoulData, customer_interests: Array) -> int:
	var base_value = calculate_advertised_value(advertised_soul, actual_soul)

	# Safety: ensure base value is at least 10 KP
	base_value = maxi(base_value, 10)

	if customer_interests.size() == 0:
		# No interests means lowball offer (60-80% of advertised value)
		return maxi(int(base_value * randf_range(0.6, 0.8)), 15)

	# Buyer found what they want (based on advertised properties)!
	# Single interest: 120-140% of advertised value
	# Multiple interests: 130-150% of advertised value
	var premium_min = 1.2
	var premium_max = 1.4

	if customer_interests.size() > 1:
		premium_min = 1.3
		premium_max = 1.5

	var premium = randf_range(premium_min, premium_max)
	var offer = int(base_value * premium)

	return maxi(offer, 25)  # Minimum offer of 25 KP

## Calculate seller asking price based on what they know (discovery log)
static func calculate_seller_price_from_discoveries(soul: SoulData, discovery_log: DiscoveryLog) -> int:
	var known_value = 0

	# Add value for known era
	if discovery_log.known_era:
		known_value += RarityTables.get_era_value(soul.era)

	# Add value for known death
	if discovery_log.known_death:
		known_value += RarityTables.get_death_value(soul.causeOfDeath)

	# Add value for known stats only
	for stat_key in discovery_log.get_discovered_stats():
		if soul.stats.has(stat_key):
			known_value += RarityTables.get_stat_value(int(soul.stats[stat_key]))

	# Safety: ensure base value is at least 10 KP
	known_value = maxi(known_value, 10)

	# Sellers are eager to sell (85-95% of what they know it's worth)
	var variation = randf_range(0.85, 0.95)
	return maxi(int(known_value * variation), 15)  # Minimum 15 KP
