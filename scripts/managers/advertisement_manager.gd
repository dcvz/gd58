extends Node

## Manages what properties we advertise for souls on display

signal advertisement_changed(soul_id: String)

# soul_id -> SoulAdvertisement
var advertisements: Dictionary = {}

func _ready() -> void:
	pass

## Get or create advertisement for a soul
func get_advertisement(soul_id: String) -> SoulAdvertisement:
	if not advertisements.has(soul_id):
		advertisements[soul_id] = SoulAdvertisement.new(soul_id)
	return advertisements[soul_id]

## Check if we have an advertisement for a soul
func has_advertisement(soul_id: String) -> bool:
	return advertisements.has(soul_id)

## Auto-advertise everything we know about a soul
func auto_advertise_all_known(soul_id: String, discovery_log: DiscoveryLog) -> void:
	var ad = get_advertisement(soul_id)
	ad.auto_advertise_from_discoveries(discovery_log)
	advertisement_changed.emit(soul_id)
	print("[Advertisement] Auto-advertised all known properties for soul %s" % soul_id)

## Remove advertisement when soul removed from display
func clear_advertisement(soul_id: String) -> void:
	if advertisements.has(soul_id):
		advertisements.erase(soul_id)
		print("[Advertisement] Cleared advertisement for soul %s" % soul_id)

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
