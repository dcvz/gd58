extends Node

## Manages the visual display of souls on plinths
##
## Display slots are unlocked based on progression (shop upgrades/fame level).
## Place plinths in the scene - they'll be locked until unlocked_slot_count increases.

var inventory_manager: Node
var game_loop_manager: Node
var soul_scene: PackedScene = preload("res://scenes/soul.tscn")
var soul_visuals: Array[Node3D] = []
var objects_node: Node
var display_plinths: Array = []
var soul_plinth_assignments: Dictionary = {}  # Maps soul_id -> plinth

## Number of display slots currently unlocked (can be increased via progression)
@export var unlocked_slot_count: int = 10

func _ready() -> void:
	# Wait for scene to be fully loaded
	await get_tree().process_frame

	# Get references
	inventory_manager = get_node("/root/Root/Gameplay/InventoryManager")
	game_loop_manager = get_node("/root/Root/Gameplay/GameLoopManager")
	var world = get_node("/root/Root/World")
	objects_node = world.get_node("Objects")

	# Find all display plinths in the scene
	display_plinths = get_tree().get_nodes_in_group("display_plinth")
	print("Found %d display plinths, %d unlocked" % [display_plinths.size(), unlocked_slot_count])

	# Sync max display slots with unlocked count
	inventory_manager.max_display_slots = unlocked_slot_count

	# Connect to inventory and game loop changes
	inventory_manager.inventory_changed.connect(_update_display)
	game_loop_manager.day_ended.connect(_on_day_ended)

	# Initial update
	_update_display()

## Called at end of day - can unlock more slots based on progression
func _on_day_ended(_day_number: int) -> void:
	# TODO: Check progression/fame and increase unlocked_slot_count
	# Example: if fame_level >= 5: unlocked_slot_count = 4
	pass

## Manually set the number of unlocked slots (for testing or progression systems)
func set_unlocked_slots(count: int) -> void:
	unlocked_slot_count = mini(count, display_plinths.size())
	inventory_manager.max_display_slots = unlocked_slot_count
	print("Unlocked %d display slots" % unlocked_slot_count)
	_update_display()

func _update_display() -> void:
	var displayed_souls = inventory_manager.get_display_souls()

	# Remove all existing soul visuals
	for soul_visual in soul_visuals:
		soul_visual.queue_free()
	soul_visuals.clear()

	# Clear all plinths first
	for plinth in display_plinths:
		plinth.displayed_soul = null

	# Get available plinths
	var available_slots = mini(unlocked_slot_count, display_plinths.size())
	var available_plinths = display_plinths.slice(0, available_slots).duplicate()

	# Remove souls that are no longer displayed from assignments
	var current_soul_ids = displayed_souls.map(func(soul): return soul.id)
	var old_assignments = soul_plinth_assignments.keys()
	for soul_id in old_assignments:
		if soul_id not in current_soul_ids:
			soul_plinth_assignments.erase(soul_id)

	# Track which plinths are already used by existing souls
	var used_plinths: Array = []
	for soul_id in soul_plinth_assignments.keys():
		used_plinths.append(soul_plinth_assignments[soul_id])

	# Create new soul visuals for displayed souls
	for soul_data in displayed_souls:
		var plinth: Node3D

		# If this soul already has a plinth assignment, use it
		if soul_plinth_assignments.has(soul_data.id):
			plinth = soul_plinth_assignments[soul_data.id]
		else:
			# Find a random unused plinth
			var unused_plinths = available_plinths.filter(func(p): return p not in used_plinths)
			if unused_plinths.size() == 0:
				break  # No more plinths available

			unused_plinths.shuffle()
			plinth = unused_plinths[0]
			soul_plinth_assignments[soul_data.id] = plinth
			used_plinths.append(plinth)

		# Safety check: ensure plinth is still in tree
		if not is_instance_valid(plinth) or not plinth.is_inside_tree():
			continue

		var soul_instance = soul_scene.instantiate()

		# Add to scene first
		objects_node.add_child(soul_instance)

		# Set position and properties using plinth's position
		soul_instance.global_position = plinth.get_soul_position()
		soul_instance.soul_color = soul_data.visual_color

		# Store soul data on plinth so customers can check it
		plinth.displayed_soul = soul_data

		soul_visuals.append(soul_instance)

## Get plinths that are unlocked and have souls displayed (for customers to browse)
func get_browsable_plinths() -> Array:
	var browsable: Array = []
	var available_slots = mini(unlocked_slot_count, display_plinths.size())

	for i in range(available_slots):
		var plinth = display_plinths[i]
		if plinth.displayed_soul != null:
			browsable.append(plinth)

	return browsable
