extends CharacterBody3D

## Represents a customer in the shop

# Load InterestMatcher for checking soul interests
const InterestMatcher = preload("res://scripts/interest_matcher.gd")

enum State {
	BROWSING,           # Walking to plinths
	INSPECTING,         # Looking at a soul on a plinth
	WALKING_TO_CHECKOUT,# Walking to checkout
	AT_CHECKOUT,        # Waiting at checkout desk
	WALKING_TO_EXIT,    # Walking back to spawn to leave
	LEAVING             # Exiting the shop
}

var current_state: State = State.BROWSING
var encounter_data: Dictionary = {}
var attention_icon: Node3D
var game_loop_manager: Node

# Movement variables
var move_speed: float = 2.0
var current_target: Vector3
var inspection_timer: float = 0.0

# Browsing path
var plinths_to_visit: Array = []
var current_plinth_index: int = 0
var will_buy: bool = false
var selected_soul_plinth: Node3D = null
var spawn_position: Vector3 = Vector3.ZERO

@onready var icon_scene: PackedScene = preload("res://scenes/attention_icon.tscn")

func _ready() -> void:
	# Get game loop manager reference
	game_loop_manager = get_node("/root/Root/Gameplay/GameLoopManager")

	# Listen for day ending
	game_loop_manager.day_ended.connect(_on_day_ended)

	# Create attention icon (hidden by default)
	attention_icon = icon_scene.instantiate()
	add_child(attention_icon)
	attention_icon.visible = false
	attention_icon.position = Vector3(0, 2, 0)  # Above customer

func setup(encounter: Dictionary) -> void:
	encounter_data = encounter

func start_browsing(available_plinths: Array) -> void:
	# Set up browsing path based on customer type
	if encounter_data.type == "seller":
		# Sellers go straight to checkout
		print("[Shade] Seller heading directly to checkout")
		_go_to_checkout()
		return

	# Buyers and brokers browse plinths first
	if available_plinths.size() > 0:
		# Pick 2-3 random plinths to visit
		var num_to_visit = mini(randi_range(2, 3), available_plinths.size())
		var shuffled = available_plinths.duplicate()
		shuffled.shuffle()
		plinths_to_visit = shuffled.slice(0, num_to_visit)

		if encounter_data.type == "buyer":
			var interests_str = ""
			for interest in encounter_data.get("interests", []):
				if interests_str != "":
					interests_str += " AND "
				interests_str += InterestMatcher.format_interest_for_display(interest)
			print("[Shade] Buyer browsing %d plinths, looking for: %s" % [num_to_visit, interests_str])
		else:
			print("[Shade] Broker browsing %d plinths" % num_to_visit)

		_go_to_next_plinth()
	else:
		# No plinths available, just leave
		print("[Shade] No plinths available to browse, leaving")
		leave_shop()

func _process(delta: float) -> void:
	# Don't move if simulation is paused
	if game_loop_manager and game_loop_manager.is_simulation_paused:
		return

	# Allow movement when leaving, even if day is over
	if current_state == State.WALKING_TO_EXIT:
		_walk_to_exit_behavior(delta)
		return

	# Don't do other behaviors if day is over
	if game_loop_manager and not game_loop_manager.is_day_active:
		return

	match current_state:
		State.BROWSING:
			_browse_behavior(delta)
		State.INSPECTING:
			_inspect_behavior(delta)
		State.WALKING_TO_CHECKOUT:
			_walk_to_checkout_behavior(delta)

func _browse_behavior(delta: float) -> void:
	# Move toward current target (plinth)
	var distance_to_target = global_position.distance_to(current_target)

	if distance_to_target < 0.3:
		# Reached plinth, start inspecting
		current_state = State.INSPECTING
		inspection_timer = randf_range(1.5, 3.0)
		velocity = Vector3.ZERO
		return

	# Move toward target
	var direction = (current_target - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func _walk_to_checkout_behavior(delta: float) -> void:
	# Move toward checkout desk
	var distance_to_target = global_position.distance_to(current_target)

	if distance_to_target < 0.3:
		# Arrived at checkout
		velocity = Vector3.ZERO
		move_to_checkout()
		return

	# Move toward target
	var direction = (current_target - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func _inspect_behavior(delta: float) -> void:
	# Look at soul for a bit
	inspection_timer -= delta

	if inspection_timer <= 0:
		# Safety check: ensure we have a valid plinth to inspect
		if current_plinth_index >= plinths_to_visit.size():
			print("[Shade] Error: Invalid plinth index, leaving")
			leave_shop()
			return

		# Check if this plinth has what the buyer wants (using centralized matcher)
		if encounter_data.type == "buyer" and encounter_data.has("interests"):
			var current_plinth = plinths_to_visit[current_plinth_index]
			var soul = current_plinth.displayed_soul

			if soul and InterestMatcher.soul_matches_interests(soul, encounter_data.interests):
				# Found a soul matching ALL their interests! Go to checkout
				will_buy = true
				selected_soul_plinth = current_plinth
				print("[Shade] Buyer found matching soul (%s) - heading to checkout!" % soul.name)

		current_plinth_index += 1

		if current_plinth_index < plinths_to_visit.size():
			# Visit next plinth
			_go_to_next_plinth()
		else:
			# Done browsing, decide what to do
			if will_buy:
				_go_to_checkout()
			else:
				# Didn't find what they wanted, leave
				if encounter_data.type == "buyer":
					var interests_str = ""
					for interest in encounter_data.get("interests", []):
						if interests_str != "":
							interests_str += " AND "
						interests_str += InterestMatcher.format_interest_for_display(interest)
					print("[Shade] Buyer didn't find matching soul - leaving disappointed (wanted: %s)" % interests_str)
				else:
					print("[Shade] Broker finished browsing - leaving")
				leave_shop()

func _go_to_next_plinth() -> void:
	if current_plinth_index < plinths_to_visit.size():
		var plinth = plinths_to_visit[current_plinth_index]
		current_target = plinth.global_position + Vector3(0.5, 0, -1.0)  # Stand in front
		current_state = State.BROWSING

func _go_to_checkout() -> void:
	# Need to walk to checkout, not teleport
	var checkout_desks = get_tree().get_nodes_in_group("checkout_desk")
	if checkout_desks.size() > 0:
		var desk = checkout_desks[0]
		current_target = desk.get_shade_position()
		current_state = State.WALKING_TO_CHECKOUT

func move_to_checkout() -> void:
	# Called when arriving at checkout
	current_state = State.AT_CHECKOUT

	# Add to interaction queue instead of showing icon
	var interaction_manager = get_node("/root/Root/Gameplay/InteractionManager")
	if interaction_manager:
		var interaction_data = encounter_data.duplicate()
		if selected_soul_plinth:
			interaction_data["selected_soul_plinth"] = selected_soul_plinth
		interaction_manager.add_interaction(interaction_data)
		print("[Shade] %s arrived at checkout - added to interaction queue" % encounter_data.type.capitalize())

	# Disappear - despawn immediately
	queue_free()

func leave_shop() -> void:
	current_state = State.WALKING_TO_EXIT
	current_target = spawn_position
	attention_icon.visible = false

func _on_day_ended(_day_number: int) -> void:
	# When day ends, everyone goes home immediately
	print("[Shade] Day ended - going home")
	leave_shop()

func _walk_to_exit_behavior(delta: float) -> void:
	# Move back toward spawn position
	var distance_to_exit = global_position.distance_to(current_target)

	if distance_to_exit < 0.3:
		# Reached exit, despawn
		current_state = State.LEAVING
		velocity = Vector3.ZERO
		queue_free()
		return

	# Move toward exit
	var direction = (current_target - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
