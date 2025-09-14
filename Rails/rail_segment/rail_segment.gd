@tool
class_name RailSegment extends Node3D

@export_range(0.3, 1.0) var plank_interval : float = 0.25:
	set(value):
		_regenerate_multimesh()
		plank_interval = clampf(value, 0.3, 1.0)

## Node whose childer's transforms will be used as points of the segment
@export var path_guide: Node3D

@onready var segment_path: Path3D = $SegmentPath
@onready var plank_multimesh: MultiMesh = $SegmentPath/TrackPlanks.multimesh
var is_mesh_dirty: bool = false

func _init(world_points: Array[Vector3]) -> void:
	self.set_segment_points(world_points)

func _ready() -> void:
	_set_curve_points_from_guide()

func set_segment_points(world_points: Array[Vector3]) -> void:
	if not segment_path:
		printerr("Tried setting rail segment world_points without a Path.")
		return

	var segment_curve := segment_path.curve
	var point_count := world_points.size()

	segment_curve.clear_points()

	for point_idx in range(0, point_count):
		segment_curve.add_point(world_points[point_idx])

	CurveSmoothing.smooth(segment_curve)

func _set_curve_points_from_guide():
	if not path_guide:
		return

	var segment_curve := segment_path.curve
	var point_count: int  = path_guide.get_child_count()

	segment_curve.clear_points()

	for point_idx in range(0, point_count):
		var guide: Node3D = path_guide.get_child(point_idx)
		segment_curve.add_point(guide.global_position)

	CurveSmoothing.smooth(segment_path.curve)


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

		var plank_forward = plank_position.direction_to(
			segment_path.curve.sample_baked(distance_along_path + 0.1, true)
		).normalized()
		var plank_up = segment_path.curve.sample_baked_up_vector(distance_along_path, true).normalized()
		var plank_right = plank_forward.cross(plank_up).normalized()

		var plank_basis = Basis(
			plank_right,
			plank_up,
			-plank_forward
		)
		var plank_transform = Transform3D(plank_basis, plank_position)

		plank_multimesh.set_instance_transform(plank_idx, plank_transform)

func _on_path_3d_curve_changed() -> void:
	is_mesh_dirty = true
