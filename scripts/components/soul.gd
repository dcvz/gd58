@tool
extends Node3D

# Soul properties
@export var soul_color: Color = Color(0.5, 0.8, 1.0, 1.0):
	set(value):
		soul_color = value
		update_gradient()

@export_group("Gradient Settings")
@export var gradient_mode: GradientMode = GradientMode.FADE_TO_TRANSPARENT:
	set(value):
		gradient_mode = value
		update_gradient()
@export_range(0.0, 1.0) var gradient_brightness: float = 1.0:
	set(value):
		gradient_brightness = value
		update_gradient()
@export var add_hot_core: bool = true:
	set(value):
		add_hot_core = value
		update_gradient()

@export_group("Emission")
@export var emission_intensity: float = 3.0:
	set(value):
		emission_intensity = value
		update_shader_parameters()
@export var time_scale: float = 2.0:
	set(value):
		time_scale = value
		update_shader_parameters()

enum GradientMode {
	FADE_TO_TRANSPARENT,     # Color to transparent
	FADE_TO_DARK,           # Color to dark color
	BRIGHT_TO_COLOR,        # Bright white/color to soul color
	MULTI_TONE              # Multi-color gradient (hot core effect)
}

# Soul data (for future expansion)
var soul_stats: Dictionary = {}
var soul_era: String = ""

@onready var particles: GPUParticles3D = $GPUParticles3D

func _ready() -> void:
	# Duplicate the material so each soul has its own
	if particles and particles.material_override:
		var material = particles.material_override as ShaderMaterial
		particles.material_override = material.duplicate()

	# Duplicate the particle process material to create unique gradient
	if particles and particles.process_material:
		var process_mat = particles.process_material as ParticleProcessMaterial
		particles.process_material = process_mat.duplicate()

	# Add a clickable collision area for easier interaction
	_create_click_area()

	# Add to clickable_soul group for click detection
	add_to_group("clickable_soul")

	# Force update everything
	call_deferred("_update_all")

func _create_click_area() -> void:
	# Create a StaticBody3D with a collision shape for clicking
	var body = StaticBody3D.new()
	add_child(body)

	var collision = CollisionShape3D.new()
	collision.position = Vector3(0, 0.3, 0)  # Offset upward to cover flame area
	var shape = SphereShape3D.new()
	shape.radius = 0.6  # Larger click area around the soul
	collision.shape = shape
	body.add_child(collision)

func _update_all() -> void:
	update_shader_parameters()
	update_gradient()

func update_shader_parameters() -> void:
	if particles and particles.material_override:
		var material = particles.material_override as ShaderMaterial
		material.set_shader_parameter("emission_intensity", emission_intensity)
		material.set_shader_parameter("time_scale", time_scale)

func update_gradient() -> void:
	if not particles or not particles.process_material:
		return

	var process_mat = particles.process_material as ParticleProcessMaterial

	# Create new gradient based on mode
	var new_gradient = Gradient.new()

	match gradient_mode:
		GradientMode.FADE_TO_TRANSPARENT:
			if add_hot_core:
				# Hot bright core, to saturated color, to darker color fading
				new_gradient.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
				var bright_core = soul_color.lightened(0.3)
				bright_core.r = min(bright_core.r * gradient_brightness * 2.0, 1.0)
				bright_core.g = min(bright_core.g * gradient_brightness * 2.0, 1.0)
				bright_core.b = min(bright_core.b * gradient_brightness * 2.0, 1.0)
				var mid_color = soul_color * gradient_brightness
				new_gradient.colors = PackedColorArray([
					bright_core,
					mid_color,
					Color(soul_color.r * 0.3, soul_color.g * 0.3, soul_color.b * 0.3, 0.0)
				])
			else:
				# Simple fade from color to transparent
				new_gradient.offsets = PackedFloat32Array([0.0, 1.0])
				new_gradient.colors = PackedColorArray([
					soul_color * gradient_brightness,
					Color(soul_color.r * 0.3, soul_color.g * 0.3, soul_color.b * 0.3, 0.0)
				])

		GradientMode.FADE_TO_DARK:
			var dark_color = soul_color.darkened(0.7)
			if add_hot_core:
				new_gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
				new_gradient.colors = PackedColorArray([
					soul_color.lightened(0.3) * gradient_brightness,
					soul_color * gradient_brightness,
					dark_color
				])
			else:
				new_gradient.offsets = PackedFloat32Array([0.0, 1.0])
				new_gradient.colors = PackedColorArray([
					soul_color * gradient_brightness,
					dark_color
				])

		GradientMode.BRIGHT_TO_COLOR:
			if add_hot_core:
				new_gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
				new_gradient.colors = PackedColorArray([
					Color.WHITE * gradient_brightness,
					soul_color.lightened(0.2) * gradient_brightness,
					soul_color
				])
			else:
				new_gradient.offsets = PackedFloat32Array([0.0, 1.0])
				new_gradient.colors = PackedColorArray([
					Color.WHITE * gradient_brightness,
					soul_color
				])

		GradientMode.MULTI_TONE:
			# Create a more complex fire-like gradient
			new_gradient.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
			var bright = Color.WHITE
			var hot = soul_color.lightened(0.5)
			var mid = soul_color
			var dark = soul_color.darkened(0.4)
			new_gradient.colors = PackedColorArray([
				bright * gradient_brightness,
				hot * gradient_brightness,
				mid * gradient_brightness,
				dark,
				Color(soul_color.r, soul_color.g, soul_color.b, 0.0)
			])

	# Create and assign new gradient texture
	var new_gradient_tex = GradientTexture1D.new()
	new_gradient_tex.gradient = new_gradient
	new_gradient_tex.width = 128
	process_mat.color_ramp = new_gradient_tex

	# Restart particles to apply new gradient
	if particles:
		particles.restart()

func set_soul_color(color: Color) -> void:
	soul_color = color
	update_gradient()

func set_emission_intensity(intensity: float) -> void:
	emission_intensity = intensity
	update_shader_parameters()

func set_time_scale(speed: float) -> void:
	time_scale = speed
	update_shader_parameters()

# Future: Add soul-specific data
func set_soul_data(stats: Dictionary, era: String) -> void:
	soul_stats = stats
	soul_era = era
