extends Node3D

func _process(delta):
	self.find_child('windmill2').transform = self.find_child('windmill2').transform.rotated_local(Vector3(1.0, 0.0, 0.0), 0.25 * PI * delta)
