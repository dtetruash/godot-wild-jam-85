extends State
class_name PreviewRailState

@onready var track_right: CSGPolygon3D = %TrackRight
@onready var track_left: CSGPolygon3D = %TrackLeft
@onready var track_planks: MultiMeshInstance3D = %TrackPlanks

const PREVIEW_PLACABLE = preload('res://Rails/rail_segment/preview_placable.material')
const PREVIEW_NONPLACABLE = preload('res://Rails/rail_segment/preview_nonplacable.material')

func _enter():
	track_planks.material_override = PREVIEW_PLACABLE
	track_left.material_override = PREVIEW_PLACABLE
	track_right.material_override = PREVIEW_PLACABLE

func _on_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_released() && event.keycode == KEY_C:
			transitioned.emit(self, "constructed")
