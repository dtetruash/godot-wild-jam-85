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

## This function returns a Vector2 with the x component being hours and y being minutes
func get_display_time_truncated() -> Vector2:
	var hours = floorf(current_time / 60.0)
	var minutes = int(current_time) % 60
	return Vector2(hours, minutes)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	current_time += time_multiplier * (delta / 60.0)
