extends Control

## End of day summary menu

signal next_day_requested()

@onready var next_day_button: Button = $Panel/VBoxContainer/NextDayButton
@onready var summary_label: Label = $Panel/VBoxContainer/SummaryLabel
@onready var game_loop_manager: Node = get_node("/root/Root/Gameplay/GameLoopManager")
@onready var currency_manager: Node = get_node("/root/Root/Gameplay/CurrencyManager")

func _ready() -> void:
	visible = false
	next_day_button.pressed.connect(_on_next_day_pressed)

func show_menu(day_number: int) -> void:
	visible = true

	# Get daily summary from currency manager
	var summary = currency_manager.get_daily_summary()

	# Build summary text
	var summary_text = "Day %d Results:\n\n" % day_number
	summary_text += "Souls Sold: %d\n" % summary.souls_sold
	summary_text += "Souls Bought: %d\n\n" % summary.souls_bought
	summary_text += "KP Earned: +%d\n" % summary.kp_earned
	summary_text += "KP Spent: -%d\n" % summary.kp_spent
	summary_text += "─────────────\n"

	# Show net profit/loss with color
	var net_kp = summary.net_kp
	if net_kp > 0:
		summary_text += "Net Profit: +%d KP" % net_kp
	elif net_kp < 0:
		summary_text += "Net Loss: %d KP" % net_kp
	else:
		summary_text += "Net: 0 KP"

	summary_label.text = summary_text
	print("Day %d complete! Net: %+d KP" % [day_number, net_kp])

func _on_next_day_pressed() -> void:
	visible = false
	next_day_requested.emit()

	# Reset daily stats before starting new day
	currency_manager.reset_daily_stats()

	game_loop_manager.start_new_day()
