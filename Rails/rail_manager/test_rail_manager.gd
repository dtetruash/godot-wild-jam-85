## Test rail manager by adding a rail from points
extends Node3D

@export var path_guide: Node3D
@onready var rail_manager = $RailManager

func _ready() -> void:
	var world_points: Array[Vector3]
	for guide_point in path_guide.get_children():
		world_points.append(guide_point.global_position)
	rail_manager.add_rail_segment_from_points(Vector2i(0,1),Vector2i(1,0), world_points)
	print(rail_manager.rails_in_level)
