class_name TownLabel extends Node3D

@export var town_position: Vector3
@export var town_name: String
@export var town_id: int

@onready var node_skin: Node3D = $TownLabelSkin
@onready var node_surface: MeshInstance3D = $TownLabelSkin/Surface
@onready var node_viewport: SubViewport = $SubViewport

@onready var button: Button = $SubViewport/TownLabelUI/Button
@onready var ui_manager = self.find_parent("UIContainer")

# Used for checking if the mouse is inside the Area3D.
var is_mouse_inside = false
# The last processed input touch/mouse event. To calculate relative movement.
var last_event_pos2D = null
# The time of the last event in seconds since engine start.
var last_event_time: float = -1.0

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	# `town_global_pos` is the Vector3 position of the town in world space
	self.find_child("Label", true).text = self.town_name

func _on_button_pressed() -> void:
	print_debug("Clicked a town!")
	ui_manager._on_town_clicked(self.town_id)

func _process(delta):
	rotate_area_to_billboard()
	pass

func _mouse_entered_area():
	print_debug("Mouse entered " + town_name)
	is_mouse_inside = true

func _mouse_exited_area():
	print_debug("Mouse exited " + town_name)
	is_mouse_inside = false

func _mouse_input_event(_camera: Node, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int):
	print_debug("Input event to " + town_name)
	# Get mesh size to detect edges and make conversions. This code only support PlaneMesh and QuadMesh.
	var quad_mesh_size = node_surface.mesh.size

	# Event position in Area3D in world coordinate space.
	var event_pos3D = event_position

	# Current time in seconds since engine start.
	var now: float = Time.get_ticks_msec() / 1000.0

	# Convert position to a coordinate space relative to the Area3D node.
	# NOTE: affine_inverse accounts for the Area3D node's scale, rotation, and position in the scene!
	event_pos3D = node_surface.global_transform.affine_inverse() * event_pos3D

	# TODO: Adapt to bilboard mode or avoid completely.

	var event_pos2D: Vector2 = Vector2()

	if is_mouse_inside:
		# Convert the relative event position from 3D to 2D.
		event_pos2D = Vector2(event_pos3D.x, -event_pos3D.y)

		# Right now the event position's range is the following: (-quad_size/2) -> (quad_size/2)
		# We need to convert it into the following range: -0.5 -> 0.5
		event_pos2D.x = event_pos2D.x / quad_mesh_size.x
		event_pos2D.y = event_pos2D.y / quad_mesh_size.y
		# Then we need to convert it into the following range: 0 -> 1
		event_pos2D.x += 0.5
		event_pos2D.y += 0.5

		# Finally, we convert the position to the following range: 0 -> viewport.size
		event_pos2D.x *= node_viewport.size.x
		event_pos2D.y *= node_viewport.size.y
		# We need to do these conversions so the event's position is in the viewport's coordinate system.

	elif last_event_pos2D != null:
		# Fall back to the last known event position.
		event_pos2D = last_event_pos2D

	# Set the event's position and global position.
	event.position = event_pos2D
	if event is InputEventMouse:
		event.global_position = event_pos2D

	# Calculate the relative event distance.
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		# If there is not a stored previous position, then we'll assume there is no relative motion.
		if last_event_pos2D == null:
			event.relative = Vector2(0, 0)
		# If there is a stored previous position, then we'll calculate the relative position by subtracting
		# the previous position from the new position. This will give us the distance the event traveled from prev_pos.
		else:
			event.relative = event_pos2D - last_event_pos2D
			event.velocity = event.relative / (now - last_event_time)

	# Update last_event_pos2D with the position we just calculated.
	last_event_pos2D = event_pos2D

	# Update last_event_time to current time.
	last_event_time = now

	# Finally, send the processed input event to the viewport.
	node_viewport.push_input(event)


func rotate_area_to_billboard():
	# Get the camera.
	var camera = get_viewport().get_camera_3d()
	# Look in the same direction as the camera.
	var look = camera.to_global(Vector3(0, 0, -10000)) - camera.global_transform.origin
	look = node_skin.position + look

	node_skin.look_at(look, Vector3.UP)

	# Rotate in the Z axis to compensate camera tilt.
	#node_skin.rotate_object_local(Vector3.BACK, camera.rotation.z)

func _unhandled_input(event):
	# ignoere non-mouse events
	for mouse_event in [InputEventMouseButton, InputEventMouseMotion, InputEventScreenDrag, InputEventScreenTouch]:
		if is_instance_of(event, mouse_event):
			return
	node_viewport.push_input(event)
