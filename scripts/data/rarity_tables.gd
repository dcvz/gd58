class_name RarityTables
extends RefCounted

## Centralized rarity definitions for soul generation and pricing
## This ensures that rare things are actually generated rarely AND valued appropriately

# Rarity tiers and their KP values
enum RarityTier { COMMON, UNCOMMON, RARE, VERY_RARE }

const RARITY_VALUES = {
	RarityTier.COMMON: 5,
	RarityTier.UNCOMMON: 15,
	RarityTier.RARE: 30,
	RarityTier.VERY_RARE: 50
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

## Get KP value for a stat based on its value (extreme = rare = valuable)
static func get_stat_value(stat_value: int) -> int:
	# Stats below 25 or above 85 are rare
	if stat_value < STAT_RARE_THRESHOLD or stat_value > (100 - STAT_RARE_THRESHOLD):
		return RARITY_VALUES[RarityTier.RARE]
	else:
		return RARITY_VALUES[RarityTier.COMMON]
