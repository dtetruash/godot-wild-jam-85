extends Node2D

const minutes_per_day: float = 1440.0

enum Day {
	Monday,
	Tuesday,
	Wednesday,
	Thursday,
	Friday,
	Saturday,
	Sunday,
}

@export var start_time = 480.0
@export var day_duration_wall_time_minutes: float = 5.0
@export var current_time: float = start_time

@onready var time_multiplier = minutes_per_day / day_duration_wall_time_minutes
@onready var map_manager = self.get_parent().find_child("MapManager", true)

var time_started: bool = false

signal time_changed(hours, minutes, day)

## This function returns a Vector2 with the x component being hours and y being minutes and z being day
func get_display_time_truncated() -> Vector3:
	var hours = int(floorf(current_time / 60.0)) % 24
	var minutes = int(current_time) % 60
	var day = int(current_time / minutes_per_day) % 7
	return Vector3(hours, minutes, day)
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	current_time += time_multiplier * (delta / 60.0)
	var display_time = self.get_display_time_truncated()
	emit_signal("time_changed", display_time.x, display_time.y, display_time.z)
