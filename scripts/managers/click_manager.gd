extends Node

## Handles 3D object clicking via raycasting from camera

signal soul_clicked(soul: SoulData, world_position: Vector3)
signal plinth_clicked(plinth: Node3D)

@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var storage_manager: Node = get_node("/root/Root/Gameplay/StorageManager")

func _input(event: InputEvent) -> void:
	# Only handle left-click
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)

func _handle_click(screen_position: Vector2) -> void:
	if not camera:
		return

	# Create ray from camera through mouse position
	var from = camera.project_ray_origin(screen_position)
	var to = from + camera.project_ray_normal(screen_position) * 1000

	# Raycast into 3D world
	var space_state = camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)

	if result:
		_process_hit(result)

func _process_hit(result: Dictionary) -> void:
	var collider = result.collider

	# Walk up the tree to find clickable objects
	var node = collider
	while node:
		# Check if this node is a notification indicator
		if node.is_in_group("notification_bell"):
			node.on_click()
			print("[ClickManager] Clicked notification indicator")
			return

		# Check if this is a clickable soul visual (on display)
		if node.is_in_group("clickable_soul"):
			# Walk up to find the plinth parent
			var parent = node.get_parent()
			while parent:
				if parent.is_in_group("display_plinth"):
					var soul = parent.get_soul_data()
					if soul:
						soul_clicked.emit(soul, result.position)
						print("[ClickManager] Clicked displayed soul visual: %s" % soul.name)
					return
				parent = parent.get_parent()
			return

		# Check if this node is a storage pedestal
		if node.is_in_group("storage_pedestal"):
			var soul = node.get_soul()
			if soul:
				soul_clicked.emit(soul, result.position)
				print("[ClickManager] Clicked soul: %s" % soul.name)
			return

		# Move up to parent
		node = node.get_parent()
