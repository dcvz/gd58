extends Node3D

## Checkout desk where shades queue to purchase souls

## Position offset where shades should stand when waiting
@export var shade_wait_offset: Vector3 = Vector3(1.0, 0, -1.5)

## Get the world position where a shade should wait
func get_shade_position() -> Vector3:
	# Transform offset to world space (handles rotation)
	var world_offset = global_transform.basis * shade_wait_offset
	return global_position + world_offset
