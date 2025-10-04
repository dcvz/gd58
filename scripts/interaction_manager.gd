extends Node

## Manages pending shade interactions (buyers and sellers at checkout)

signal interaction_added(interaction: Dictionary)
signal interaction_removed(interaction: Dictionary)

# Queue of pending interactions
var pending_interactions: Array[Dictionary] = []

func add_interaction(shade_data: Dictionary) -> void:
	"""Add a shade interaction to the queue"""
	var interaction = {
		"type": shade_data.type,
		"timestamp": Time.get_ticks_msec()
	}

	# Add type-specific data
	if shade_data.type == "buyer":
		interaction["interests"] = shade_data.get("interests", [])
		interaction["selected_soul_plinth"] = shade_data.get("selected_soul_plinth", null)
	elif shade_data.type == "seller":
		interaction["soul_to_sell"] = shade_data.get("soul_to_sell", null)

	pending_interactions.append(interaction)
	interaction_added.emit(interaction)
	print("Added %s interaction to queue (total: %d)" % [interaction.type, pending_interactions.size()])

func remove_interaction(index: int) -> void:
	"""Remove an interaction from the queue by index"""
	if index >= 0 and index < pending_interactions.size():
		var interaction = pending_interactions[index]
		pending_interactions.remove_at(index)
		interaction_removed.emit(interaction)
		print("Removed %s interaction from queue" % interaction.type)

func get_pending_interactions() -> Array[Dictionary]:
	"""Get all pending interactions"""
	return pending_interactions

func clear_all_interactions() -> void:
	"""Clear all pending interactions (e.g., at end of day)"""
	pending_interactions.clear()
	print("Cleared all pending interactions")
