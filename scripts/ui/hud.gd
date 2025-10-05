extends Control

@onready var day_counter: Label = $BottomLeft/DayCounter
@onready var time_label: Label = $BottomLeft/TimeLabel
@onready var kp_label: Label = $BottomLeft/KPLabel
@onready var menu_button: Button = $TopRight/MenuButton
@onready var game_loop_manager: Node = get_node("/root/Root/Gameplay/GameLoopManager")
@onready var currency_manager: Node = get_node("/root/Root/Gameplay/CurrencyManager")
@onready var interaction_menu: Control = get_node("/root/Root/UI/InteractionMenu")
@onready var shade_interactions_menu: Control = get_node("/root/Root/UI/ShadeInteractionsMenu")
@onready var end_of_day_menu: Control = get_node("/root/Root/UI/EndOfDayMenu")

func _ready() -> void:
	# Connect to game loop signals
	game_loop_manager.day_started.connect(_on_day_started)
	game_loop_manager.day_ended.connect(_on_day_ended)

	# Connect menu buttons
	menu_button.pressed.connect(_on_menu_button_pressed)

	# Connect to currency manager
	currency_manager.currency_changed.connect(_update_kp_display)

	_update_kp_display(currency_manager.get_kp())

func _process(_delta: float) -> void:
	# Update time display
	if game_loop_manager.is_day_active:
		var elapsed = int(game_loop_manager.day_time_elapsed)
		var total = int(game_loop_manager.day_duration)
		time_label.text = "%d/%d" % [elapsed, total]

func _input(event: InputEvent) -> void:
	# Toggle menu with ESC key
	if event.is_action_pressed("ui_cancel"):
		if interaction_menu.visible:
			interaction_menu.close_menu()
			get_viewport().set_input_as_handled()
		elif not shade_interactions_menu.visible and not end_of_day_menu.visible:
			_on_menu_button_pressed()
			get_viewport().set_input_as_handled()

func _on_day_started(day_number: int) -> void:
	day_counter.text = "Day %d" % day_number

func _on_day_ended(day_number: int) -> void:
	time_label.text = "Day Complete"
	end_of_day_menu.show_menu(day_number)

func _on_menu_button_pressed() -> void:
	interaction_menu.open_menu()

func _update_kp_display(amount: int) -> void:
	kp_label.text = "%d KP" % amount
