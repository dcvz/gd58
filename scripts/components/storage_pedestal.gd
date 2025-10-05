extends Node3D

## Represents a single storage pedestal that can hold one soul

signal pedestal_clicked(pedestal: Node3D)

@export var pedestal_index: int = 0  # Position in storage grid (0-11)

var stored_soul_data: SoulData = null
var soul_visual: Node3D = null
var name_label: Label3D = null

func _ready() -> void:
	_create_name_label()

func _create_name_label() -> void:
	# Create floating label above pedestal
	name_label = Label3D.new()
	name_label.position = Vector3(0, 1.5, 0)
	name_label.pixel_size = 0.005
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test = true
	name_label.modulate = Color(0.8, 0.8, 0.8, 0.0)  # Start invisible
	name_label.outline_size = 8
	name_label.outline_modulate = Color(0, 0, 0, 0.8)
	add_child(name_label)

func set_soul(soul: SoulData) -> void:
	"""Place a soul on this pedestal"""
	stored_soul_data = soul

	if soul:
		_create_soul_visual()
		name_label.text = soul.name
		name_label.modulate.a = 1.0  # Make visible
	else:
		_clear_soul_visual()
		name_label.text = ""
		name_label.modulate.a = 0.0  # Hide

func get_soul() -> SoulData:
	"""Get the soul stored on this pedestal"""
	return stored_soul_data

func is_empty() -> bool:
	"""Check if pedestal has no soul"""
	return stored_soul_data == null

func clear_soul() -> void:
	"""Remove soul from pedestal"""
	set_soul(null)

func _create_soul_visual() -> void:
	"""Create visual representation of soul on pedestal"""
	if soul_visual:
		soul_visual.queue_free()

	# Container for soul visual with collision
	var soul_container = Node3D.new()
	soul_container.position = Vector3(0, 0.5, 0)
	soul_visual = soul_container
	add_child(soul_visual)

	# Simple glowing sphere
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	mesh_instance.mesh = sphere

	# Glowing material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.8, 1.0)  # Light blue glow
	material.emission_enabled = true
	material.emission = Color(0.4, 0.6, 0.9)
	material.emission_energy_multiplier = 2.0
	mesh_instance.material_override = material

	soul_container.add_child(mesh_instance)

	# Add StaticBody3D with larger collision for easier clicking
	var body = StaticBody3D.new()
	soul_container.add_child(body)

	var collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.4  # Slightly larger than visual for easier clicking
	collision.shape = sphere_shape
	body.add_child(collision)

	# Add gentle floating animation to the container
	var tween = create_tween()
	tween.set_loops(0)  # 0 = infinite loops
	tween.tween_property(soul_visual, "position:y", 0.6, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(soul_visual, "position:y", 0.5, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _clear_soul_visual() -> void:
	"""Remove soul visual from pedestal"""
	if soul_visual:
		soul_visual.queue_free()
		soul_visual = null

## Called when clicked (will be hooked up by click detection system)
func on_click() -> void:
	pedestal_clicked.emit(self)
