extends Control

@onready var hour_select:= self.find_child("HourSelect", true)
@onready var minute_select:= self.find_child("MinuteSelect", true)
@onready var start_select:= self.find_child("StartSelect", true)
@onready var destination_select:= self.find_child("DestinationSelect", true)
@onready var enabled:= self.find_child("CheckButton", true)

@export var id:int
@export var town_list: Array
@export var default_hour: int = 12
@export var default_minute: int = 0

var initialized := false

signal entry_changed

func set_town_list(town_list: Array):
	self.start_select.clear()
	self.destination_select.clear()
	for town_name in town_list:
		self.start_select.add_item(town_name)
		self.destination_select.add_item(town_name)
		
	self.start_select.select(0)
	self.destination_select.select(1)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_town_list(self.town_list) # Replace with function body.
	self.hour_select.value = default_hour
	self.minute_select.value = default_minute
	
	self.start_select.connect("item_selected", _on_entry_changed)
	self.destination_select.connect("item_selected", _on_entry_changed)
	self.hour_select.connect("value_changed", _on_entry_changed)
	self.minute_select.connect("value_changed", _on_entry_changed)
	
	emit_signal("entry_changed", self.summarize())

func summarize() -> Dictionary:
	var dict = {
		'id': self.id,
		'destination': self.destination_select.get_item_text(self.destination_select.get_selected_id()),
		'start': self.start_select.get_item_text(self.start_select.get_selected_id()),
		'hour': self.hour_select.value,
		'minute': self.minute_select.value,
	}
	return dict
	
func _on_entry_changed(_val):
	emit_signal("entry_changed", self.summarize())
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
