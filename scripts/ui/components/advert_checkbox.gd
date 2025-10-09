extends CheckBox
class_name AdvertCheckBox

## Universal checkbox component for advertisement properties
## Handles both simple properties (era, death) and complex stats (exact/range/presence)
## Artists can style in scene, devs just set data via simple API

signal toggled_with_data(is_checked: bool, user_data: Dictionary)

## Optional user data attached to this checkbox (for complex scenarios)
var user_data: Dictionary = {}

## Simple setup - just text and optional data
func setup(display_text: String, data: Dictionary = {}) -> void:
	text = display_text
	user_data = data

## Set checked state without triggering signals
func set_checked_silent(is_checked: bool) -> void:
	set_pressed_no_signal(is_checked)

func _on_toggled(is_pressed: bool) -> void:
	toggled_with_data.emit(is_pressed, user_data)
