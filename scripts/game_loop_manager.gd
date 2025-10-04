extends Node

# Load InterestMatcher for generating buyer interests
const InterestMatcher = preload("res://scripts/interest_matcher.gd")

# Signals for day cycle and simulation
signal day_started(day_number: int)
signal day_ended(day_number: int)
signal simulation_paused()
signal simulation_resumed()
signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)
signal encounter_arrived(encounter_type: String)
signal special_opportunity_available()

# Menus that overlay the shop view (pauses simulation)
enum Menu {
	NONE,
	DISPLAY,        # Curate display slots
	ANALYZE,        # Run analyses on souls in storage
	SPECIAL         # Handle special opportunities (auctions, black market, etc.)
}

# State variables
var current_day: int = 0
var is_day_active: bool = false
var is_simulation_paused: bool = false
var current_menu: Menu = Menu.NONE

# Day simulation variables
var day_time_elapsed: float = 0.0
@export var day_duration: float = 30.0  # Total seconds per day (adjustable in editor)
var encounter_queue: Array = []
var has_special_opportunity: bool = false

func _ready() -> void:
	print("GameLoopManager initialized")
	# Start the first day automatically
	start_new_day()

func _process(delta: float) -> void:
	if not is_day_active or is_simulation_paused:
		return

	# Advance day simulation
	day_time_elapsed += delta

	# Check if day should end
	if day_time_elapsed >= day_duration:
		end_day()

func start_new_day() -> void:
	current_day += 1
	is_day_active = true
	day_time_elapsed = 0.0

	# Initialize the day
	_roll_daily_encounters()
	_roll_special_opportunity()

	day_started.emit(current_day)
	print("=== Day %d Started ===" % current_day)

func _roll_daily_encounters() -> void:
	# Roll 3-5 encounters for the day
	encounter_queue.clear()
	var num_encounters = randi_range(3, 5)

	for i in range(num_encounters):
		var encounter_types = ["seller", "buyer", "broker"]
		var encounter_type = encounter_types[randi() % encounter_types.size()]
		var encounter = {
			"type": encounter_type,
			"arrival_time": randf() * day_duration * 0.8  # Arrive in first 80% of day
		}

		# Add type-specific interests using centralized InterestMatcher
		if encounter_type == "buyer":
			# Generate random interests (80% single, 20% multiple)
			encounter["interests"] = InterestMatcher.generate_random_interests()

		elif encounter_type == "seller":
			# Sellers bring a soul to sell
			encounter["soul_to_sell"] = SoulData.generate_random_soul()

		encounter_queue.append(encounter)

	# Sort by arrival time
	encounter_queue.sort_custom(func(a, b): return a.arrival_time < b.arrival_time)
	print("Rolled %d encounters for today:" % num_encounters)
	for encounter in encounter_queue:
		if encounter.type == "buyer":
			var interests_str = ""
			for interest in encounter.get("interests", []):
				if interests_str != "":
					interests_str += " AND "
				interests_str += InterestMatcher.format_interest_for_display(interest)
			print("  - %s arriving at %.1f seconds (wants: %s)" % [encounter.type, encounter.arrival_time, interests_str])
		elif encounter.type == "seller":
			print("  - %s arriving at %.1f seconds (selling %s)" % [encounter.type, encounter.arrival_time, encounter.soul_to_sell.name])
		else:
			print("  - %s arriving at %.1f seconds" % [encounter.type, encounter.arrival_time])

func _weighted_random(options: Array, weights: Array) -> String:
	var total_weight = 0
	for w in weights:
		total_weight += w

	var random_value = randf() * total_weight
	var cumulative = 0

	for i in range(options.size()):
		cumulative += weights[i]
		if random_value <= cumulative:
			return options[i]

	return options[0]  # Fallback


func _roll_special_opportunity() -> void:
	# Random chance for special opportunity
	has_special_opportunity = randf() < 0.3  # 30% chance
	if has_special_opportunity:
		print("Special opportunity available today!")

func get_day_progress() -> float:
	"""Returns 0.0 to 1.0 representing how much of the day has passed"""
	if day_duration <= 0:
		return 0.0
	return clamp(day_time_elapsed / day_duration, 0.0, 1.0)

# Menu management
func open_menu(menu: Menu) -> void:
	if current_menu != Menu.NONE:
		print("Menu already open, close current menu first")
		return

	current_menu = menu
	is_simulation_paused = true
	simulation_paused.emit()

	var menu_name = Menu.keys()[menu]
	menu_opened.emit(menu_name)
	print("Opened %s menu (simulation paused)" % menu_name)

func close_menu() -> void:
	if current_menu == Menu.NONE:
		return

	var menu_name = Menu.keys()[current_menu]
	current_menu = Menu.NONE
	is_simulation_paused = false
	simulation_resumed.emit()
	menu_closed.emit(menu_name)
	print("Closed %s menu (simulation resumed)" % menu_name)

# Convenience functions for opening specific menus
func open_display_menu() -> void:
	open_menu(Menu.DISPLAY)

func open_analyze_menu() -> void:
	open_menu(Menu.ANALYZE)

func open_special_menu() -> void:
	if has_special_opportunity:
		open_menu(Menu.SPECIAL)
	else:
		print("No special opportunity available today")

func end_day() -> void:
	print("=== Day %d Complete ===" % current_day)

	# Perform end-of-day upkeep
	_perform_upkeep()

	day_ended.emit(current_day)
	is_day_active = false

	# TODO: Check win condition (legendary set complete?)

func _perform_upkeep() -> void:
	# TODO: Check storage capacity, apply integrity decay, update market prices
	print("Performing end-of-day upkeep...")
	print("- Checking storage capacity")
	print("- Applying integrity decay to souls")
	print("- Updating market prices")
