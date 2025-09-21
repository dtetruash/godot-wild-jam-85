extends Control

@onready var rail_manager = self.get_parent().get_parent().find_child("RailManager", true)
@onready var state_machine = self.get_parent().get_parent().find_child("StateMachine")

var preview_rail_available: bool = false

signal confirm_rail

func _ready():
	self.visible = false
	self.rail_manager.connect("preview_rail_built", _on_preview_rail_added)
	self.find_child("BuildButton").connect("pressed", _on_button_pressed)
	self.state_machine.connect("state_changed", _on_state_changed)
	
	
func _process(delta: float):
	pass

func _on_preview_rail_added(length: float):
	self.visible = true
	var cost:int = floor(length)
	self.find_child("PriceDisplay").text = "Cost: %d acorns" % cost
	self.preview_rail_available = true
	
func _on_button_pressed():
	if not self.preview_rail_available:
		return
		
	# TODO: check if there is enough money
	emit_signal("confirm_rail")
	self.preview_rail_available = false
	self.visible = false
	
func _on_state_changed(state_name):
	if state_name == 'overview':
		self.visible = false
		
