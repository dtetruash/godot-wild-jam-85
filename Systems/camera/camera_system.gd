# Camera system
# This system has two modes: Overview and Focus
# When in Overview mode, it has no rotation and can be paned with click and drag
# and can be toggled between close, medium, and far zoom with the mouse wheel.
# When in focus mode, it automatically locks into close zoom and begins to rotate
# around the focus point.

extends Node3D

enum CameraMode {
    Overview,
    Focus,
}

@export var camera_mode : CameraMode = CameraMode.Overview

@export_group("Zoom Properties", "zoom")
@export var zoom_stops: Array[float] = [3.0, 5.0, 10.0]
@export var zoom_speed: float = 3.0

@export_group("Input Actions")
@export var input_action_zoom_in: String = "camera_zoom_in"
@export var input_action_zoom_out: String = "camera_zoom_out"

@onready var camera_arm: SpringArm3D = $CameraPivot/CameraArm

var current_zoom_stop_index: int = 0
var target_zoom_stop: float = zoom_stops[current_zoom_stop_index]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    zoom_stops.sort()

func _process(delta: float) -> void:
    if camera_arm.spring_length != target_zoom_stop:
        _move_camera_arm(delta)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed(input_action_zoom_in):
        _zoom_in()

    if event.is_action_pressed(input_action_zoom_out):
        _zoom_out()

# Move the camera arm with easing
func _move_camera_arm(delta: float):
    camera_arm.spring_length = lerp(camera_arm.spring_length, target_zoom_stop, delta * zoom_speed)

func _zoom_in():
    if current_zoom_stop_index == 0:
        return
    current_zoom_stop_index -= 1
    target_zoom_stop = zoom_stops[current_zoom_stop_index]

func _zoom_out():
    if current_zoom_stop_index == zoom_stops.size() - 1:
        return
    current_zoom_stop_index += 1
    target_zoom_stop = zoom_stops[current_zoom_stop_index]
