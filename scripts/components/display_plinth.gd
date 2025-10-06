extends Node3D

## Marks a position where souls can be displayed for sale

## Offset from the plinth origin where the soul should appear (centered on 1x1 cube)
@export var soul_offset: Vector3 = Vector3(0, 1.5, 0)

## The soul data currently on this plinth (null if empty)
var displayed_soul: SoulData = null

## Get the world position where a soul should be placed
func get_soul_position() -> Vector3:
	return global_position + soul_offset

## Get the soul data displayed on this plinth
func get_soul_data() -> SoulData:
	return displayed_soul
