extends Node

## Manages the visual display of souls on plinths

var inventory_manager: Node
var soul_scene: PackedScene = preload("res://scenes/soul.tscn")
var soul_visuals: Array[Node3D] = []
var objects_node: Node

## Display slot positions - add more as needed
@export var display_positions: Array[Vector3] = [
	Vector3(1.5, 1.5, 2.5),   # Plinth 1
	Vector3(-2.5, 1.5, 2.6),  # Plinth 2
	Vector3(1.5, 1.5, -2.4)   # Plinth 3
]

func _ready() -> void:
	# Wait for scene to be fully loaded
	await get_tree().process_frame

	# Get references
	inventory_manager = get_node("/root/Root/Gameplay/InventoryManager")
	var world = get_node("/root/Root/World")
	objects_node = world.get_node("Objects")

	# Sync max display slots with available positions
	inventory_manager.max_display_slots = display_positions.size()

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
	for i in range(min(displayed_souls.size(), display_positions.size())):
		var soul_data = displayed_souls[i]
		var soul_instance = soul_scene.instantiate()

		# Set position and properties
		soul_instance.position = display_positions[i]
		soul_instance.soul_color = soul_data.visual_color

		# Add to scene
		objects_node.add_child(soul_instance)
		soul_visuals.append(soul_instance)
