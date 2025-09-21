class_name Money extends Control

@export var current_money:= 100

func _process(delta) -> void:
	self.get_child(2).text = "%d" % current_money
	
	
func get_current_money() -> int:
	return current_money
	
func add_money(amt: int) -> void:
	self.current_money += amt
	
func remove_money(amt: int) -> void:
	self.current_money -= amt
