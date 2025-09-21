## Manage the creation of rails in the world
extends Node3D

@export var rail_segment: PackedScene = preload("res://Rails/rail_segment/rail_segment.tscn")

# (Vector2i, Vector2i) -> RailSegment
@export var _rails_in_level: Dictionary[Array, Node3D]
@export var preview_rail: Node3D = null
@export var preview_key: Array

@onready var confirm_build = self.get_parent().get_parent().find_child("ConfirmBuild")
@onready var state_machine = self.get_parent().get_parent().find_child("StateMachine")

const PREVIEW_PLACABLE = preload('res://Rails/rail_segment/preview_placable.material')
const PREVIEW_NONPLACABLE = preload('res://Rails/rail_segment/preview_nonplacable.material')
const MATERIAL_RAIL_METAIL = preload('res://Rails/rail_segment/material_rail_metail.material')
const RAIL_WOOD = preload('res://Rails/rail_segment/rail_wood.material')


signal rail_added
signal preview_rail_built

func _ready() -> void:
	confirm_build.connect("confirm_rail", _on_confirm_rail)
	state_machine.connect("state_changed", _on_state_changed)

func add_rail_segment_from_points(start: int, end: int, world_points: Array[Vector3]):
	if preview_rail != null:
		self.remove_child(preview_rail)
		preview_rail = null
	if [start, end] in _rails_in_level or [end, start] in _rails_in_level:
		return
	var segment := rail_segment.instantiate()
	self.add_child(segment)
	segment.set_segment_points(world_points)
	self.preview_rail = segment
	self.preview_key = [start, end]
	
	# set material to preview material
	# TODO: Check if there is enough money
	self.preview_rail.find_child("TrackRight").material_override = PREVIEW_PLACABLE
	self.preview_rail.find_child("TrackLeft").material_override = PREVIEW_PLACABLE
	self.preview_rail.find_child("TrackPlanks").material_override = PREVIEW_PLACABLE
	
	emit_signal("preview_rail_built", self.preview_rail.curve.get_baked_length())

func _on_confirm_rail():
	print_debug("Adding rail to network")
	_build_rail(self.preview_key[0], self.preview_key[1], self.preview_rail)
	self.preview_rail = null

func _build_rail(start:int, end: int, segment):
	self.preview_rail.find_child("TrackRight").material_override = MATERIAL_RAIL_METAIL
	self.preview_rail.find_child("TrackLeft").material_override = MATERIAL_RAIL_METAIL
	self.preview_rail.find_child("TrackPlanks").material_override = RAIL_WOOD
	
	
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

func _on_state_changed(state_name):
	if state_name == 'overview':
		self.remove_child(self.preview_rail)
		self.preview_rail = null
		
		
