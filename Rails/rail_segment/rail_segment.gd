@tool
extends Path3D

@export_range(0.3, 1.0) var plank_interval: float = 0.25:
	set(value):
		_regenerate_multimesh()
		plank_interval = clampf(value, 0.3, 1.0)

@export var should_smooth_segment : bool = false

## Node whose childer's transforms could be used as points of the segment
@export var path_guide: Node3D
@export var should_use_path_guide: bool = false

@export var show_segment_points: bool = false
@onready var segment_point_visualizer: Node3D = $SegmentPointVisualizer
const DEBUG_MARKER_SPHERE = preload('res://visual_debug/markers/debug_marker_sphere.tscn')

@onready var plank_multimesh: MultiMesh = $TrackPlanks.multimesh
var is_mesh_dirty: bool = false

## Set the world points of the segment's path and recompute it's mesh
func set_segment_points(world_points: Array[Vector3]) -> void:

	curve.clear_points()
	var point_count := world_points.size()

	for point_idx in range(0, point_count):
		curve.add_point(world_points[point_idx])

		if show_segment_points:
			var debug_point = DEBUG_MARKER_SPHERE.instantiate()
			debug_point.transform.origin = world_points[point_idx]
			debug_point.scale = 2.0 * Vector3.ONE
			segment_point_visualizer.add_child(debug_point)

	if should_smooth_segment:
		CurveSmoothing.smooth(curve)

func _ready() -> void:
	_set_curve_points_from_guide()

func _process(_delta: float) -> void:
	if is_mesh_dirty:
		_regenerate_multimesh()
		is_mesh_dirty = false

func _set_curve_points_from_guide() -> void:
	if not (path_guide and should_use_path_guide):
		return

	var world_points: Array[Vector3]
	for guide in path_guide.get_children():
		world_points.append(guide.global_position)

	self.set_segment_points(world_points)

func  _regenerate_multimesh():
	if not plank_multimesh:
		return

	print_debug("Regenerating rail segment planks on " + str(self))

	var segment_length: float = curve.get_baked_length()
	var plank_count: int = floor(segment_length / plank_interval)

	plank_multimesh.instance_count = plank_count
	var offset_along_path: float = plank_interval * 0.5

	for plank_idx in range(0, plank_count):
		var distance_along_path = offset_along_path + plank_interval * plank_idx
		var plank_position = curve.sample_baked(distance_along_path, true)
		var plank_ahead = curve.sample_baked(distance_along_path + 0.1, true)
		var plank_transform = Transform3D(Basis(), plank_position).looking_at(plank_ahead, Vector3.UP)

		plank_multimesh.set_instance_transform(plank_idx, plank_transform)


func _on_curve_changed() -> void:
	is_mesh_dirty = true
