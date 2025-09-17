class_name Overview
extends State

func _enter():
	print("entered overview")

func _on_build_mode_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		transitioned.emit(self, "building")
