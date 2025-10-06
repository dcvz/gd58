extends Node

## Manages pending shade interactions (buyers and sellers at checkout)


signal interaction_added(interaction: Dictionary)
signal interaction_removed(interaction: Dictionary)
signal interaction_expired(interaction: Dictionary)

# Queue of pending interactions
var pending_interactions: Array[Dictionary] = []

# Expiration durations (in days)
const BUYER_EXPIRATION_DAYS_MIN = 1.0
const BUYER_EXPIRATION_DAYS_MAX = 2.0
const SELLER_EXPIRATION_DAYS_MIN = 2.0
const SELLER_EXPIRATION_DAYS_MAX = 3.0

# Reference to game loop for day duration
@onready var game_loop: Node = get_node("/root/Root/Gameplay/GameLoopManager")

# Check expiration every second
var expiration_check_timer: float = 0.0
const EXPIRATION_CHECK_INTERVAL: float = 1.0

func _process(delta: float) -> void:
	# Periodically check for expired interactions
	expiration_check_timer += delta
	if expiration_check_timer >= EXPIRATION_CHECK_INTERVAL:
		expiration_check_timer = 0.0
		check_and_remove_expired()

func add_interaction(shade_data: Dictionary) -> void:
	"""Add a shade interaction to the queue"""
	var interaction = {
		"type": shade_data.type,
		"timestamp": Time.get_ticks_msec(),
		"added_on_day": game_loop.current_day
	}

	# Assign expiration time based on type
	if shade_data.type == "buyer":
		var expiration_days = randf_range(BUYER_EXPIRATION_DAYS_MIN, BUYER_EXPIRATION_DAYS_MAX)
		interaction["expiration_days"] = expiration_days
		interaction["expires_on_day"] = game_loop.current_day + expiration_days
	elif shade_data.type == "seller":
		var expiration_days = randf_range(SELLER_EXPIRATION_DAYS_MIN, SELLER_EXPIRATION_DAYS_MAX)
		interaction["expiration_days"] = expiration_days
		interaction["expires_on_day"] = game_loop.current_day + expiration_days
	else:  # broker or other
		interaction["expiration_days"] = 1.0
		interaction["expires_on_day"] = game_loop.current_day + 1.0

	# Add type-specific data
	if shade_data.type == "buyer":
		interaction["wishes"] = shade_data.get("wishes", [])
		interaction["selected_soul_plinth"] = shade_data.get("selected_soul_plinth", null)

		# Calculate the price the collector is willing to pay using new pricing system
		var plinth = shade_data.get("selected_soul_plinth", null)
		if plinth and plinth.displayed_soul:
			var soul = plinth.displayed_soul
			var advertisement_manager = get_node("/root/Root/Gameplay/AdvertisementManager")
			var discovery_manager = get_node("/root/Root/Gameplay/DiscoveryManager")

			var ad = advertisement_manager.get_advertisement(soul.id)
			var our_discovery_log = discovery_manager.get_discovery_log(soul.id)

			# Simulate collector's own investigation - they discover 0-2 additional properties beyond what we advertise
			var collector_discovery_log = _simulate_collector_investigation(soul, our_discovery_log)

			# Use new CollectorPricing system with the collector's discovery log
			var offer_price = CollectorPricing.calculate_offer(soul, collector_discovery_log, shade_data.get("wishes", []))
			interaction["offer_price"] = offer_price
			print("[InteractionManager] Collector offering %d KP for %s (based on wishes and investigation)" % [offer_price, soul.name])
		else:
			# No valid soul - collector arrived but soul was removed/sold before they could interact
			print("[InteractionManager] WARNING: Collector arrived but soul is no longer available, skipping interaction")
			return

	elif shade_data.type == "seller":
		interaction["soul_to_sell"] = shade_data.get("soul_to_sell", null)

		# Generate seller's knowledge (what they know about the soul they're selling)
		var soul = shade_data.get("soul_to_sell", null)
		if soul:
			# Create seller's limited knowledge (ranges, not exact values)
			var seller_knowledge = SoulDisplayHelper.create_seller_knowledge(soul, 25)
			interaction["seller_knowledge"] = seller_knowledge

			# Use new SellerPricing system
			var asking_price = SellerPricing.calculate_asking_price(soul, seller_knowledge)
			interaction["asking_price"] = asking_price
			print("[InteractionManager] Seller asking %d KP for %s (based on what they know)" % [asking_price, soul.name])
		else:
			interaction["asking_price"] = 0

	pending_interactions.append(interaction)
	interaction_added.emit(interaction)
	print("Added %s interaction to queue (total: %d)" % [interaction.type, pending_interactions.size()])

func remove_interaction(index: int) -> void:
	"""Remove an interaction from the queue by index"""
	if index >= 0 and index < pending_interactions.size():
		var interaction = pending_interactions[index]
		pending_interactions.remove_at(index)
		interaction_removed.emit(interaction)
		print("Removed %s interaction from queue" % interaction.type)

func get_pending_interactions() -> Array[Dictionary]:
	"""Get all pending interactions"""
	return pending_interactions

func clear_all_interactions() -> void:
	"""Clear all pending interactions (e.g., at end of day)"""
	pending_interactions.clear()
	print("Cleared all pending interactions")

func check_and_remove_expired() -> void:
	"""Check for expired interactions and remove them"""
	var current_fractional_day = game_loop.get_current_fractional_day()

	# Iterate backwards to safely remove items
	for i in range(pending_interactions.size() - 1, -1, -1):
		var interaction = pending_interactions[i]
		if current_fractional_day >= interaction.get("expires_on_day", 999999):
			print("[InteractionManager] %s interaction expired (was waiting %.1f days)" % [interaction.type, interaction.expiration_days])
			var expired = pending_interactions[i]
			pending_interactions.remove_at(i)
			interaction_expired.emit(expired)

func get_days_remaining(interaction: Dictionary) -> float:
	"""Get the number of days remaining before this interaction expires"""
	var current_fractional_day = game_loop.get_current_fractional_day()
	var expires_on = interaction.get("expires_on_day", current_fractional_day + 1)
	return max(0.0, expires_on - current_fractional_day)

func _simulate_collector_investigation(soul: SoulData, our_log: DiscoveryLog) -> DiscoveryLog:
	"""Simulate a collector running their own tests to discover 0-2 additional properties"""
	# Create a copy of our discovery log as the starting point
	var collector_log = DiscoveryLog.new()
	collector_log.known_era = our_log.known_era
	collector_log.known_death = our_log.known_death
	collector_log.era_hints = our_log.era_hints.duplicate()
	collector_log.death_hints = our_log.death_hints.duplicate()
	collector_log.known_stats = our_log.known_stats.duplicate()
	collector_log.stat_hints = our_log.stat_hints.duplicate(true)

	# Collector discovers 0-2 additional stats we don't know about
	var num_discoveries = randi_range(0, 2)
	var undiscovered_stats = []

	for stat_key in soul.stats.keys():
		if not our_log.knows_stat(stat_key):
			undiscovered_stats.append(stat_key)

	if undiscovered_stats.size() > 0:
		undiscovered_stats.shuffle()
		for i in range(min(num_discoveries, undiscovered_stats.size())):
			var stat_key = undiscovered_stats[i]
			collector_log.known_stats[stat_key] = soul.stats[stat_key]

	return collector_log
