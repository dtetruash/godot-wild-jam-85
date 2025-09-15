@tool
extends Node3D

@export_range(0.3, 1.0) var plank_interval : float = 0.25:
	set(value):
		_regenerate_multimesh()
		plank_interval = clampf(value, 0.3, 1.0)

@export var should_smooth_segment : bool = false

## Node whose childer's transforms could be used as points of the segment
@export var path_guide: Node3D

@onready var segment_path: Path3D = self.find_child("SegmentPath")
@onready var plank_multimesh: MultiMesh = $SegmentPath/TrackPlanks.multimesh
var is_mesh_dirty: bool = false

func _ready() -> void:
	print("HI: ", self.segment_path)
	_set_curve_points_from_guide()

## Set the world points of the segment's path and recompute it's mesh
func set_segment_points(world_points: Array[Vector3]) -> void:
	if not segment_path:
		push_error("Tried setting rail segment world_points without a Path.")
		return

	var segment_curve := segment_path.curve
	var point_count := world_points.size()

	segment_curve.clear_points()

	for point_idx in range(0, point_count):
		segment_curve.add_point(world_points[point_idx])

	if should_smooth_segment:
		CurveSmoothing.smooth(segment_curve)

func _set_curve_points_from_guide() -> void:
	if not path_guide:
		return

	var world_points: Array[Vector3]
	for guide in path_guide.get_children():
		world_points.append(guide.global_position)

	self.set_segment_points(world_points)

func _process(_delta: float) -> void:
	if is_mesh_dirty:
		_regenerate_multimesh()
		is_mesh_dirty = false

func  _regenerate_multimesh():
	if segment_path == null:
		return

	var segment_length: float = segment_path.curve.get_baked_length()
	var plank_count = floor(segment_length / plank_interval)

	plank_multimesh.instance_count = plank_count
	var offset_along_path: float = plank_interval * 0.5

	for plank_idx in range(0, plank_count):
		var distance_along_path = offset_along_path + plank_interval * plank_idx
		var plank_position = segment_path.curve.sample_baked(distance_along_path, true)
		var plank_ahead = segment_path.curve.sample_baked(distance_along_path + 0.1, true)
		var plank_transform = Transform3D(Basis(), plank_position).looking_at(plank_ahead, Vector3.UP)

		plank_multimesh.set_instance_transform(plank_idx, plank_transform)

func _on_path_3d_curve_changed() -> void:
	is_mesh_dirty = true
