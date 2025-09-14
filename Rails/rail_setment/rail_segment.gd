@tool
extends Node3D

@export_range(0.3, 1.0) var plank_interval : float = 0.25:
	set(value):
		_regenerate_multimesh()
		plank_interval = clampf(value, 0.3, 1.0)

## Snap each segment path point to the closest solid object below it.
@export var snap_to_floor: bool = false
## How far down should be look from each point to snap to.
@export var snap_margin: float = 10.0:
	set(value):
		snap_margin = max(1.0, value)

@export var path_guide: Node3D

@onready var segment_path: Path3D = $SegmentPath
@onready var plank_multimesh: MultiMesh = $SegmentPath/TrackPlanks.multimesh
var is_mesh_dirty: bool = false
var is_path_dirty: bool = false

func _ready() -> void:
	# get points to go through
	var segment_curve := segment_path.curve
	segment_curve.clear_points()
	var point_count: int  = path_guide.get_child_count()

	segment_curve.point_count = point_count
	for point_idx in range(0, point_count):
		var guide: Node3D = path_guide.get_child(point_idx)
		segment_curve.set_point_position(point_idx, guide.global_position)
		segment_curve.set_point_tilt(point_idx, 0)


func _process(_delta: float) -> void:
	if is_mesh_dirty:
		_regenerate_multimesh()
		is_mesh_dirty = false

func _physics_process(_delta: float) -> void:
	if snap_to_floor:
			_snap_path_to_floor()
			is_path_dirty = false

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
		var plank_up = segment_path.curve.sample_baked_up_vector(distance_along_path, true)
		var plank_right = plank_forward.cross(plank_up).normalized()

		var plank_basis = Basis(
			plank_right,
			plank_up,
			-plank_forward
		)
		var plank_transform = Transform3D(plank_basis, plank_position)

		plank_multimesh.set_instance_transform(plank_idx, plank_transform)


func _snap_path_to_floor():
	# print("snapping path to flor")
	# for each point in the path
	var path_points :=  segment_path.curve.get_baked_points()
	var point_count: int = segment_path.curve.point_count
	print(point_count)
	print(path_points)
	for point_idx: int in range(0, point_count):
		var path_point: Vector3 = path_points[point_idx]

		var ray_query := PhysicsRayQueryParameters3D.create(path_point, path_point + Vector3.DOWN * snap_margin)
		var space_state := get_world_3d().direct_space_state
		var ray_cast_result := space_state.intersect_ray(ray_query)
		print("about to snap poitn " + str(point_idx) + " with res " + str(ray_cast_result))
		if ray_cast_result:
			path_point = ray_cast_result.position
			print("setting point " + str(point_idx) + " to " + str(path_point))
			segment_path.curve.set_point_position(point_idx, path_point)


func _on_path_3d_curve_changed() -> void:
	is_mesh_dirty = true
	is_path_dirty = true
