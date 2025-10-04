extends Control

@onready var day_counter: Label = $BottomLeft/DayCounter
@onready var time_label: Label = $BottomLeft/TimeLabel
@onready var menu_button: Button = $MenuButton
@onready var game_loop_manager: Node = get_node("/root/Root/Gameplay/GameLoopManager")
@onready var interaction_menu: Control = get_node("/root/Root/UI/InteractionMenu")
@onready var end_of_day_menu: Control = get_node("/root/Root/UI/EndOfDayMenu")

func _ready() -> void:
	# Connect to game loop signals
	game_loop_manager.day_started.connect(_on_day_started)
	game_loop_manager.day_ended.connect(_on_day_ended)

	# Connect menu button
	menu_button.pressed.connect(_on_menu_button_pressed)

func _process(_delta: float) -> void:
	# Update time display
	if game_loop_manager.is_day_active:
		var elapsed = int(game_loop_manager.day_time_elapsed)
		var total = int(game_loop_manager.day_duration)
		time_label.text = "%d/%d" % [elapsed, total]

func _on_day_started(day_number: int) -> void:
	day_counter.text = "Day %d" % day_number

func _on_day_ended(day_number: int) -> void:
	time_label.text = "Day Complete"
	end_of_day_menu.show_menu(day_number)

func _on_menu_button_pressed() -> void:
	interaction_menu.open_menu()
