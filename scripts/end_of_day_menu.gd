extends Control

## End of day summary menu

signal next_day_requested()

@onready var next_day_button: Button = $Panel/VBoxContainer/NextDayButton
@onready var game_loop_manager: Node = get_node("/root/Root/Gameplay/GameLoopManager")

func _ready() -> void:
	visible = false
	next_day_button.pressed.connect(_on_next_day_pressed)

func show_menu(day_number: int) -> void:
	visible = true
	# TODO: Show day summary, earnings, etc.
	print("Day %d complete!" % day_number)

func _on_next_day_pressed() -> void:
	visible = false
	next_day_requested.emit()
	game_loop_manager.start_new_day()
