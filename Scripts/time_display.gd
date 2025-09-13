extends Label

@onready var time_manager = self.get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	time_manager.connect("time_changed", _on_time_changed)


func _on_time_changed(hours: int, minutes: int, day: int) -> void:
	self.text = "%02d:%02d" % [hours, minutes]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
