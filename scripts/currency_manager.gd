extends Node

## Manages the player's Karmic Points (KP) currency

signal currency_changed(new_amount: int)

var karmic_points: int = 200  # Starting balance

func _ready() -> void:
	print("CurrencyManager initialized with %d KP" % karmic_points)

## Add KP to the player's balance
func add_kp(amount: int) -> void:
	karmic_points += amount
	currency_changed.emit(karmic_points)
	print("Added %d KP (Total: %d KP)" % [amount, karmic_points])

## Remove KP from the player's balance (returns true if successful)
func spend_kp(amount: int) -> bool:
	if karmic_points >= amount:
		karmic_points -= amount
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
