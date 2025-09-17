extends Node

@onready var rail_manager = self.get_parent().get_parent().find_child("RailManager", true)
@export var schedule: Array[Dictionary] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.find_child("Exit").connect("pressed", _on_exit_clicked)
	self.get_parent().connect("scheduler_opened", _open_scheduler)
	self.find_child("AddScheduleEntryButton").connect("pressed", _on_add_schedule_entry)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_exit_clicked():
	self.visible = false
	emit_signal("scheduler_closed")
	
func _open_scheduler() -> void:
	self.visible = true

func _on_add_schedule_entry():
	print_debug("adding schedule entry")
	
