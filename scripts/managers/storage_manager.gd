extends Node

## Manages physical storage pedestals and their soul assignments

signal storage_updated()
signal pedestal_clicked(pedestal: Node3D, soul: SoulData)

var storage_pedestals: Array = []  # Array of StoragePedestal nodes
var soul_to_pedestal: Dictionary = {}  # soul_id -> pedestal_index

@onready var inventory_manager: Node = get_node("/root/Root/Gameplay/InventoryManager")

func _ready() -> void:
	await get_tree().process_frame

	# Find all storage pedestals in the world
	_initialize_pedestals()

	# Connect to inventory changes
	if inventory_manager:
		inventory_manager.soul_added.connect(_on_soul_added_to_inventory)
		inventory_manager.soul_removed.connect(_on_soul_removed_from_inventory)
		inventory_manager.inventory_changed.connect(_refresh_storage)
		inventory_manager.inventory_slots_changed.connect(_update_pedestal_visibility)

func _initialize_pedestals() -> void:
	"""Find and register all storage pedestals"""
	var pedestals = get_tree().get_nodes_in_group("storage_pedestal")
	storage_pedestals = pedestals
	storage_pedestals.sort_custom(func(a, b): return a.pedestal_index < b.pedestal_index)

	# Connect click signals
	for pedestal in storage_pedestals:
		if not pedestal.pedestal_clicked.is_connected(_on_pedestal_clicked):
			pedestal.pedestal_clicked.connect(_on_pedestal_clicked)

	print("[StorageManager] Initialized with %d pedestals" % storage_pedestals.size())

	# Update visibility based on current capacity
	_update_pedestal_visibility()

func _on_soul_added_to_inventory(soul: SoulData) -> void:
	"""When soul added to inventory, check if it should be in storage"""
	# Only show in storage if NOT on display
	if inventory_manager.display_slots.has(soul.id):
		# Soul is on display, don't show in storage
		return

	# Skip if soul is already placed
	if soul_to_pedestal.has(soul.id):
		return

	# Find empty pedestal
	var empty_pedestal_index = _find_empty_pedestal()
	if empty_pedestal_index == -1:
		print("[StorageManager] WARNING: No empty pedestals! Storage full.")
		return

	# Place soul on pedestal
	var pedestal = storage_pedestals[empty_pedestal_index]
	pedestal.set_soul(soul)
	soul_to_pedestal[soul.id] = empty_pedestal_index

	print("[StorageManager] Placed soul '%s' on pedestal %d" % [soul.name, empty_pedestal_index])
	storage_updated.emit()

func _on_soul_removed_from_inventory(soul_id: String) -> void:
	"""When soul removed from inventory, clear from pedestal"""
	if not soul_to_pedestal.has(soul_id):
		return

	var pedestal_index = soul_to_pedestal[soul_id]
	var pedestal = storage_pedestals[pedestal_index]
	pedestal.clear_soul()
	soul_to_pedestal.erase(soul_id)

	print("[StorageManager] Removed soul from pedestal %d" % pedestal_index)
	storage_updated.emit()

func _find_empty_pedestal() -> int:
	"""Find first empty pedestal, return -1 if none"""
	for i in range(storage_pedestals.size()):
		if storage_pedestals[i].is_empty():
			return i
	return -1

func get_storage_capacity() -> int:
	"""Get total number of storage pedestals"""
	return storage_pedestals.size()

func get_used_capacity() -> int:
	"""Get number of pedestals with souls"""
	return soul_to_pedestal.size()

func is_storage_full() -> bool:
	"""Check if all pedestals are occupied"""
	return get_used_capacity() >= get_storage_capacity()

func get_pedestal_for_soul(soul_id: String) -> Node3D:
	"""Get the pedestal holding a specific soul"""
	if not soul_to_pedestal.has(soul_id):
		return null
	var pedestal_index = soul_to_pedestal[soul_id]
	return storage_pedestals[pedestal_index]

func _on_pedestal_clicked(pedestal: Node3D) -> void:
	"""Handle pedestal click - emit signal with soul data"""
	var soul = pedestal.get_soul()
	if soul:
		pedestal_clicked.emit(pedestal, soul)
		print("[StorageManager] Pedestal clicked: %s" % soul.name)

func _refresh_storage() -> void:
	"""Rebuild storage display based on current inventory state"""
	# Clear all pedestals
	for pedestal in storage_pedestals:
		pedestal.clear_soul()
	soul_to_pedestal.clear()

	# Get all souls NOT on display
	var storage_souls = inventory_manager.get_storage_souls()

	# Place each storage soul on a pedestal (only on visible pedestals)
	var visible_capacity = inventory_manager.max_souls
	for i in range(min(storage_souls.size(), visible_capacity)):
		var soul = storage_souls[i]
		var pedestal = storage_pedestals[i]
		pedestal.set_soul(soul)
		soul_to_pedestal[soul.id] = i

	print("[StorageManager] Refreshed storage: %d souls" % storage_souls.size())
	storage_updated.emit()

func _update_pedestal_visibility() -> void:
	"""Show/hide pedestals based on purchased capacity"""
	var capacity = inventory_manager.max_souls
	for i in range(storage_pedestals.size()):
		if i < capacity:
			storage_pedestals[i].visible = true
		else:
			storage_pedestals[i].visible = false

	print("[StorageManager] Updated pedestal visibility: %d / %d visible" % [capacity, storage_pedestals.size()])
