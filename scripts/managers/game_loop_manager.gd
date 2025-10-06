extends Node


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
@export var day_duration: float = 90.0  # Total seconds per day (adjustable in editor)
var encounter_queue: Array = []
var has_special_opportunity: bool = false

var is_game_initialized: bool = false

func _ready() -> void:
	print("GameLoopManager initialized")

	# Wait for all managers to be ready
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame to ensure all managers initialized

	# Initialize game on first run (starter package)
	if not is_game_initialized:
		_initialize_starter_package()
		is_game_initialized = true

	# Start the first day automatically
	start_new_day()

func _initialize_starter_package() -> void:
	print("[GameLoop] Setting up starter package...")

	var machine_manager = get_node("/root/Root/Gameplay/MachineManager")
	var inventory_manager = get_node("/root/Root/Gameplay/InventoryManager")
	var currency_manager = get_node("/root/Root/Gameplay/CurrencyManager")
	var discovery_manager = get_node("/root/Root/Gameplay/DiscoveryManager")

	# 1. Grant starter machine (Basic Analyzer)
	machine_manager.grant_machine(MachineData.MachineType.BASIC_ANALYZER)
	print("[GameLoop] Granted Basic Analyzer (starter machine)")

	# 2. Set starting currency (300 KP)
	currency_manager.add_kp(300)
	print("[GameLoop] Starting currency: 300 KP")

	# 3. Create 3 starter souls with partial knowledge
	_create_starter_souls(inventory_manager, discovery_manager)

	print("[GameLoop] Starter package complete!")

func _create_starter_souls(inventory_manager: Node, discovery_manager: Node) -> void:
	# Soul 1: Well-known - Era + 2 stats (ON DISPLAY)
	var soul1 = SoulData.generate_random_soul()
	inventory_manager.add_soul(soul1)

	var disc_log1 = discovery_manager.get_discovery_log(soul1.id)
	disc_log1.discover_era()

	var stat_keys1 = soul1.stats.keys()
	stat_keys1.shuffle()
	for i in range(min(2, stat_keys1.size())):
		disc_log1.discover_stat(stat_keys1[i], soul1.stats[stat_keys1[i]])

	inventory_manager.add_to_display(soul1.id)
	print("[GameLoop] Created starter soul 1: %s (Era + 2 stats, ON DISPLAY)" % soul1.name)

	# Soul 2: Partially known - 1 stat + hints (ON DISPLAY)
	var soul2 = SoulData.generate_random_soul()
	inventory_manager.add_soul(soul2)

	var disc_log2 = discovery_manager.get_discovery_log(soul2.id)

	var stat_keys2 = soul2.stats.keys()
	if stat_keys2.size() > 0:
		stat_keys2.shuffle()
		disc_log2.discover_stat(stat_keys2[0], soul2.stats[stat_keys2[0]])

		# Add 1-2 stat hints (ranges) for other stats
		var num_hints = randi_range(1, min(2, stat_keys2.size() - 1))
		for i in range(1, 1 + num_hints):
			if i < stat_keys2.size():
				var stat_key = stat_keys2[i]
				var actual_value = soul2.stats[stat_key]
				var range_width = 25
				var min_val = max(0, actual_value - range_width / 2)
				var max_val = min(100, actual_value + range_width / 2)
				var hint = "%d-%d" % [int(min_val), int(max_val)]
				disc_log2.add_stat_hint(stat_key, hint)

	inventory_manager.add_to_display(soul2.id)
	print("[GameLoop] Created starter soul 2: %s (1 stat + hints, ON DISPLAY)" % soul2.name)

	# Soul 3: Mystery soul - only 1 stat known (IN STORAGE - needs research!)
	var soul3 = SoulData.generate_random_soul()
	inventory_manager.add_soul(soul3)

	var disc_log3 = discovery_manager.get_discovery_log(soul3.id)

	var stat_keys3 = soul3.stats.keys()
	if stat_keys3.size() > 0:
		stat_keys3.shuffle()
		disc_log3.discover_stat(stat_keys3[0], soul3.stats[stat_keys3[0]])

	# Soul 3 stays in storage - player needs to research it!
	print("[GameLoop] Created starter soul 3: %s (1 stat only, IN STORAGE)" % soul3.name)

func _process(delta: float) -> void:
	if not is_day_active or is_simulation_paused:
		return

	# Advance day simulation
	day_time_elapsed += delta

	# Check if day should end
	if day_time_elapsed >= day_duration:
		end_day()

## Get the current day as a fractional value (accounts for partial day progress)
func get_current_fractional_day() -> float:
	var progress = day_time_elapsed / day_duration if day_duration > 0 else 0.0
	return current_day + progress

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
	# Roll 9-15 encounters for the day (tripled from 3-5)
	encounter_queue.clear()
	var num_encounters = randi_range(9, 15)

	# Day-based encounter distribution (easier early game)
	var buyer_threshold: float
	var seller_threshold: float

	if current_day <= 3:
		# Days 1-3: Tutorial phase - lots of sellers, simple buyers
		buyer_threshold = 0.25     # 25% buyers
		seller_threshold = 0.95    # 70% sellers (0.25 + 0.70 = 0.95)
		# Remaining 5% are brokers
	elif current_day <= 7:
		# Days 4-7: Ramp up
		buyer_threshold = 0.50     # 50% buyers
		seller_threshold = 0.90    # 40% sellers (0.50 + 0.40 = 0.90)
		# Remaining 10% are brokers
	else:
		# Day 8+: Normal difficulty
		buyer_threshold = 0.60     # 60% buyers
		seller_threshold = 0.85    # 25% sellers (0.60 + 0.25 = 0.85)
		# Remaining 15% are brokers

	for i in range(num_encounters):
		var roll = randf()
		var encounter_type: String
		if roll < buyer_threshold:
			encounter_type = "buyer"
		elif roll < seller_threshold:
			encounter_type = "seller"
		else:
			encounter_type = "broker"
		var encounter = {
			"type": encounter_type,
			"arrival_time": randf() * day_duration * 0.75  # Arrive in first 75% of day (avoid last quarter)
		}

		# Add type-specific interests using centralized InterestMatcher
		if encounter_type == "buyer":
			# Assign matching mode based on day (early game = more flexible buyers)
			var flexible_chance = 0.8 if current_day <= 3 else 0.2  # 80% flexible early, 20% later
			var is_flexible = randf() < flexible_chance
			encounter["matching_mode"] = InterestMatcher.MatchingMode.ANY if is_flexible else InterestMatcher.MatchingMode.ALL

			# Generate interests based on buyer type
			if is_flexible:
				# Flexible buyers (ANY): 2-3 interests for variety
				var num_interests = randi_range(2, 3)
				encounter["interests"] = []
				for j in range(num_interests):
					encounter["interests"].append(InterestMatcher.generate_single_interest())
			else:
				# Picky buyers (ALL): Use natural distribution (80% single, 20% double)
				encounter["interests"] = InterestMatcher.generate_random_interests()

		elif encounter_type == "seller":
			# Sellers bring a soul to sell
			var soul = SoulData.generate_random_soul()
			encounter["soul_to_sell"] = soul

		encounter_queue.append(encounter)

	# Sort by arrival time
	encounter_queue.sort_custom(func(a, b): return a.arrival_time < b.arrival_time)
	print("Rolled %d encounters for today:" % num_encounters)
	for encounter in encounter_queue:
		if encounter.type == "buyer":
			var matching_mode = encounter.get("matching_mode", InterestMatcher.MatchingMode.ALL)
			var mode_text = "[ANY]" if matching_mode == InterestMatcher.MatchingMode.ANY else "[ALL]"
			var connector = " OR " if matching_mode == InterestMatcher.MatchingMode.ANY else " AND "

			var interests_str = ""
			for interest in encounter.get("interests", []):
				if interests_str != "":
					interests_str += connector
				interests_str += InterestMatcher.format_interest_for_display(interest)
			print("  - %s arriving at %.1f seconds %s (wants: %s)" % [encounter.type, encounter.arrival_time, mode_text, interests_str])
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
