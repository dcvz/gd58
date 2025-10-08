class_name RarityTables
extends RefCounted

## Centralized rarity definitions for soul generation and pricing
## This ensures that rare things are actually generated rarely AND valued appropriately

# Rarity tiers and their KP values
enum RarityTier { COMMON, UNCOMMON, RARE, VERY_RARE, LEGENDARY }

const RARITY_VALUES = {
	RarityTier.COMMON: 5,
	RarityTier.UNCOMMON: 15,
	RarityTier.RARE: 30,
	RarityTier.VERY_RARE: 50,
	RarityTier.LEGENDARY: 100
}

# Rarity colors for UI display
const RARITY_COLORS = {
	RarityTier.COMMON: Color.WHITE,
	RarityTier.UNCOMMON: Color(0.3, 1.0, 0.3),      # Green
	RarityTier.RARE: Color(0.3, 0.6, 1.0),          # Blue
	RarityTier.VERY_RARE: Color(0.8, 0.3, 1.0),     # Purple
	RarityTier.LEGENDARY: Color(1.0, 0.6, 0.0)      # Orange
}

# Era rarity and generation weights
const ERA_RARITY = {
	SoulData.Era.MODERN: RarityTier.COMMON,
	SoulData.Era.CLASSICAL: RarityTier.RARE,
	SoulData.Era.ANCIENT: RarityTier.VERY_RARE,
	SoulData.Era.PREHISTORIC: RarityTier.VERY_RARE
}

# Weighted probabilities for era generation (higher = more common)
const ERA_WEIGHTS = {
	SoulData.Era.MODERN: 50,        # 50% chance
	SoulData.Era.CLASSICAL: 30,     # 30% chance
	SoulData.Era.ANCIENT: 15,       # 15% chance
	SoulData.Era.PREHISTORIC: 5     # 5% chance (very rare!)
}

# Death cause rarity
const DEATH_RARITY = {
	SoulData.CauseOfDeath.NATURAL: RarityTier.COMMON,
	SoulData.CauseOfDeath.ILLNESS: RarityTier.COMMON,
	SoulData.CauseOfDeath.ACCIDENT: RarityTier.UNCOMMON,
	SoulData.CauseOfDeath.BATTLE: RarityTier.UNCOMMON,
	SoulData.CauseOfDeath.DROWNED: RarityTier.UNCOMMON,
	SoulData.CauseOfDeath.STARVED: RarityTier.UNCOMMON,
	SoulData.CauseOfDeath.FROZEN: RarityTier.UNCOMMON,
	SoulData.CauseOfDeath.POISON: RarityTier.RARE,
	SoulData.CauseOfDeath.MURDERED: RarityTier.RARE
}

# Weighted probabilities for death cause generation
const DEATH_WEIGHTS = {
	SoulData.CauseOfDeath.NATURAL: 30,    # 30%
	SoulData.CauseOfDeath.ILLNESS: 20,    # 20%
	SoulData.CauseOfDeath.ACCIDENT: 15,   # 15%
	SoulData.CauseOfDeath.BATTLE: 10,     # 10%
	SoulData.CauseOfDeath.DROWNED: 8,     # 8%
	SoulData.CauseOfDeath.STARVED: 7,     # 7%
	SoulData.CauseOfDeath.FROZEN: 5,      # 5%
	SoulData.CauseOfDeath.POISON: 3,      # 3%
	SoulData.CauseOfDeath.MURDERED: 2     # 2%
}

# Stat rarity thresholds
# Extreme values (< 25 or > 85) are rare and valuable
const STAT_RARE_THRESHOLD = 25

## Generate a random era using weighted probabilities
static func generate_weighted_era() -> SoulData.Era:
	var total_weight = 0
	for weight in ERA_WEIGHTS.values():
		total_weight += weight

	var roll = randi_range(0, total_weight - 1)
	var current_weight = 0

	for era in ERA_WEIGHTS.keys():
		current_weight += ERA_WEIGHTS[era]
		if roll < current_weight:
			return era

	return SoulData.Era.MODERN  # Fallback

## Generate a random cause of death using weighted probabilities
static func generate_weighted_death() -> SoulData.CauseOfDeath:
	var total_weight = 0
	for weight in DEATH_WEIGHTS.values():
		total_weight += weight

	var roll = randi_range(0, total_weight - 1)
	var current_weight = 0

	for death in DEATH_WEIGHTS.keys():
		current_weight += DEATH_WEIGHTS[death]
		if roll < current_weight:
			return death

	return SoulData.CauseOfDeath.NATURAL  # Fallback

## Get KP value for an era
static func get_era_value(era: SoulData.Era) -> int:
	if ERA_RARITY.has(era):
		return RARITY_VALUES[ERA_RARITY[era]]
	return RARITY_VALUES[RarityTier.COMMON]

## Get KP value for a death cause
static func get_death_value(death: SoulData.CauseOfDeath) -> int:
	if DEATH_RARITY.has(death):
		return RARITY_VALUES[DEATH_RARITY[death]]
	return RARITY_VALUES[RarityTier.COMMON]

## Get rarity tier for a stat based on its value
## Stats are generated using randfn(0.5, 0.18) * 100, creating a normal distribution
## centered at 50 with standard deviation of 18
static func get_stat_rarity(stat_value: int) -> RarityTier:
	# Legendary: Beyond 2 standard deviations (≥86 or ≤14) - ~5% of stats
	if stat_value >= 86 or stat_value <= 14:
		return RarityTier.LEGENDARY
	# Very Rare: Beyond 1.5 standard deviations (≥77 or ≤23) - ~13% of stats
	elif stat_value >= 77 or stat_value <= 23:
		return RarityTier.VERY_RARE
	# Rare: Beyond 1.2 standard deviations (≥72 or ≤28) - ~23% of stats
	elif stat_value >= 72 or stat_value <= 28:
		return RarityTier.RARE
	# Uncommon: Beyond 0.7 standard deviations (≥63 or ≤37) - ~48% of stats
	elif stat_value >= 63 or stat_value <= 37:
		return RarityTier.UNCOMMON
	# Common: Within 0.7 standard deviations (38-62) - ~52% of stats
	else:
		return RarityTier.COMMON

## Get color for a stat based on its rarity
static func get_stat_color(stat_value: int) -> Color:
	var rarity = get_stat_rarity(stat_value)
	return RARITY_COLORS[rarity]

## Get KP value for a stat based on its value (extreme = rare = valuable)
static func get_stat_value(stat_value: int) -> int:
	var rarity = get_stat_rarity(stat_value)
	return RARITY_VALUES[rarity]
