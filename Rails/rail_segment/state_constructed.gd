extends State
class_name ConstructedRailState

@onready var track_right: CSGPolygon3D = %TrackRight
@onready var track_left: CSGPolygon3D = %TrackLeft
@onready var track_planks: MultiMeshInstance3D = %TrackPlanks

const MATERIAL_RAIL_METAIL = preload('res://Rails/rail_segment/material_rail_metail.material')
const RAIL_WOOD = preload('res://Rails/rail_segment/rail_wood.material')

func _enter():
	track_planks.material_override = RAIL_WOOD
	track_left.material_override = MATERIAL_RAIL_METAIL
	track_right.material_override = MATERIAL_RAIL_METAIL

func _on_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_released() && event.keycode == KEY_C:
			transitioned.emit(self, "preview")
