extends CharacterBody3D

## Represents a customer in the shop


enum State {
	BROWSING,           # Walking to plinths
	INSPECTING,         # Looking at a soul on a plinth
	WALKING_TO_CHECKOUT,# Walking to checkout
	AT_CHECKOUT,        # Waiting at checkout desk
	WALKING_TO_EXIT,    # Walking back to spawn to leave
	LEAVING,            # Exiting the shop
	FADING              # Disappearing into thin air
}

var appearing: bool
var current_state: State = State.BROWSING
var encounter_data: Dictionary = {}
var game_loop_manager: Node
var shadeSprite: AnimatedSprite3D

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

func _ready() -> void:
	# Get game loop manager reference + animations
	game_loop_manager = get_node("/root/Root/Gameplay/GameLoopManager")
	shadeSprite = get_node("ShadeAnimatedSprite3D")
	appearing = true # play fade in animation once on a new shade
	

	# Listen for day ending
	game_loop_manager.day_ended.connect(_on_day_ended)

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
			var wishes = encounter_data.get("wishes", [])
			var wishes_str = ""
			for wish in wishes:
				if wishes_str != "":
					wishes_str += ", "
				wishes_str += wish.get_description()
			print("[Shade] Collector browsing %d plinths, wishes: %s" % [num_to_visit, wishes_str])
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
	
	if appearing:
		_appear()

	match current_state:
		State.BROWSING:
			_browse_behavior(delta)
		State.INSPECTING:
			_inspect_behavior(delta)
		State.WALKING_TO_CHECKOUT:
			_walk_to_checkout_behavior(delta)
		State.FADING:
			_fade_behavior(delta)

func fade() -> void:
	shadeSprite.play("fade")
	current_state = State.FADING
	
func _fade_behavior(delta: float) -> void:
	if !shadeSprite.is_playing():
		queue_free()

func _appear() -> void:
	if !shadeSprite.is_playing():
		shadeSprite.play(&"hover")
		appearing = false

func _browse_behavior(delta: float) -> void:
	# Move toward current target (plinth)
	var distance_to_target = global_position.distance_to(current_target)

	if distance_to_target < 1.0:
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

		# Check if this plinth has what the collector wants (using new WishSystem)
		if encounter_data.type == "buyer" and encounter_data.has("wishes"):
			var current_plinth = plinths_to_visit[current_plinth_index]
			var soul = current_plinth.displayed_soul

			if soul:
				# Get what we're advertising about this soul
				var advertisement_manager = get_node("/root/Root/Gameplay/AdvertisementManager")
				var ad = advertisement_manager.get_advertisement(soul.id)
				var discovery_manager = get_node("/root/Root/Gameplay/DiscoveryManager")
				var ad_log = discovery_manager.get_discovery_log(soul.id)

				# Check wish matching based on collector's requirements
				var wishes = encounter_data.get("wishes", [])
				var require_all = encounter_data.get("require_all_wishes", false)

				if require_all:
					# Strict collector: ALL wishes must be met
					var all_met = true
					for wish in wishes:
						var match_result = WishSystem.check_wish_match(wish, soul, ad_log)
						if not match_result.met:
							all_met = false
							break
					if all_met and wishes.size() > 0:
						will_buy = true
						selected_soul_plinth = current_plinth
						print("[Shade] Collector found soul matching ALL wishes (%s) - heading to checkout!" % soul.name)
				else:
					# Flexible collector: ANY wish met is enough
					for wish in wishes:
						var match_result = WishSystem.check_wish_match(wish, soul, ad_log)
						if match_result.met:
							will_buy = true
							selected_soul_plinth = current_plinth
							print("[Shade] Collector found soul matching a wish (%s) - heading to checkout!" % soul.name)
							break

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
					var wishes = encounter_data.get("wishes", [])
					var wishes_str = ""
					for wish in wishes:
						if wishes_str != "":
							wishes_str += ", "
						wishes_str += wish.get_description()
					print("[Shade] Collector didn't find matching soul - leaving disappointed (wanted: %s)" % wishes_str)
				else:
					print("[Shade] Broker finished browsing - leaving")
				leave_shop()

func _go_to_next_plinth() -> void:
	if current_plinth_index < plinths_to_visit.size():
		var plinth = plinths_to_visit[current_plinth_index]
		current_target = plinth.global_position  # center of plinth
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
	
	# fade from the shop
	fade()

func leave_shop() -> void:
	current_state = State.WALKING_TO_EXIT
	current_target = spawn_position

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
		fade()
		return

	# Move toward exit
	var direction = (current_target - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
