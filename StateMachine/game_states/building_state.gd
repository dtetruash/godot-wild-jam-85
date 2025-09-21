class_name BuildingState
extends State

@onready var ui_router = self.get_parent().get_parent().find_child("UIContainer")
@onready var route_tool = self.get_parent().get_parent().find_child("RouteTool", true)
func _enter():
	print("entered building")

func _on_build_mode_button_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		transitioned.emit(self, "overview")

func _ready():
	ui_router.connect("town_clicked", _on_town_clicked)


func _on_town_clicked(id: int):
	if self.get_parent().current_state == self:
		print_debug("town_clicked in build state")
		route_tool.select_town(id)
