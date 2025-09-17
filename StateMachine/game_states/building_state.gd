class_name BuildingState
extends State

func _enter():
	print("entered building")

func _on_build_mode_button_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		transitioned.emit(self, "overview")
