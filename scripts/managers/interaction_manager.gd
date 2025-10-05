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
		interaction["interests"] = shade_data.get("interests", [])
		interaction["selected_soul_plinth"] = shade_data.get("selected_soul_plinth", null)

		# Calculate the price the buyer is willing to pay
		var plinth = shade_data.get("selected_soul_plinth", null)
		if plinth and plinth.displayed_soul:
			var soul = plinth.displayed_soul
			var offer_price = SoulPricing.calculate_customer_offer(soul, shade_data.get("interests", []))
			interaction["offer_price"] = offer_price
			print("[InteractionManager] Buyer offering %d KP for %s" % [offer_price, soul.name])
		else:
			# No valid soul - buyer arrived but soul was removed/sold before they could interact
			# Don't add this buyer to the queue
			print("[InteractionManager] WARNING: Buyer arrived but soul is no longer available, skipping interaction")
			return

	elif shade_data.type == "seller":
		interaction["soul_to_sell"] = shade_data.get("soul_to_sell", null)

		# Calculate the price the seller is asking
		var soul = shade_data.get("soul_to_sell", null)
		if soul:
			var asking_price = SoulPricing.calculate_seller_asking_price(soul, [])
			interaction["asking_price"] = asking_price
			print("[InteractionManager] Seller asking %d KP for %s" % [asking_price, soul.name])
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
