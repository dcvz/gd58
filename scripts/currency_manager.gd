extends Node

## Manages the player's Karmic Points (KP) currency and daily transaction tracking

signal currency_changed(new_amount: int)

var karmic_points: int = 200  # Starting balance

# Daily transaction tracking
var daily_kp_earned: int = 0
var daily_kp_spent: int = 0
var daily_souls_sold: int = 0
var daily_souls_bought: int = 0

func _ready() -> void:
	print("CurrencyManager initialized with %d KP" % karmic_points)

## Add KP to the player's balance
func add_kp(amount: int) -> void:
	karmic_points += amount
	daily_kp_earned += amount
	currency_changed.emit(karmic_points)
	print("Added %d KP (Total: %d KP)" % [amount, karmic_points])

## Remove KP from the player's balance (returns true if successful)
func spend_kp(amount: int) -> bool:
	if karmic_points >= amount:
		karmic_points -= amount
		daily_kp_spent += amount
		currency_changed.emit(karmic_points)
		print("Spent %d KP (Remaining: %d KP)" % [amount, karmic_points])
		return true
	else:
		print("Not enough KP! Need %d, have %d" % [amount, karmic_points])
		return false

## Get current KP balance
func get_kp() -> int:
	return karmic_points

## Check if player can afford an amount
func can_afford(amount: int) -> bool:
	return karmic_points >= amount

## Track a soul purchase (for daily stats)
func record_soul_purchase() -> void:
	daily_souls_bought += 1

## Track a soul sale (for daily stats)
func record_soul_sale() -> void:
	daily_souls_sold += 1

## Get daily summary statistics
func get_daily_summary() -> Dictionary:
	return {
		"kp_earned": daily_kp_earned,
		"kp_spent": daily_kp_spent,
		"souls_sold": daily_souls_sold,
		"souls_bought": daily_souls_bought,
		"net_kp": daily_kp_earned - daily_kp_spent
	}

## Reset daily tracking (call at start of new day)
func reset_daily_stats() -> void:
	daily_kp_earned = 0
	daily_kp_spent = 0
	daily_souls_sold = 0
	daily_souls_bought = 0
	print("[CurrencyManager] Reset daily stats for new day")
