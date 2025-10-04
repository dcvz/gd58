extends Node3D

## Marks a position where souls can be displayed for sale

## Offset from the plinth origin where the soul should appear (centered on 1x1 cube)
@export var soul_offset: Vector3 = Vector3(0.5, 1.5, -0.5)

## Get the world position where a soul should be placed
func get_soul_position() -> Vector3:
	return global_position + soul_offset
