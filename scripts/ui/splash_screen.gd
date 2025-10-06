extends Control

## Splash screen with game title and start button

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	# Go to loading screen which will load the main game
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")
