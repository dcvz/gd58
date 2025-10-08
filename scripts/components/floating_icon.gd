extends Node3D

@onready var sprite: Sprite3D = $Sprite3D
var bob_time: float = 0.0

func _process(delta: float) -> void:
	# Bob up and down
	bob_time += delta * 3.0
	position.y = 0.0 + sin(bob_time) * 0.2

func get_sprite() -> Sprite3D:
	return sprite
