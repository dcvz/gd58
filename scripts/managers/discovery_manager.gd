extends Node

## Manages what we know about each soul (discovery logs)

signal discovery_made(soul_id: String)

# soul_id -> DiscoveryLog
var soul_discoveries: Dictionary = {}

func _ready() -> void:
	pass

## Get or create discovery log for a soul
func get_discovery_log(soul_id: String) -> DiscoveryLog:
	if not soul_discoveries.has(soul_id):
		soul_discoveries[soul_id] = DiscoveryLog.new()
	return soul_discoveries[soul_id]

## Check if we have any discoveries for a soul
func has_discoveries(soul_id: String) -> bool:
	return soul_discoveries.has(soul_id)

## Discover the era of a soul
func discover_era(soul_id: String) -> void:
	var disc_log = get_discovery_log(soul_id)
	disc_log.discover_era()
	discovery_made.emit(soul_id)
	print("[Discovery] Discovered era for soul %s" % soul_id)

## Discover the cause of death of a soul
func discover_death(soul_id: String) -> void:
	var disc_log = get_discovery_log(soul_id)
	disc_log.discover_death()
	discovery_made.emit(soul_id)
	print("[Discovery] Discovered cause of death for soul %s" % soul_id)

## Discover a stat's exact value
func discover_stat(soul_id: String, stat_key: int, value: float) -> void:
	var disc_log = get_discovery_log(soul_id)
	disc_log.discover_stat(stat_key, value)
	discovery_made.emit(soul_id)
	print("[Discovery] Discovered stat %s = %.1f for soul %s" % [SoulData.SoulAttribute.keys()[stat_key], value, soul_id])

## Add a hint about era
func add_era_hint(soul_id: String, hint: String) -> void:
	var disc_log = get_discovery_log(soul_id)
	disc_log.add_era_hint(hint)
	discovery_made.emit(soul_id)
	print("[Discovery] Added era hint '%s' for soul %s" % [hint, soul_id])

## Add a hint about cause of death
func add_death_hint(soul_id: String, hint: String) -> void:
	var disc_log = get_discovery_log(soul_id)
	disc_log.add_death_hint(hint)
	discovery_made.emit(soul_id)
	print("[Discovery] Added death hint '%s' for soul %s" % [hint, soul_id])

## Add a hint about a stat
func add_stat_hint(soul_id: String, stat_key: int, hint: String) -> void:
	var disc_log = get_discovery_log(soul_id)
	disc_log.add_stat_hint(stat_key, hint)
	discovery_made.emit(soul_id)
	print("[Discovery] Added stat hint '%s' for soul %s" % [hint, soul_id])

## Remove all discoveries for a soul (when sold)
func clear_discoveries(soul_id: String) -> void:
	if soul_discoveries.has(soul_id):
		soul_discoveries.erase(soul_id)
		print("[Discovery] Cleared discoveries for soul %s" % soul_id)
