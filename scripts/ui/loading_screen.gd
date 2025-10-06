extends Control

## Simple loading screen that shows progress and transitions to main game

@onready var loading_label: Label = $CenterContainer/VBoxContainer/LoadingLabel
@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar

var target_scene: String = "res://main.tscn"
var loading_progress: float = 0.0
var is_transitioning: bool = false

func _ready() -> void:
	print("[LoadingScreen] Starting load...")
	_start_loading()

func _start_loading() -> void:
	# Start loading the main scene in background
	ResourceLoader.load_threaded_request(target_scene)
	set_process(true)

func _process(_delta: float) -> void:
	if is_transitioning:
		return

	# Check loading progress
	var progress_array = []
	var status = ResourceLoader.load_threaded_get_status(target_scene, progress_array)

	if progress_array.size() > 0:
		loading_progress = progress_array[0]
		progress_bar.value = loading_progress * 100.0

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			loading_label.text = "Loading... %.0f%%" % (loading_progress * 100.0)

		ResourceLoader.THREAD_LOAD_LOADED:
			loading_label.text = "Complete!"
			progress_bar.value = 100.0
			is_transitioning = true
			_transition_to_game()

		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			loading_label.text = "Error loading game!"
			push_error("[LoadingScreen] Failed to load main scene")
			set_process(false)

func _transition_to_game() -> void:
	print("[LoadingScreen] Transitioning to game...")
	set_process(false)
	var packed_scene = ResourceLoader.load_threaded_get(target_scene)
	if packed_scene:
		get_tree().change_scene_to_packed(packed_scene)
	else:
		push_error("[LoadingScreen] Failed to get loaded scene")
