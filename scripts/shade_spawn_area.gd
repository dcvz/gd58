extends Node3D

## Defines an area where shades can spawn

## Size of the spawn area
@export var area_size: Vector2 = Vector2(2.0, 2.0)

## Get a random position within the spawn area
func get_random_spawn_position() -> Vector3:
	var random_x = randf_range(-area_size.x / 2.0, area_size.x / 2.0)
	var random_z = randf_range(-area_size.y / 2.0, area_size.y / 2.0)
	# Convert local offset to world space (handles rotation)
	var local_offset = Vector3(random_x, 0, random_z)
	var world_offset = global_transform.basis * local_offset
	return Vector3(global_position.x + world_offset.x, 0, global_position.z + world_offset.z)
