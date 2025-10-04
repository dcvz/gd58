extends Node
class_name SoulPricing

## Centralized soul pricing and valuation system
## Calculates prices based on stat rarity and customer interest matching

const InterestMatcher = preload("res://scripts/interest_matcher.gd")

# Rarity thresholds for stats (lower = rarer)
const STAT_VERY_RARE_THRESHOLD = 20
const STAT_RARE_THRESHOLD = 40
const STAT_UNCOMMON_THRESHOLD = 60
const STAT_COMMON_THRESHOLD = 80

# Base KP values for different rarities
const VERY_RARE_VALUE = 50
const RARE_VALUE = 30
const UNCOMMON_VALUE = 15
const COMMON_VALUE = 5

# Era rarity (some eras are rarer than others)
const ERA_RARITY = {
	"CLASSICAL": RARE_VALUE,
	"ANCIENT": VERY_RARE_VALUE,
	"PREHISTORIC": VERY_RARE_VALUE,
	"MODERN": COMMON_VALUE
}

# Cause of death rarity
const DEATH_RARITY = {
	"BATTLE": UNCOMMON_VALUE,
	"ACCIDENT": UNCOMMON_VALUE,
	"NATURAL": COMMON_VALUE,
	"POISON": RARE_VALUE,
	"ILLNESS": COMMON_VALUE,
	"MURDERED": RARE_VALUE,
	"DROWNED": UNCOMMON_VALUE,
	"STARVED": UNCOMMON_VALUE,
	"FROZEN": UNCOMMON_VALUE
}

# Customer interest multipliers
const PERFECT_MATCH_MULTIPLIER = 1.0  # Customer wants this specific attribute
const NO_INTEREST_MULTIPLIER = 0.4    # Customer doesn't care about this attribute
const MULTI_INTEREST_BONUS = 1.3      # Bonus when soul matches multiple interests

## Calculate the inherent value of a soul based on its stat rarities
static func calculate_base_value(soul: SoulData) -> int:
	var total_value = 0

	# Add value based on era rarity
	var era_name = SoulData.Era.keys()[soul.era]
	if ERA_RARITY.has(era_name):
		total_value += ERA_RARITY[era_name]
	else:
		total_value += COMMON_VALUE

	# Add value based on cause of death rarity
	var death_name = SoulData.CauseOfDeath.keys()[soul.causeOfDeath]
	if DEATH_RARITY.has(death_name):
		total_value += DEATH_RARITY[death_name]
	else:
		total_value += COMMON_VALUE

	# Add value for each stat in the stats dictionary
	for stat_key in soul.stats.keys():
		var stat_value = soul.stats[stat_key]
		total_value += _get_stat_value(int(stat_value))

	return total_value

## Calculate what a customer would offer/pay for a soul
## Based on THEIR valuation (what they care about), not objective rarity
static func calculate_customer_offer(soul: SoulData, customer_interests: Array) -> int:
	if customer_interests.size() == 0:
		# No interests means random lowball offer
		return randi_range(10, 30)

	# Base offer for finding what they want (regardless of rarity)
	var base_offer = 30  # They found what they came for!

	# Add value per interest they're satisfying
	var interest_value = 25 * customer_interests.size()

	# Apply multi-interest bonus (they're getting exactly what they want!)
	if customer_interests.size() > 1:
		interest_value = int(interest_value * MULTI_INTEREST_BONUS)

	var total_offer = base_offer + interest_value

	# Add small recognition of objective rarity (10-20% of base value)
	# Even if they don't care about specific attributes, they recognize overall quality
	var base_value = calculate_base_value(soul)
	var rarity_bonus = int(base_value * randf_range(0.1, 0.2))

	total_offer += rarity_bonus

	# Add some randomness (buyer desperation/budget variation)
	var desperation = randf_range(0.8, 1.2)
	total_offer = int(total_offer * desperation)

	return maxi(total_offer, 15)  # Minimum offer of 15 KP

## Calculate how much you should pay a seller for their soul
static func calculate_seller_asking_price(soul: SoulData, seller_interests: Array) -> int:
	# Sellers price based on what they think is valuable about the soul
	# Similar to customer offers, but slightly higher
	var base_price = calculate_base_value(soul)

	# Sellers ask for about 120% of base value
	return int(base_price * 1.2)

## Helper: Get value of a single stat based on its rarity
static func _get_stat_value(stat_value: int) -> int:
	# Low stats and high stats are both rare and valuable
	var distance_from_middle = abs(stat_value - 50)

	if stat_value <= STAT_VERY_RARE_THRESHOLD or stat_value >= (100 - STAT_VERY_RARE_THRESHOLD):
		return VERY_RARE_VALUE
	elif stat_value <= STAT_RARE_THRESHOLD or stat_value >= (100 - STAT_RARE_THRESHOLD):
		return RARE_VALUE
	elif stat_value <= STAT_UNCOMMON_THRESHOLD or stat_value >= (100 - STAT_UNCOMMON_THRESHOLD):
		return UNCOMMON_VALUE
	else:
		return COMMON_VALUE
