extends Label

@onready var time_manager = self.get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var display_time: Vector2 = self.time_manager.get_display_time_truncated()
	# giving up on have 00:00 formatting because it doesn't work for some reason and this is a placeholder anyway
	self.text = "%2d:%2d" % [display_time.x, display_time.y] 
