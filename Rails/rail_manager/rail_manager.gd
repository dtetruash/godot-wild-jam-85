## Manage the creation of rails in the world
extends Node3D

@export var rail_segment: PackedScene = preload("res://Rails/rail_segment/rail_segment.tscn")

# (Vector2i, Vector2i) -> RailSegment
@export var rails_in_level: Dictionary[Array, Node3D]

signal rail_added

func add_rail_segment_from_points(start: int, end: int, world_points: Array[Vector3]):
	var segment := rail_segment.instantiate()
	self.add_child(segment)
	segment.set_segment_points(world_points)
	rails_in_level[[start, end]] = segment
	#return segment
	
func get_segment(start:int, end:int):
	if [start, end] in self.rails_in_level.keys():
		return self.rails_in_level[[start, end]]
	elif [end, start] in self.rails_in_level.keys():
		return self.rails_in_level[[end, start]]
	else:
		return null

func remove_rail_segment(start: int, end: int):
	var key = [start, end]
	if not rails_in_level.has(key):
		return
	var to_remove = rails_in_level[key]
	rails_in_level.erase(key)
	to_remove.queue_free()

func get_towns_with_rails() -> Array[int]:
	var towns_with_rails: Array[int] = []
	for rail in rails_in_level.keys():
		if not rail[0] in towns_with_rails:
			towns_with_rails.append(rail[0])
		if not rail[1] in towns_with_rails:
			towns_with_rails.append(rail[1])
	return towns_with_rails
