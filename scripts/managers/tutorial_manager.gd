extends Node

var tutorial_popup: Control
var current_step: int = 0
var tutorial_steps: Array = []

func _ready() -> void:
	# Define tutorial steps
	tutorial_steps = [
		{
			"title": "Welcome to Soul Emporium!",
			"message": "You run a shop that buys, analyzes, and sells souls to mysterious buyers.\n\nYour goal: Discover what makes each soul unique and match them with the right buyers to earn Karmic Points (KP)!"
		},
		{
			"title": "How to Play",
			"message": "1. ANALYZE souls using machines to discover their traits\n2. DISPLAY souls on plinths in your showroom\n3. SELL to buyers who want specific traits\n4. EARN KP to buy better machines and more souls!"
		},
		{
			"title": "Getting Started",
			"message": "You have 3 starter souls in storage and a Basic Analyzer machine.\n\nTry clicking on a soul in the storage room and select 'Analyze' to learn more about it. Good luck!"
		}
	]

func start_tutorial(popup: Control) -> void:
	tutorial_popup = popup
	current_step = 0
	_show_current_step()

func _show_current_step() -> void:
	if current_step >= tutorial_steps.size():
		_finish_tutorial()
		return

	var step = tutorial_steps[current_step]
	var is_last_step = current_step == tutorial_steps.size() - 1

	tutorial_popup.setup(step["title"], step["message"], not is_last_step)
	tutorial_popup.visible = true

	# Connect signals
	if tutorial_popup.next_pressed.is_connected(_on_next_pressed):
		tutorial_popup.next_pressed.disconnect(_on_next_pressed)
	if tutorial_popup.close_pressed.is_connected(_on_close_pressed):
		tutorial_popup.close_pressed.disconnect(_on_close_pressed)

	tutorial_popup.next_pressed.connect(_on_next_pressed)
	tutorial_popup.close_pressed.connect(_on_close_pressed)

func _on_next_pressed() -> void:
	current_step += 1
	_show_current_step()

func _on_close_pressed() -> void:
	_finish_tutorial()

func _finish_tutorial() -> void:
	tutorial_popup.visible = false
	# Save that tutorial has been completed
	var save_data = {
		"tutorial_completed": true
	}
	var save_file = FileAccess.open("user://tutorial_save.dat", FileAccess.WRITE)
	if save_file:
		save_file.store_var(save_data)
		save_file.close()
	print("[Tutorial] Tutorial completed and saved")

func has_completed_tutorial() -> bool:
	if not FileAccess.file_exists("user://tutorial_save.dat"):
		return false

	var save_file = FileAccess.open("user://tutorial_save.dat", FileAccess.READ)
	if save_file:
		var save_data = save_file.get_var()
		save_file.close()
		return save_data.get("tutorial_completed", false)

	return false
