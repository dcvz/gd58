extends Node

## Manages customer spawning and checkout queue

var game_loop_manager: Node
var display_manager: Node
var customer_scene: PackedScene = preload("res://scenes/shade.tscn")
var checkout_desk: Node3D
var spawn_area: Node3D
var world_node: Node

# Active customers in the shop
var browsing_customers: Array[Node3D] = []
var checkout_queue: Array[Node3D] = []

# Spawn tracking
var encounters_to_spawn: Array = []
var next_spawn_index: int = 0

func _ready() -> void:
	await get_tree().process_frame

	game_loop_manager = get_node("/root/Root/Gameplay/GameLoopManager")
	display_manager = get_node("/root/Root/Gameplay/DisplayManager")
	world_node = get_node("/root/Root/World")

	# Find checkout desk
	var desks = get_tree().get_nodes_in_group("checkout_desk")
	if desks.size() > 0:
		checkout_desk = desks[0]
		print("Found checkout desk at: ", checkout_desk.global_position)

	# Find spawn area
	var spawn_areas = get_tree().get_nodes_in_group("customer_spawn_area")
	if spawn_areas.size() > 0:
		spawn_area = spawn_areas[0]
		print("Found customer spawn area at: ", spawn_area.global_position)

	# Connect to game loop
	game_loop_manager.day_started.connect(_on_day_started)

	# Load encounters for current day if already started
	if game_loop_manager.is_day_active:
		_on_day_started(game_loop_manager.current_day)

func _process(delta: float) -> void:
	if not game_loop_manager.is_day_active or game_loop_manager.is_simulation_paused:
		return

	# Check if it's time to spawn next customer
	_check_spawn_customers()

func _on_day_started(day_number: int) -> void:
	# Get encounters from game loop
	encounters_to_spawn = game_loop_manager.encounter_queue.duplicate()
	next_spawn_index = 0

func _check_spawn_customers() -> void:
	if next_spawn_index >= encounters_to_spawn.size():
		return

	var encounter = encounters_to_spawn[next_spawn_index]
	var current_time = game_loop_manager.day_time_elapsed

	if current_time >= encounter.arrival_time:
		_spawn_customer(encounter)
		next_spawn_index += 1

func _spawn_customer(encounter: Dictionary) -> void:
	var customer = customer_scene.instantiate()
	customer.setup(encounter)

	# Place at spawn area
	var spawn_pos: Vector3
	if spawn_area:
		spawn_pos = spawn_area.get_random_spawn_position()
	else:
		spawn_pos = Vector3(0, 0, 0)

	customer.global_position = spawn_pos
	customer.spawn_position = spawn_pos  # Remember where we spawned for exit

	world_node.add_child(customer)

	# Get browsable plinths from DisplayManager
	var available_plinths = display_manager.get_browsable_plinths()

	# Start browsing with available plinths
	customer.start_browsing(available_plinths)
	browsing_customers.append(customer)

	print("Spawned %s customer at %s (browsing %d available plinths)" % [encounter.type, customer.global_position, available_plinths.size()])

func _send_to_checkout(customer: Node3D) -> void:
	if customer in browsing_customers:
		browsing_customers.erase(customer)

	checkout_queue.append(customer)
	customer.move_to_checkout()

	if checkout_desk:
		customer.global_position = checkout_desk.get_customer_position()

	print("Customer moved to checkout!")

## Get the current customer at checkout (front of queue)
func get_current_customer() -> Node3D:
	if checkout_queue.size() > 0:
		return checkout_queue[0]
	return null

## Complete transaction with current customer
func complete_transaction() -> void:
	if checkout_queue.size() > 0:
		var customer = checkout_queue.pop_front()
		customer.leave_shop()
		print("Transaction complete, customer leaving")
