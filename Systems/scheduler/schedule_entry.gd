extends Node2D

@onready var hour_select:= self.find_child("HourSelect", true)
@onready var minute_select:= self.find_child("MinuteSelect", true)
@onready var start_select:= self.find_child("Start", true)
@onready var destination_select:= self.find_child("Destination", true)
@onready var enabled:= self.find_child("CheckButton", true)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
