extends Node

## Manages owned research machines

signal machine_purchased(machine_type: MachineData.MachineType)
signal machines_changed()

var owned_machines: Array[MachineData.MachineType] = []

func _ready() -> void:
	pass

## Check if a machine is owned
func has_machine(type: MachineData.MachineType) -> bool:
	return owned_machines.has(type)

## Purchase a machine
func purchase_machine(type: MachineData.MachineType) -> bool:
	if has_machine(type):
		print("Machine already owned!")
		return false

	var cost = MachineData.get_machine_cost(type)
	var currency_manager = get_node("/root/Root/Gameplay/CurrencyManager")

	if not currency_manager.can_afford(cost):
		print("Cannot afford machine! Need %d KP" % cost)
		return false

	if currency_manager.spend_kp(cost):
		owned_machines.append(type)
		machine_purchased.emit(type)
		machines_changed.emit()
		print("Purchased %s for %d KP" % [MachineData.get_machine_name(type), cost])
		return true

	return false

## Get all owned machines
func get_owned_machines() -> Array[MachineData.MachineType]:
	return owned_machines.duplicate()

## Get all available machines to purchase
func get_available_machines() -> Array[MachineData.MachineType]:
	var available: Array[MachineData.MachineType] = []
	for type in MachineData.MachineType.values():
		if not has_machine(type):
			available.append(type)
	return available
