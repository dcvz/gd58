extends Node

## Manages the player's soul inventory

signal soul_added(soul: SoulData)
signal soul_removed(soul_id: String)
signal inventory_changed()

# Storage for all souls
var souls: Dictionary = {}  # Key: soul_id, Value: SoulData

# Display slots (limited number of souls that can be shown in shop)
@export var max_display_slots: int = 3
var display_slots: Array[String] = []  # Array of soul IDs currently on display

func _ready() -> void:
	print("InventoryManager initialized")
	_create_starting_souls()

## Add a soul to inventory
func add_soul(soul: SoulData) -> void:
	if soul.id.is_empty():
		soul.id = _generate_soul_id()

	souls[soul.id] = soul
	soul_added.emit(soul)
	inventory_changed.emit()
	print("Added soul to inventory: ", soul)

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
	inventory_changed.emit()
	return true

## Remove soul from display slot
func remove_from_display(soul_id: String) -> bool:
	if not display_slots.has(soul_id):
		return false

	display_slots.erase(soul_id)
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
	var starting_color = Color("#212b33")

	for i in range(3):
		var soul = SoulData.new()
		soul.id = "soul_starter_%d" % (i + 1)
		soul.name = "Common Soul %d" % (i + 1)
		soul.era = "Modern"
		soul.tags = ["unidentified"]
		soul.rarity = "common"
		soul.condition = 1.0
		soul.visual_color = starting_color

		add_soul(soul)
		add_to_display(soul.id)

	print("Created 3 starting souls")
