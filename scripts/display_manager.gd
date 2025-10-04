extends Node

## Manages the visual display of souls on plinths

var inventory_manager: Node
var soul_scene: PackedScene = preload("res://scenes/soul.tscn")
var soul_visuals: Array[Node3D] = []
var objects_node: Node
var display_plinths: Array = []

func _ready() -> void:
	# Wait for scene to be fully loaded
	await get_tree().process_frame

	# Get references
	inventory_manager = get_node("/root/Root/Gameplay/InventoryManager")
	var world = get_node("/root/Root/World")
	objects_node = world.get_node("Objects")

	# Find all display plinths in the scene
	display_plinths = get_tree().get_nodes_in_group("display_plinth")
	print("Found %d display plinths" % display_plinths.size())

	# Sync max display slots with available plinths
	inventory_manager.max_display_slots = display_plinths.size()

	# Connect to inventory changes
	inventory_manager.inventory_changed.connect(_update_display)

	# Initial update
	_update_display()

func _update_display() -> void:
	var displayed_souls = inventory_manager.get_display_souls()

	# Remove all existing soul visuals
	for soul_visual in soul_visuals:
		soul_visual.queue_free()
	soul_visuals.clear()

	# Create new soul visuals for displayed souls
	for i in range(min(displayed_souls.size(), display_plinths.size())):
		var soul_data = displayed_souls[i]
		var plinth = display_plinths[i]
		var soul_instance = soul_scene.instantiate()

		# Set position and properties using plinth's position
		soul_instance.global_position = plinth.get_soul_position()
		soul_instance.soul_color = soul_data.visual_color

		# Add to scene
		objects_node.add_child(soul_instance)
		soul_visuals.append(soul_instance)
