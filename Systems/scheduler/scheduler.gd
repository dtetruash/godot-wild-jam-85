extends Node

const TRAIN_FOLLOWER = preload('res://Rails/train/train_follower.tscn')
const schedule_entry_template = preload("res://Systems/scheduler/schedule_entry.tscn")
@onready var rail_manager = self.get_parent().get_parent().find_child("RailManager", true)
@onready var town_manager = self.get_parent().get_parent().find_child("TownManager", true)
@onready var time_manager = self.get_parent().find_child("TimeManager", true)
@onready var entry_container = self.find_child("EntryContainer", true)
@export var schedule: Array[Dictionary] = []

signal scheduler_closed
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.find_child("Exit").connect("pressed", _on_exit_clicked)
	self.get_parent().connect("scheduler_opened", _open_scheduler)
	self.find_child("AddScheduleEntryButton").connect("pressed", _on_add_schedule_entry)
	self.time_manager.connect("time_changed", _on_time_changed)
	
	# hide menu to start
	self.visible = false
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
	var new_schedule_entry = schedule_entry_template.instantiate()
	#new_schedule_entry.transform.origin = Vector2(0, (schedule.size() + 1) * 32)
	var towns_with_rails = []
	for id in rail_manager.get_towns_with_rails():
		towns_with_rails.append(town_manager.town_names[id])
	new_schedule_entry.town_list = towns_with_rails
	new_schedule_entry.connect("entry_changed", _on_schedule_entry_changed)
	new_schedule_entry.id = self.schedule.size()
	self.schedule.append({})
	entry_container.add_child(new_schedule_entry)
	
	
func _on_schedule_entry_changed(schedule_entry: Dictionary):
	print_debug("entry changed")
	print_debug(schedule_entry)
	var idx = schedule_entry['id']
	self.schedule[idx] = schedule_entry
	
func _on_time_changed(hour: int, minute: int, day: int):
	for entry in self.schedule:
		if entry['hour'] == hour and entry['minute'] == minute:
			print_debug("CHOOO CHOOO!!!!")
			# first, find the two towns
			var start_id = town_manager.find_town_with_name(entry['start'])
			var end_id = town_manager.find_town_with_name(entry['destination'])
			var segment = rail_manager.get_segment(start_id, end_id)
			if segment == null:
				continue
			var train_follower = TRAIN_FOLLOWER.instantiate()
			self.add_child(train_follower)
			train_follower.assign_to_segment(segment)
