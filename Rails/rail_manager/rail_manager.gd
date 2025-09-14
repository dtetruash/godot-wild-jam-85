## Manage the creation of rails in the world
extends Node3D

@export var rail_segment: PackedScene

# (Vector2i, Vector2i) -> RailSegment
@export var rails_in_level: Dictionary[Array, Node3D]

func add_rail_segment_from_points(start: Vector2i, end: Vector2i, world_points: Array[Vector3]):
	var segment := rail_segment.instantiate()
	self.add_child(segment)
	segment.set_segment_points(world_points)
	rails_in_level[[start, end]] = segment

func remove_rail_segment(start: Vector2i, end: Vector2i):
	var key = [start, end]
	if not rails_in_level.has(key):
		return

	var to_remove = rails_in_level[key]
	rails_in_level.erase(key)
	to_remove.queue_free()
