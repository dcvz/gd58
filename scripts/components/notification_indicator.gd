extends Node3D

## Floating notification badge above checkout desk
## Uses Sprite3D for clean billboard rendering

signal clicked()

var sprite: Sprite3D
var count_texture: ImageTexture
var pending_count: int = 0
var urgency_level: int = 0

# Badge colors (vibrant like iOS)
const COLOR_BADGE_NORMAL = Color(0.2, 0.5, 1.0)    # Blue
const COLOR_BADGE_WARNING = Color(1.0, 0.6, 0.0)   # Orange
const COLOR_BADGE_URGENT = Color(1.0, 0.2, 0.3)    # Red

func _ready() -> void:
	_create_badge()
	update_display(0, 0)

func _create_badge() -> void:
	# Create sprite for badge
	sprite = Sprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = true
	sprite.pixel_size = 0.002  # Smaller size
	sprite.modulate = COLOR_BADGE_NORMAL
	add_child(sprite)

	# Create label overlay for the number
	var label = Label3D.new()
	label.name = "CountLabel"
	label.position = Vector3(0, 0, -0.01)  # Slightly in front
	label.pixel_size = 0.002
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.outline_size = 0
	label.font_size = 48
	label.modulate = Color(0, 0, 0, 1)  # Black text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)

	# Create initial texture (after label exists)
	_update_badge_texture(0)

	# Add collision for clicking
	var body = StaticBody3D.new()
	add_child(body)

	var collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.3  # Smaller collision
	collision.shape = sphere_shape
	body.add_child(collision)

func _update_badge_texture(count: int) -> void:
	# Create a simple circular badge
	var size = 256
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # Transparent background

	# Draw circle
	var center = size / 2.0
	var radius = size / 2.0 - 4

	for y in range(size):
		for x in range(size):
			var dx = x - center
			var dy = y - center
			var distance = sqrt(dx * dx + dy * dy)

			if distance < radius:
				# Solid interior
				image.set_pixel(x, y, Color(1, 1, 1, 1))
			elif distance < radius + 4:
				# Anti-aliased edge
				var alpha = 1.0 - (distance - radius) / 4.0
				image.set_pixel(x, y, Color(1, 1, 1, alpha))

	count_texture = ImageTexture.create_from_image(image)
	sprite.texture = count_texture

	# Update label text
	var label = get_node("CountLabel")
	label.text = str(count) if count > 0 else ""

func update_display(count: int, urgency: int) -> void:
	pending_count = count
	urgency_level = urgency

	# Show/hide based on count
	if count > 0:
		visible = true
		_update_badge_texture(count)

		# Start subtle pulse animation
		if not has_node("PulseTween"):
			_start_pulse_animation()
	else:
		visible = false

		# Stop pulsing
		if has_node("PulseTween"):
			get_node("PulseTween").queue_free()

	# Update color based on urgency
	var badge_color: Color
	match urgency:
		0:
			badge_color = COLOR_BADGE_NORMAL
		1:
			badge_color = COLOR_BADGE_WARNING
		2:
			badge_color = COLOR_BADGE_URGENT
		_:
			badge_color = COLOR_BADGE_NORMAL

	sprite.modulate = badge_color

func _start_pulse_animation() -> void:
	var tween = create_tween()
	tween.set_loops()  # Infinite loops

	# Store original position
	var original_y = position.y

	# Gentle floating animation
	tween.tween_property(self, "position:y", original_y + 0.15, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", original_y, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func on_click() -> void:
	# Emit click signal (will be connected to open interactions menu)
	clicked.emit()
	print("[NotificationIndicator] Clicked - opening interactions menu")
