class_name MachineUIHelper
extends RefCounted

## Centralized helper for machine UI components
## Prevents duplication of job status and machine selection UI

## Add job status label to a container if a job is active for this soul
## Returns true if a job was shown
static func add_job_status_if_active(container: Node, soul_id: String) -> bool:
	var machine_manager = _get_machine_manager()
	if not machine_manager:
		return false

	var active_job = machine_manager.get_soul_job(soul_id)
	if not active_job:
		return false

	var job_status_hbox = HBoxContainer.new()
	container.add_child(job_status_hbox)

	var status_label = Label.new()
	var remaining = active_job.get_remaining_time(Time.get_ticks_msec() / 1000.0)
	status_label.text = "⏱ %s: %.1fs remaining" % [MachineData.get_machine_name(active_job.machine_type), remaining]
	status_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	job_status_hbox.add_child(status_label)

	return true

## Show machine selection popup menu for a soul
## parent: Node to add the popup to
## soul: SoulData to analyze
## on_machine_selected: Optional callback(machine_type: int) when machine is selected
static func show_machine_selection_popup(parent: Node, soul: SoulData, on_machine_selected: Callable = Callable()) -> void:
	var machine_manager = _get_machine_manager()
	if not machine_manager:
		print("[MachineUIHelper] Error: Could not find MachineManager")
		return

	# Check if already being analyzed
	if machine_manager.is_soul_being_analyzed(soul.id):
		print("[MachineUIHelper] Soul is already being analyzed!")
		return

	# Get owned machines
	var owned = machine_manager.get_owned_machines()
	if owned.size() == 0:
		print("[MachineUIHelper] No machines owned!")
		return

	# Create popup menu
	var popup = PopupMenu.new()
	parent.add_child(popup)

	for machine_type in owned:
		popup.add_item(MachineData.get_machine_name(machine_type), machine_type)

	popup.index_pressed.connect(func(index):
		var machine_type = popup.get_item_id(index)
		machine_manager.start_job(soul.id, soul, machine_type)

		# Call optional callback
		if on_machine_selected.is_valid():
			on_machine_selected.call(machine_type)

		popup.queue_free()
	)

	popup.popup_centered()

## Get MachineManager singleton
static func _get_machine_manager() -> Node:
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		return tree.root.get_node_or_null("/root/Root/Gameplay/MachineManager")
	return null
