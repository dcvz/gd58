extends Node3D

## Checkout desk where customers queue to purchase souls

## Position offset where customers should stand when waiting
@export var customer_wait_offset: Vector3 = Vector3(1.0, 0, -1.5)

## Get the world position where a customer should wait
func get_customer_position() -> Vector3:
	# Transform offset to world space (handles rotation)
	var world_offset = global_transform.basis * customer_wait_offset
	return global_position + world_offset
