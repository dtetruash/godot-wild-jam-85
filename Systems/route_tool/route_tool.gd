extends Node3D

var clicked_towns: Array[int] = []

@export var vertical_rail_offset: float = 0.1

@onready var map_manager = self.get_parent().find_child("MapManager", true)
@onready var path_finder = map_manager.find_child("PathFinder", true)
@onready var rail_manager = self.get_parent().find_child("RailManager", true)

# TODO: Consider using a factory to instantiate trains
const TRAIN_FOLLOWER = preload('res://Rails/train/train_follower.tscn')

func _on_town_clicked(id: int) -> void:
	if clicked_towns.has(id):
		return
	if clicked_towns.size() == 0:
		clicked_towns.append(id)
	elif clicked_towns.size() > 0:
		clicked_towns.append(id)
		var start_id = clicked_towns[0]
		var end_id = clicked_towns[1]
		var start: Vector2i = map_manager.get_town_centers()[start_id]
		var end: Vector2i = map_manager.get_town_centers()[end_id]
		var path: Array[Vector2i] = path_finder.a_star(start, end)
		var path_world_3d: Array[Vector3] = []
		for axial_coord in path:
			var coord_3d = map_manager.axial_to_world_3d(axial_coord.x, axial_coord.y)
			coord_3d += self.vertical_rail_offset * Vector3.UP
			path_world_3d.append(coord_3d)
		path_world_3d = path_finder.insert_midpoints(path_world_3d)
		print_debug("Creating rail")

		self.rail_manager.add_rail_segment_from_points(start_id, end_id, path_world_3d)
		#var train_follower = TRAIN_FOLLOWER.instantiate()
		#add_child(train_follower)
		#train_follower.assign_to_segment(added_segment)
		emit_signal("rail_added", start_id, end_id)

		clicked_towns.clear()


func _ready() -> void:
	connect("town_clicked", _on_town_clicked)
