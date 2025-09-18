extends Node

@onready var route_tool = self.get_parent().find_child("RouteTool")

signal scheduler_opened
signal scheduler_closed


func _on_town_clicked(id: int) -> void:
	route_tool._on_town_clicked(id)
	
func _ready():
	self.find_child("OpenSchedulerButton").connect("pressed", _on_open_scheduler_button_pressed)
	self.find_child("Scheduler").connect("scheduler_closed", _on_scheduler_closed)
	
func _on_open_scheduler_button_pressed():
	emit_signal("scheduler_opened")
	for child in get_children():
		if child is TownLabel:
			child.visible = false
	
func _on_scheduler_closed():
	print_debug("scheuler closed")
	for child in get_children():
		if child is TownLabel:
			child.visible = true
