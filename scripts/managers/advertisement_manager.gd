extends Node

## Manages what properties we advertise for souls on display

signal advertisement_changed(soul_id: String)

# soul_id -> SoulAdvertisement
var advertisements: Dictionary = {}

func _ready() -> void:
	# Connect to discovery signals to auto-update advertisements
	var discovery_manager = get_node("/root/Root/Gameplay/DiscoveryManager")
	discovery_manager.discovery_made.connect(_on_discovery_made)

## Get or create advertisement for a soul
func get_advertisement(soul_id: String) -> SoulAdvertisement:
	if not advertisements.has(soul_id):
		advertisements[soul_id] = SoulAdvertisement.new(soul_id)
	return advertisements[soul_id]

## Check if we have an advertisement for a soul
func has_advertisement(soul_id: String) -> bool:
	return advertisements.has(soul_id)

## Auto-advertise everything we know about a soul
func auto_advertise_all_known(soul_id: String, soul: SoulData, discovery_log: DiscoveryLog) -> void:
	var ad = get_advertisement(soul_id)
	ad.auto_advertise_from_discoveries(discovery_log, soul)
	advertisement_changed.emit(soul_id)
	print("[Advertisement] Auto-advertised all known properties for soul %s" % soul_id)

## Remove advertisement when soul removed from display
func clear_advertisement(soul_id: String) -> void:
	if advertisements.has(soul_id):
		advertisements.erase(soul_id)
		print("[Advertisement] Cleared advertisement for soul %s" % soul_id)

## Called when a discovery is made - auto-update advertisement if soul is on display
func _on_discovery_made(soul_id: String) -> void:
	# Only auto-update if this soul has an advertisement (i.e., it's on display)
	if not has_advertisement(soul_id):
		return

	var inventory_manager = get_node("/root/Root/Gameplay/InventoryManager")
	var discovery_manager = get_node("/root/Root/Gameplay/DiscoveryManager")

	var soul = inventory_manager.get_soul_by_id(soul_id)
	if not soul:
		return

	var discovery_log = discovery_manager.get_discovery_log(soul_id)
	auto_advertise_all_known(soul_id, soul, discovery_log)
	print("[Advertisement] Auto-updated advertisement for %s after discovery" % soul_id)

## Create a virtual soul with only advertised properties (for matching/pricing)
func create_advertised_soul(soul: SoulData, ad: SoulAdvertisement) -> Dictionary:
	"""
	Returns a dictionary representing what buyers/pricing see:
	{
		"has_era": bool,
		"era": Era (if has_era),
		"has_death": bool,
		"death": CauseOfDeath (if has_death),
		"stats": {
			stat_key: {
				"level": AdvertLevel,
				"exact": value (if ADVERTISE_EXACT),
				"min": value (if ADVERTISE_RANGE),
				"max": value (if ADVERTISE_RANGE)
			}
		}
	}
	"""
	var advertised = {
		"soul_id": soul.id,
		"name": soul.name,  # Name is always visible
		"has_era": ad.advertise_era,
		"has_death": ad.advertise_death,
		"stats": {}
	}

	if ad.advertise_era:
		advertised["era"] = soul.era

	if ad.advertise_death:
		advertised["death"] = soul.causeOfDeath

	# Include advertised stats with their advertisement level
	for stat_key in ad.get_advertised_stat_keys():
		var stat_ad = ad.get_stat_advertisement(stat_key)
		var level = stat_ad.get("level", SoulAdvertisement.AdvertLevel.NOT_ADVERTISED)

		match level:
			SoulAdvertisement.AdvertLevel.ADVERTISE_PRESENCE:
				# Just show stat exists (no value info)
				advertised["stats"][stat_key] = {
					"level": level
				}

			SoulAdvertisement.AdvertLevel.ADVERTISE_RANGE:
				# Show advertised range (could be a lie!)
				advertised["stats"][stat_key] = {
					"level": level,
					"min": stat_ad.get("min", 0),
					"max": stat_ad.get("max", 100)
				}

			SoulAdvertisement.AdvertLevel.ADVERTISE_EXACT:
				# Show exact value
				advertised["stats"][stat_key] = {
					"level": level,
					"exact": stat_ad.get("exact", soul.stats.get(stat_key, 0))
				}

	return advertised

## Create a virtual soul from a discovery log (for buyer investigations)
func create_advertised_soul_from_log(soul: SoulData, discovery_log: DiscoveryLog) -> Dictionary:
	"""
	Similar to create_advertised_soul but based on a discovery log instead of advertisement.
	Used to simulate what a buyer knows after running their own tests.
	"""
	var advertised = {
		"soul_id": soul.id,
		"name": soul.name,
		"has_era": discovery_log.known_era,
		"has_death": discovery_log.known_death,
		"stats": {}
	}

	if discovery_log.known_era:
		advertised["era"] = soul.era

	if discovery_log.known_death:
		advertised["death"] = soul.causeOfDeath

	# Include all discovered stats as exact values
	for stat_key in discovery_log.get_discovered_stats():
		if soul.stats.has(stat_key):
			advertised["stats"][stat_key] = {
				"level": SoulAdvertisement.AdvertLevel.ADVERTISE_EXACT,
				"exact": soul.stats[stat_key]
			}

	# Include stat hints (ranges and presence)
	for stat_key in soul.stats.keys():
		if not discovery_log.knows_stat(stat_key) and discovery_log.has_stat_hints(stat_key):
			var hints = discovery_log.get_stat_hints(stat_key)
			var has_range = false

			# Check if we have a range hint
			for hint in hints:
				if "-" in hint and hint != "Present":
					var parts = hint.split("-")
					if parts.size() == 2:
						var min_val = parts[0].to_int()
						var max_val = parts[1].to_int()
						if min_val >= 0 and max_val <= 100 and min_val < max_val:
							advertised["stats"][stat_key] = {
								"level": SoulAdvertisement.AdvertLevel.ADVERTISE_RANGE,
								"min": min_val,
								"max": max_val
							}
							has_range = true
							break

			# If no range, but we have hints (presence only)
			if not has_range and hints.size() > 0:
				advertised["stats"][stat_key] = {
					"level": SoulAdvertisement.AdvertLevel.ADVERTISE_PRESENCE
				}

	return advertised
