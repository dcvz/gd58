class_name MachineJob
extends Resource

## Represents an active machine research job

var soul_id: String
var machine_type: MachineData.MachineType
var start_time: float  # Time when job started (in seconds)
var duration: float    # How long job takes (in seconds)
var completed: bool = false
var elapsed_time: float = 0.0  # Accumulated time while unpaused

func _init(p_soul_id: String = "", p_machine_type: MachineData.MachineType = MachineData.MachineType.RANDOM_PROPERTY, p_start_time: float = 0.0, p_duration: float = 0.0) -> void:
	soul_id = p_soul_id
	machine_type = p_machine_type
	start_time = p_start_time
	duration = p_duration

## Update elapsed time (called by MachineManager when unpaused)
func update_elapsed(delta: float) -> void:
	elapsed_time += delta

## Get remaining time in seconds
func get_remaining_time(current_time: float) -> float:
	return max(0.0, duration - elapsed_time)

## Check if job is complete
func is_complete(current_time: float) -> bool:
	return elapsed_time >= duration

## Get progress (0.0 to 1.0)
func get_progress(current_time: float) -> float:
	return clamp(elapsed_time / duration, 0.0, 1.0)
