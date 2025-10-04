extends Node

## Manages the visual display of souls on plinths

var inventory_manager: Node
var soul_visuals: Array[Node3D] = []

func _ready() -> void:
	# Wait for scene to be fully loaded
	await get_tree().process_frame

	# Get references
	inventory_manager = get_node("/root/Root/Gameplay/InventoryManager")

	# Find soul visuals in the world
	var world = get_node("/root/Root/World")
	soul_visuals.append(world.get_node("Objects/Soul1"))
	soul_visuals.append(world.get_node("Objects/Soul2"))
	soul_visuals.append(world.get_node("Objects/Soul3"))

	# Hide all souls initially
	for soul in soul_visuals:
		soul.visible = false

	# Connect to inventory changes
	inventory_manager.inventory_changed.connect(_update_display)

	# Initial update
	_update_display()

func _update_display() -> void:
	var displayed_souls = inventory_manager.get_display_souls()

	# Hide all first
	for soul_visual in soul_visuals:
		soul_visual.visible = false

	# Show souls that are on display
	for i in range(min(displayed_souls.size(), soul_visuals.size())):
		var soul_data = displayed_souls[i]
		var soul_visual = soul_visuals[i]

		soul_visual.visible = true
		soul_visual.soul_color = soul_data.visual_color
