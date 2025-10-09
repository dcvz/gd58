extends Node

## Manages the visual display of souls on plinths
##
## Display slots can be purchased to expand the display room

signal plinths_changed()

var inventory_manager: Node
var game_loop_manager: Node
var currency_manager: Node
var soul_scene: PackedScene = preload("res://scenes/soul.tscn")
var plinth_scene: PackedScene = preload("res://scenes/display_plinth.tscn")
var soul_visuals: Array[Node3D] = []
var objects_node: Node
var display_plinths: Array = []
var soul_plinth_assignments: Dictionary = {}  # Maps soul_id -> plinth

## Number of display plinths owned
var owned_plinth_count: int = 3

## Cost to purchase next plinth
const BASE_PLINTH_COST: int = 200
const PLINTH_COST_INCREMENT: int = 100

## Plinth positions (captured from scene at startup)
var plinth_positions: Array[Vector3] = []

func _ready() -> void:
	# Wait for scene to be fully loaded
	await get_tree().process_frame

	# Get references
	inventory_manager = get_node("/root/Root/Gameplay/InventoryManager")
	game_loop_manager = get_node("/root/Root/Gameplay/GameLoopManager")
	currency_manager = get_node("/root/Root/Gameplay/CurrencyManager")
	objects_node = get_node("/root/Root/World/WorldGeometry/Objects")

	# Get all existing display plinths in the scene and randomize their order
	var existing_plinths = get_tree().get_nodes_in_group("display_plinth")
	existing_plinths.shuffle()

	# Use the randomized plinths as our display_plinths array
	display_plinths = existing_plinths

	# Show only the first 'owned_plinth_count' plinths, hide the rest
	for i in range(display_plinths.size()):
		if i < owned_plinth_count:
			display_plinths[i].visible = true
			_set_plinth_collision_enabled(display_plinths[i], true)
		else:
			display_plinths[i].visible = false
			_set_plinth_collision_enabled(display_plinths[i], false)

	print("[DisplayManager] Initialized with %d plinths (%d visible, %d hidden)" % [display_plinths.size(), owned_plinth_count, display_plinths.size() - owned_plinth_count])

	# Sync max display slots with owned count
	inventory_manager.max_display_slots = owned_plinth_count

	# Connect to inventory changes
	inventory_manager.inventory_changed.connect(_update_display)

	# Initial update
	_update_display()

## Get cost to purchase next plinth
func get_next_plinth_cost() -> int:
	return BASE_PLINTH_COST + (owned_plinth_count * PLINTH_COST_INCREMENT)

## Get maximum possible plinths
func get_max_plinths() -> int:
	return display_plinths.size()

## Check if can purchase more plinths
func can_purchase_plinth() -> bool:
	return owned_plinth_count < get_max_plinths()

## Purchase a new display plinth
func purchase_plinth() -> bool:
	if not can_purchase_plinth():
		print("[DisplayManager] Already at max plinths!")
		return false

	var cost = get_next_plinth_cost()
	if not currency_manager.can_afford(cost):
		print("[DisplayManager] Cannot afford plinth! Need %d KP" % cost)
		return false

	if currency_manager.spend_kp(cost):
		# Reveal the next hidden plinth
		if owned_plinth_count < display_plinths.size():
			display_plinths[owned_plinth_count].visible = true
			_set_plinth_collision_enabled(display_plinths[owned_plinth_count], true)

		owned_plinth_count += 1
		inventory_manager.max_display_slots = owned_plinth_count
		plinths_changed.emit()
		print("[DisplayManager] Purchased plinth #%d for %d KP" % [owned_plinth_count, cost])
		return true

	return false

func _update_display() -> void:
	var displayed_souls = inventory_manager.get_display_souls()
	print("[DisplayManager] Updating display with %d souls" % displayed_souls.size())

	# Remove all existing soul visuals
	for soul_visual in soul_visuals:
		soul_visual.queue_free()
	soul_visuals.clear()

	# Clear all plinths first
	for plinth in display_plinths:
		plinth.displayed_soul = null

	# Only the visible/owned plinths are available for display
	var available_plinths = []
	for i in range(min(owned_plinth_count, display_plinths.size())):
		available_plinths.append(display_plinths[i])

	# Remove souls that are no longer displayed from assignments
	var current_soul_ids = displayed_souls.map(func(soul): return soul.id)
	var old_assignments = soul_plinth_assignments.keys()
	for soul_id in old_assignments:
		if soul_id not in current_soul_ids:
			print("[DisplayManager] Removing stale plinth assignment for soul: %s" % soul_id)
			soul_plinth_assignments.erase(soul_id)

	# Track which plinths are already used by existing souls
	var used_plinths: Array = []
	for soul_id in soul_plinth_assignments.keys():
		var assigned_plinth = soul_plinth_assignments[soul_id]
		# Validate: plinth must exist, be visible, and be in available plinths
		if assigned_plinth == null:
			print("[DisplayManager] WARNING: Null plinth for soul %s, removing assignment" % soul_id)
			soul_plinth_assignments.erase(soul_id)
			continue
		if not assigned_plinth.visible:
			print("[DisplayManager] WARNING: Plinth for soul %s is hidden, removing assignment" % soul_id)
			soul_plinth_assignments.erase(soul_id)
			continue
		if assigned_plinth not in available_plinths:
			print("[DisplayManager] WARNING: Plinth for soul %s is not in available list, removing assignment" % soul_id)
			soul_plinth_assignments.erase(soul_id)
			continue
		used_plinths.append(assigned_plinth)

	# Create new soul visuals for displayed souls
	for soul_data in displayed_souls:
		var plinth: Node3D

		# If this soul already has a plinth assignment AND it's still available, use it
		if soul_plinth_assignments.has(soul_data.id) and soul_plinth_assignments[soul_data.id] in available_plinths:
			plinth = soul_plinth_assignments[soul_data.id]
			print("[DisplayManager] Soul '%s' reusing plinth" % soul_data.name)
		else:
			# Find a random unused plinth
			var unused_plinths = available_plinths.filter(func(p): return p not in used_plinths)
			print("[DisplayManager] Finding plinth for '%s': %d unused plinths available" % [soul_data.name, unused_plinths.size()])
			if unused_plinths.size() == 0:
				print("[DisplayManager] ERROR: No plinths for soul '%s'" % soul_data.name)
				break  # No more plinths available

			unused_plinths.shuffle()
			plinth = unused_plinths[0]
			soul_plinth_assignments[soul_data.id] = plinth
			used_plinths.append(plinth)
			print("[DisplayManager] Soul '%s' assigned new plinth" % soul_data.name)

		# Safety check: ensure plinth is still in tree
		if not is_instance_valid(plinth) or not plinth.is_inside_tree():
			print("[DisplayManager] ERROR: Plinth invalid for soul '%s'" % soul_data.name)
			continue

		print("[DisplayManager] Creating visual for soul '%s'" % soul_data.name)

		var soul_instance = soul_scene.instantiate()

		# Add soul as child of plinth (so clicking soul can find plinth parent)
		plinth.add_child(soul_instance)

		# Set position relative to plinth
		soul_instance.position = plinth.soul_offset
		soul_instance.soul_color = soul_data.visual_color

		# Store soul data on plinth so customers can check it
		plinth.displayed_soul = soul_data

		soul_visuals.append(soul_instance)

## Get plinths that have souls displayed (for customers to browse)
func get_browsable_plinths() -> Array:
	var browsable: Array = []

	for plinth in display_plinths:
		if plinth.displayed_soul != null:
			browsable.append(plinth)

	return browsable

## Enable or disable collision for a plinth
func _set_plinth_collision_enabled(plinth: Node3D, enabled: bool) -> void:
	# Find the StaticBody3D child and disable its collision
	var static_body = plinth.get_node_or_null("StaticBody3D")
	if static_body:
		static_body.set_collision_layer_value(1, enabled)
		static_body.set_collision_mask_value(1, enabled)
