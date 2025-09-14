extends TextureRect

@export var town_position: Vector3
@export var town_name: String

func _process(delta):
	var viewport = get_viewport()
	# `town_global_pos` is the Vector3 position of the town in world space
	var screen_pos = viewport.get_camera_3d().unproject_position(town_position)
	self.position = screen_pos - self.size / 2  # center label above town
	self.find_child("Label").text = self.town_name
