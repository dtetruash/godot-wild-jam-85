class_name TownLabel extends Node3D

@export var town_position: Vector3
@export var town_name: String
@export var town_id: int

@onready var button: Button = $TownLabelSkin/SubViewport/TownLabelUI/Button
@onready var ui_manager = self.find_parent("UIContainer")

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)

func _process(delta):
	# `town_global_pos` is the Vector3 position of the town in world space
	self.find_child("Label", true).text = self.town_name


func _on_button_pressed() -> void:
	#print_debug("Clicked!", town_name)
	ui_manager._on_town_clicked(self.town_id)
