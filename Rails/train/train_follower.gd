## Train car which can be assigned to a track to move along it
extends Node3D

@export var train_chars: TrainCharacteristics

var _follower: PathFollow3D = PathFollow3D.new()
var _remote_transform: RemoteTransform3D = RemoteTransform3D.new()
var _current_segment: Path3D = null
var _progress_along_segment: float = 0.0:
	set(value):
		_progress_along_segment = clampf(value, 0.0, 1.0)

func _ready() -> void:
	_follower.rotation_mode = PathFollow3D.ROTATION_XY
	#_follower.v_offset = 0.5
	_follower.loop = true
	_follower.add_child(_remote_transform)
	_remote_transform.remote_path = self.get_path()

	train_chars.speed += randf() * 0.2 * (-1 * randi() % 2 )

func _process(delta: float) -> void:
	move_along_segment(delta)

func assign_to_segment(segment: Path3D):
	if _current_segment != null:
		push_error("Could not assign train to segment since it already has one. Remove it from its current segment fist")
		return

	# add it's follower to that path
	_current_segment = segment
	_current_segment.add_child(_follower)

func remove_from_segment():
	if _current_segment == null:
		push_error("Could not remove train from segment since it was not on one in the first place.")
		return

	# remove the follower from the segment
	_current_segment.remove_child(_follower)
	_follower.progress_ratio = 0.0
	_current_segment = null


func move_along_segment(delta: float):
	_follower.progress_ratio += train_chars.speed * delta
