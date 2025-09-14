extends Node

## Manage the creation of rails in the world

# (Vector2i, Vector2i) -> RailSegment
var rails_in_level: Dictionary[Array, RailSegment]

func add_rail_segment(start: Vector2i, end: Vector2i, world_points: Array[Vector3]):
	var segment = RailSegment.new(world_points)
	rails_in_level[[start, end]] = segment
	add_child(segment)

func remove_rail_segment(start: Vector2i, end: Vector2i):
	var key = [start, end]
	if not rails_in_level.has(key):
		return

	var to_remove = rails_in_level[key]
	rails_in_level.erase(key)
	to_remove.queue_free()
