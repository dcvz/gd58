class_name SoulAdvertisement
extends Resource

## Tracks what properties we're advertising for a soul on display
## Supports strategic advertising including speculation/lying about ranges

enum AdvertLevel {
	NOT_ADVERTISED,      # Don't show this stat
	ADVERTISE_PRESENCE,  # "Has this stat" (no value info)
	ADVERTISE_RANGE,     # "Stat is between X-Y" (can be speculative)
	ADVERTISE_EXACT      # "Stat = X" (exact value)
}

var soul_id: String
var advertise_era: bool = false
var advertise_death: bool = false

# stat_key -> {level: AdvertLevel, min: float, max: float, exact: float}
var advertised_stats: Dictionary = {}

func _init(p_soul_id: String = "") -> void:
	soul_id = p_soul_id

## Set whether to advertise era
func set_advertise_era(value: bool) -> void:
	advertise_era = value

## Set whether to advertise death
func set_advertise_death(value: bool) -> void:
	advertise_death = value

## Advertise that a stat exists (presence only)
func advertise_stat_presence(stat_key: int) -> void:
	advertised_stats[stat_key] = {
		"level": AdvertLevel.ADVERTISE_PRESENCE
	}

## Advertise a stat range (can be speculative/lying)
func advertise_stat_range(stat_key: int, min_val: float, max_val: float) -> void:
	advertised_stats[stat_key] = {
		"level": AdvertLevel.ADVERTISE_RANGE,
		"min": min_val,
		"max": max_val
	}

## Advertise exact stat value
func advertise_stat_exact(stat_key: int, value: float) -> void:
	advertised_stats[stat_key] = {
		"level": AdvertLevel.ADVERTISE_EXACT,
		"exact": value
	}

## Remove stat advertisement
func unadvertise_stat(stat_key: int) -> void:
	advertised_stats.erase(stat_key)

## Check if a stat is being advertised (at any level)
func is_stat_advertised(stat_key: int) -> bool:
	return advertised_stats.has(stat_key)

## Get advertisement level for a stat
func get_stat_advert_level(stat_key: int) -> int:
	if not advertised_stats.has(stat_key):
		return AdvertLevel.NOT_ADVERTISED
	return advertised_stats[stat_key].get("level", AdvertLevel.NOT_ADVERTISED)

## Get all advertised stat keys
func get_advertised_stat_keys() -> Array:
	return advertised_stats.keys()

## Get advertisement data for a stat
func get_stat_advertisement(stat_key: int) -> Dictionary:
	if advertised_stats.has(stat_key):
		return advertised_stats[stat_key].duplicate()
	return {}

## Auto-advertise everything we know (exact values, ranges, and presence)
## By default, advertise ALL known information about a soul
func auto_advertise_from_discoveries(discovery_log: DiscoveryLog, soul: SoulData) -> void:
	advertise_era = discovery_log.known_era
	advertise_death = discovery_log.known_death
	advertised_stats.clear()

	# Advertise exact values for discovered stats
	for stat_key in discovery_log.get_discovered_stats():
		var value = discovery_log.known_stats[stat_key]
		advertise_stat_exact(stat_key, value)

	# Advertise ranges for stats with hints
	for stat_key in soul.stats.keys():
		if not discovery_log.knows_stat(stat_key) and discovery_log.has_stat_hints(stat_key):
			var hints = discovery_log.get_stat_hints(stat_key)
			var has_range = false

			# Check if we have a range hint
			for hint in hints:
				if "-" in hint and hint != "Present":
					var parts = hint.split("-")
					if parts.size() == 2:
						var min_val = parts[0].to_float()
						var max_val = parts[1].to_float()
						if min_val >= 0 and max_val <= 100 and min_val < max_val:
							advertise_stat_range(stat_key, min_val, max_val)
							has_range = true
							break

			# If no range, but we have hints (presence only)
			if not has_range and hints.size() > 0:
				advertise_stat_presence(stat_key)
