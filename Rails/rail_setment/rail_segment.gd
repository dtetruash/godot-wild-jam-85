@tool
extends Node3D

@export_range(0.3, 1.0) var plank_interval : float = 0.25:
	set(value):
		_regenerate_multimesh()
		plank_interval = clampf(value, 0.3, 1.0)


@onready var segment_path: Path3D = $SegmentPath
@onready var plank_multimesh: MultiMesh = $SegmentPath/TrackPlanks.multimesh
var is_dirty: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if is_dirty:
		_regenerate_multimesh()
		is_dirty = false

func  _regenerate_multimesh():
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


func _on_path_3d_curve_changed() -> void:
	is_dirty = true
