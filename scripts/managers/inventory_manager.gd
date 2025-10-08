extends Node

## Manages the player's soul inventory

signal soul_added(soul: SoulData)
signal soul_removed(soul_id: String)
signal inventory_changed()

# Storage for all souls
var souls: Dictionary = {}  # Key: soul_id, Value: SoulData
@export var max_souls: int = 12  # Total storage capacity (12 pedestals in storage room)

# Display slots (limited number of souls that can be shown in shop)
@export var max_display_slots: int = 10
var display_slots: Array[String] = []  # Array of soul IDs currently on display

func _ready() -> void:
	print("InventoryManager initialized")

## Add a soul to inventory
func add_soul(soul: SoulData) -> bool:
	if soul.id.is_empty():
		soul.id = _generate_soul_id()

	# Check if inventory is full
	if souls.size() >= max_souls:
		print("Cannot add soul - inventory full (%d/%d)" % [souls.size(), max_souls])
		return false

	souls[soul.id] = soul
	soul_added.emit(soul)
	inventory_changed.emit()
	print("Added soul to inventory: ", soul)
	return true

## Remove a soul from inventory
func remove_soul(soul_id: String) -> bool:
	if not souls.has(soul_id):
		return false

	# Remove from display if it's there
	if display_slots.has(soul_id):
		display_slots.erase(soul_id)

	souls.erase(soul_id)
	soul_removed.emit(soul_id)
	inventory_changed.emit()
	print("Removed soul from inventory: ", soul_id)
	return true

## Get a soul by ID
func get_soul(soul_id: String) -> SoulData:
	return souls.get(soul_id, null)

## Alias for get_soul (for compatibility)
func get_soul_by_id(soul_id: String) -> SoulData:
	return get_soul(soul_id)

## Get all souls
func get_all_souls() -> Array[SoulData]:
	var soul_list: Array[SoulData] = []
	for soul in souls.values():
		soul_list.append(soul)
	return soul_list

## Get souls in storage (not on display)
func get_storage_souls() -> Array[SoulData]:
	var storage: Array[SoulData] = []
	for soul_id in souls.keys():
		if not display_slots.has(soul_id):
			storage.append(souls[soul_id])
	return storage

## Add soul to display slot
func add_to_display(soul_id: String) -> bool:
	if not souls.has(soul_id):
		return false

	if display_slots.size() >= max_display_slots:
		print("Display slots full!")
		return false

	if display_slots.has(soul_id):
		print("Soul already on display!")
		return false

	display_slots.append(soul_id)

	# Auto-advertise everything we know about this soul
	var discovery_manager = get_node("/root/Root/Gameplay/DiscoveryManager")
	var advertisement_manager = get_node("/root/Root/Gameplay/AdvertisementManager")
	var soul = souls[soul_id]
	var discovery_log = discovery_manager.get_discovery_log(soul_id)
	advertisement_manager.auto_advertise_all_known(soul_id, soul, discovery_log)

	inventory_changed.emit()
	return true

## Remove soul from display slot
func remove_from_display(soul_id: String) -> bool:
	if not display_slots.has(soul_id):
		return false

	display_slots.erase(soul_id)

	# Clear advertisement when removed from display
	var advertisement_manager = get_node("/root/Root/Gameplay/AdvertisementManager")
	advertisement_manager.clear_advertisement(soul_id)

	inventory_changed.emit()
	return true

## Get souls currently on display
func get_display_souls() -> Array[SoulData]:
	var displayed: Array[SoulData] = []
	for soul_id in display_slots:
		if souls.has(soul_id):
			displayed.append(souls[soul_id])
	return displayed

## Check if display has available slots
func has_available_display_slot() -> bool:
	return display_slots.size() < max_display_slots

## Get inventory count
func get_soul_count() -> int:
	return souls.size()

## Generate a unique soul ID
func _generate_soul_id() -> String:
	return "soul_" + str(Time.get_ticks_msec()) + "_" + str(randi())

## Create starting souls for the player
func _create_starting_souls() -> void:
	for i in range(3):
		var soul = SoulData.generate_random_soul()

		add_soul(soul)
		add_to_display(soul.id)

	print("Created 3 starting souls")
