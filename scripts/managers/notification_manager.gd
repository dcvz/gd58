extends Node

## Manages the 3D notification indicator above the checkout desk

var notification_indicator: Node3D
var interaction_manager: Node
var shade_interactions_menu: Control

func _ready() -> void:
	await get_tree().process_frame

	# Get references
	notification_indicator = get_node("/root/Root/World/Objects/NotificationIndicator")
	interaction_manager = get_node("/root/Root/Gameplay/InteractionManager")
	shade_interactions_menu = get_node("/root/Root/UI/ShadeInteractionsMenu")

	# Connect signals
	if notification_indicator:
		notification_indicator.clicked.connect(_on_notification_clicked)

	if interaction_manager:
		interaction_manager.interaction_added.connect(_update_indicator)
		interaction_manager.interaction_removed.connect(_update_indicator)
		interaction_manager.interaction_expired.connect(_update_indicator)

	# Initial update
	_update_indicator()

func _on_notification_clicked() -> void:
	if shade_interactions_menu:
		shade_interactions_menu.show_menu()

func _update_indicator(_interaction: Dictionary = {}) -> void:
	if not notification_indicator or not interaction_manager:
		return

	var pending = interaction_manager.get_pending_interactions()
	var count = pending.size()

	# Determine urgency level based on earliest expiring interaction
	var urgency = 0
	var min_days_remaining = 999.0

	for interaction in pending:
		var days_remaining = interaction_manager.get_days_remaining(interaction)
		if days_remaining < min_days_remaining:
			min_days_remaining = days_remaining

	# Set urgency level
	if min_days_remaining < 0.5:
		urgency = 2  # Urgent (red)
	elif min_days_remaining < 1.0:
		urgency = 1  # Warning (yellow)
	else:
		urgency = 0  # Normal (blue)

	notification_indicator.update_display(count, urgency)
