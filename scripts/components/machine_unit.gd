extends Node3D

## Physical 3D representation of a soul analysis machine
## Cute washing machine aesthetic

var machine_type: int = -1
var is_in_use: bool = false
var body_mesh: MeshInstance3D
var window_mesh: MeshInstance3D
var light_mesh: MeshInstance3D
var body_material: StandardMaterial3D
var window_material: StandardMaterial3D
var light_material: StandardMaterial3D
var spin_tween: Tween = null

# Machine colors
const COLOR_IDLE = Color(0.85, 0.85, 0.9)
const COLOR_WORKING = Color(0.6, 0.8, 1.0)
const COLOR_WINDOW = Color(0.3, 0.5, 0.7, 0.6)

func _ready() -> void:
	_create_machine_visual()

func _create_machine_visual() -> void:
	# Main body (rounded box)
	body_mesh = MeshInstance3D.new()
	var body_box = BoxMesh.new()
	body_box.size = Vector3(0.8, 1.0, 0.8)
	body_mesh.mesh = body_box
	body_mesh.position = Vector3(0, 0.5, 0)

	body_material = StandardMaterial3D.new()
	body_material.albedo_color = COLOR_IDLE
	body_material.metallic = 0.3
	body_material.roughness = 0.7
	body_mesh.material_override = body_material
	add_child(body_mesh)

	# Front window (circular glass door)
	window_mesh = MeshInstance3D.new()
	var window_cylinder = CylinderMesh.new()
	window_cylinder.top_radius = 0.28
	window_cylinder.bottom_radius = 0.28
	window_cylinder.height = 0.05
	window_mesh.mesh = window_cylinder
	window_mesh.position = Vector3(0, 0.5, -0.4)
	window_mesh.rotation_degrees = Vector3(90, 0, 0)

	window_material = StandardMaterial3D.new()
	window_material.albedo_color = COLOR_WINDOW
	window_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	window_material.metallic = 0.8
	window_material.roughness = 0.1
	window_mesh.material_override = window_material
	add_child(window_mesh)

	# Status light on top
	light_mesh = MeshInstance3D.new()
	var light_sphere = SphereMesh.new()
	light_sphere.radius = 0.08
	light_sphere.height = 0.16
	light_mesh.mesh = light_sphere
	light_mesh.position = Vector3(0, 1.1, 0)

	light_material = StandardMaterial3D.new()
	light_material.albedo_color = Color(0.3, 0.3, 0.3)
	light_material.emission_enabled = false
	light_mesh.material_override = light_material
	add_child(light_mesh)

	# Add collision
	var body = StaticBody3D.new()
	add_child(body)

	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.8, 1.0, 0.8)
	collision.shape = box_shape
	collision.position = Vector3(0, 0.5, 0)
	body.add_child(collision)

func set_machine_type(type: int) -> void:
	machine_type = type
	# Could customize appearance based on type

func set_in_use(in_use: bool, soul_color: Color = Color.WHITE) -> void:
	is_in_use = in_use

	if in_use:
		# Machine is working - use soul's color
		body_material.albedo_color = soul_color
		light_material.emission_enabled = true
		light_material.emission = soul_color
		light_material.emission_energy_multiplier = 2.0
		light_material.albedo_color = soul_color

		# Start spinning animation
		if spin_tween == null or not spin_tween.is_valid():
			_start_spin_animation()
	else:
		# Machine is idle
		body_material.albedo_color = COLOR_IDLE
		light_material.emission_enabled = false
		light_material.albedo_color = Color(0.3, 0.3, 0.3)

		# Stop spinning
		if spin_tween != null and spin_tween.is_valid():
			spin_tween.kill()
			spin_tween = null
		window_mesh.rotation_degrees = Vector3(90, 0, 0)

func _start_spin_animation() -> void:
	spin_tween = create_tween()
	spin_tween.set_loops()

	# Spin the window
	spin_tween.tween_property(window_mesh, "rotation_degrees:z", 360, 2.0).from(0.0).set_trans(Tween.TRANS_LINEAR)
