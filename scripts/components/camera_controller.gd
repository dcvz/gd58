extends Camera3D

## Orbital camera controller for shop view
## Click-drag to rotate, scroll to zoom

@export var orbit_center: Vector3 = Vector3(0, 0, 0)  # Point to orbit around
@export var min_distance: float = 8.0
@export var max_distance: float = 20.0
@export var rotation_speed: float = 0.005
@export var zoom_speed: float = 1.0

var is_rotating: bool = false
var last_mouse_position: Vector2
var current_distance: float = 12.0
var horizontal_angle: float = 0.785  # ~45 degrees
var vertical_angle: float = 0.785    # ~45 degrees

func _ready() -> void:
	_update_camera_position()

func _input(event: InputEvent) -> void:
	# Start rotation on middle mouse button or right-click drag
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_rotating = true
				last_mouse_position = event.position
			else:
				is_rotating = false

		# Zoom with scroll wheel
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_distance = max(min_distance, current_distance - zoom_speed)
			_update_camera_position()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_distance = min(max_distance, current_distance + zoom_speed)
			_update_camera_position()

	# Handle rotation drag
	if event is InputEventMouseMotion and is_rotating:
		var delta = event.position - last_mouse_position
		horizontal_angle -= delta.x * rotation_speed
		vertical_angle = clamp(vertical_angle - delta.y * rotation_speed, 0.1, PI / 2 - 0.1)
		last_mouse_position = event.position
		_update_camera_position()

func _update_camera_position() -> void:
	# Calculate position based on spherical coordinates
	var offset = Vector3(
		current_distance * sin(vertical_angle) * cos(horizontal_angle),
		current_distance * cos(vertical_angle),
		current_distance * sin(vertical_angle) * sin(horizontal_angle)
	)

	position = orbit_center + offset
	look_at(orbit_center, Vector3.UP)
