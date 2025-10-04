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

## Number of display slots currently unlocked (can be increased via progression)
@export var unlocked_slot_count: int = 3

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

	# Only create souls for unlocked slots
	var available_slots = mini(unlocked_slot_count, display_plinths.size())

	# Create new soul visuals for displayed souls
	for i in range(min(displayed_souls.size(), available_slots)):
		var soul_data = displayed_souls[i]
		var plinth = display_plinths[i]
		var soul_instance = soul_scene.instantiate()

		# Set position and properties using plinth's position
		soul_instance.global_position = plinth.get_soul_position()
		soul_instance.soul_color = soul_data.visual_color

		# Store soul data on plinth so customers can check it
		plinth.displayed_soul = soul_data

		# Add to scene
		objects_node.add_child(soul_instance)
		soul_visuals.append(soul_instance)
