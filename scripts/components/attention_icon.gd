extends Node3D

## Floating attention icon (!! indicator)

var bob_time: float = 0.0

func _process(delta: float) -> void:
	# Bob up and down
	bob_time += delta * 3.0
	position.y = 2.0 + sin(bob_time) * 0.2
