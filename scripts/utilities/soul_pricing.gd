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
