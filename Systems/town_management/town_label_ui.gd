extends Control

@onready var button: Button = $Button
@onready var ui_manager = self.find_parent("UIContainer")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	print_debug("Clicked a town!")
	ui_manager._on_town_clicked(self.town_id)
