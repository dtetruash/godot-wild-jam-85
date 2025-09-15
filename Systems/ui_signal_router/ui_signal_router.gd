extends Node

@onready var route_tool = self.get_parent().find_child("RouteTool")

func _on_town_clicked(id: int) -> void:
	route_tool._on_town_clicked(id)
