## Manage the creation of rails in the world
extends Node3D

@export var rail_segment: PackedScene = preload("res://Rails/rail_segment/rail_segment.tscn")

# (Vector2i, Vector2i) -> RailSegment
@export var _rails_in_level: Dictionary[Array, Node3D]

signal rail_added

func add_rail_segment_from_points(start: int, end: int, world_points: Array[Vector3]):
	if [start, end] in _rails_in_level or [end, start] in _rails_in_level:
		return
	var segment := rail_segment.instantiate()
	self.add_child(segment)
	segment.set_segment_points(world_points)
	_rails_in_level[[start, end]] = segment

func get_segment(start:int, end:int):
	if [start, end] in self._rails_in_level.keys():
		return self._rails_in_level[[start, end]]
	elif [end, start] in self._rails_in_level.keys():
		return self._rails_in_level[[end, start]]
	else:
		return null

func remove_rail_segment(start: int, end: int):
	var to_remove: Node3D
	if [start, end] in _rails_in_level:
		to_remove = _rails_in_level.get([start, end])
		_rails_in_level.erase([start, end])
		to_remove.queue_free()
	elif [end, start] in _rails_in_level:
		to_remove = _rails_in_level.get([end, start])
		_rails_in_level.erase([end, start])
		to_remove.queue_free()
	else:
		push_warning("Tried remove a non-existant rail segment " + str([start, end]) + " from graph")

func get_towns_with_rails() -> Array[int]:
	var towns_with_rails: Array[int] = []
	for rail in _rails_in_level.keys():
		if not rail[0] in towns_with_rails:
			towns_with_rails.append(rail[0])
		if not rail[1] in towns_with_rails:
			towns_with_rails.append(rail[1])
	return towns_with_rails

func is_town_in_network(town_id: int) -> bool:
	return town_id in get_towns_with_rails()
