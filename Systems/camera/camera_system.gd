# Camera system
# This system has two modes: Overview and Focus

extends Node3D

enum CameraMode {
    ## Pan by clicking and dragging and zoomed between zoom stops.
    Overview,
    ## Automatically lock into the smallest zoom stop and begin to rotate around the focus point.
    Focus,
}

## The behaviors mode of the camera
@export var camera_mode : CameraMode = CameraMode.Overview

@export_group("Angle Properties")
@export_range(-85.0, -10.0) var camera_angle := -40.0:
    set(value):
        camera_angle = clampf(value, -40.0, -15.0)
@export_range(5, 360) var algular_speed := 5

@export_group("Zoom Properties", "zoom")
## Distances from the focus point that the camera will stop at after each zoom input.
@export var zoom_stops: Array[float] = [3.0, 5.0, 10.0]
var current_zoom_stop_index: int = zoom_stops.size() - 1
var target_zoom_stop: float = zoom_stops[current_zoom_stop_index]:
    set(value):
        target_zoom_stop = clampf(value, zoom_minimum, zoom_maximum)

@export var zoom_minimum: float = 1.0
@export var zoom_maximum: float = 15.0
## The speed at which the camera will travel between zoom stops.
@export var zoom_speed: float = 3.0

@export_group("Pan Properties", "pan")
@export var pan_speed_coefficient := 0.01
var _is_panning := false

@export_group("Input Actions", "input_action")
@export var input_action_zoom_in: String = "camera_zoom_in"
@export var input_action_zoom_out: String = "camera_zoom_out"
@export var input_action_pan: String = "camera_pan"

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_arm: SpringArm3D = $CameraPivot/CameraArm


func _ready() -> void:
    zoom_stops.sort()

func _process(delta: float) -> void:
    if camera_arm.spring_length != target_zoom_stop:
        _vary_camera_arm_length(delta)

    if camera_pivot.rotation_degrees.x != camera_angle:
        _angle_camera_arm(delta)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed(input_action_zoom_in):
        _zoom_in()

    if event.is_action_pressed(input_action_zoom_out):
        _zoom_out()

    if event.is_action_pressed(input_action_pan):
        _is_panning = true
    if event.is_action_released(input_action_pan):
        _is_panning = false
    if _is_panning && event is InputEventMouseMotion:
        var pan_direction := -Vector3(event.relative.x, 0, event.relative.y)
        position += pan_direction * pan_speed_coefficient * zoom_stops[current_zoom_stop_index]

# Move the camera arm with easing
func _vary_camera_arm_length(delta: float):
    camera_arm.spring_length = lerp(camera_arm.spring_length, target_zoom_stop, delta * zoom_speed)

func _angle_camera_arm(delta: float):
    camera_pivot.rotation_degrees.x = lerp(camera_pivot.rotation_degrees.x, camera_angle, delta * algular_speed)

func _zoom_in():
    current_zoom_stop_index = max(current_zoom_stop_index - 1, 0)
    target_zoom_stop = zoom_stops[current_zoom_stop_index]
    camera_angle += 15

func _zoom_out():
    current_zoom_stop_index = min(current_zoom_stop_index + 1, zoom_stops.size() - 1)
    target_zoom_stop = zoom_stops[current_zoom_stop_index]
    camera_angle -= 15
