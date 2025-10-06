extends Control

signal next_pressed
signal close_pressed

@onready var title_label: Label = $Panel/VBoxContainer/Title
@onready var message_label: Label = $Panel/VBoxContainer/Message
@onready var next_button: Button = $Panel/VBoxContainer/Buttons/NextButton
@onready var close_button: Button = $Panel/VBoxContainer/Buttons/CloseButton

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	close_button.pressed.connect(_on_close_pressed)

func setup(title: String, message: String, show_next: bool = true) -> void:
	title_label.text = title
	message_label.text = message
	next_button.visible = show_next
	close_button.visible = not show_next

func _on_next_pressed() -> void:
	next_pressed.emit()

func _on_close_pressed() -> void:
	close_pressed.emit()
