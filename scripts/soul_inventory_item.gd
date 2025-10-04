extends HBoxContainer

## Individual soul item in the inventory list

signal toggle_display_requested(soul_id: String, is_currently_displayed: bool)

var soul_data: SoulData
var is_on_display: bool = false

@onready var name_label: Label = $NameLabel
@onready var era_label: Label = $EraLabel
@onready var display_button: Button = $DisplayButton

func setup(soul: SoulData, on_display: bool) -> void:
	soul_data = soul
	is_on_display = on_display

	name_label.text = soul.name
	era_label.text = str("%s", soul.era)

	_update_button_text()

	if not display_button.pressed.is_connected(_on_button_pressed):
		display_button.pressed.connect(_on_button_pressed)

func _update_button_text() -> void:
	if is_on_display:
		display_button.text = "Remove from Sale"
	else:
		display_button.text = "Put for Sale"

func _on_button_pressed() -> void:
	toggle_display_requested.emit(soul_data.id, is_on_display)
