extends Node3D

@onready var map_manager = self.get_parent()
@onready var town_names_set = preload("res://Scripts/town_names.gd").TOWN_NAMES
@export var town_names: Array[String] = []
@export var town_centers: Array[Vector3] = []
@export var population: Array[float] = []
@export var rng_seed: int = 10

var num_labels = 0

func initialize_town_data(town_centers_2d: Array[Vector2i]):
	
	var rng = RandomNumberGenerator.new()
	rng.seed = rng_seed

	var num_towns = town_centers_2d.size()
	var num_town_names = town_names_set.size()
	print_debug("initializing %d towns" % num_towns)
	for i in range(num_towns):
		var town_center_2d = town_centers_2d[i]
		self.town_names.append(town_names_set[rng.randi() % num_town_names])
		self.town_centers.append(self.map_manager.axial_to_world_3d(town_center_2d.x, town_center_2d.y))

func initialize_ui_elements():
	print_debug("About to initialize %d labels" % town_names.size())
	for i in range(self.town_names.size()):
		print_debug("Initializing label for ", town_names[i])
		var label_3d = Label3D.new()
		label_3d.text = town_names[i]
		label_3d.pixel_size = 0.05
		label_3d.transform.origin = self.town_centers[i] + 5.0 * Vector3.UP
		self.add_child(label_3d)
		self.num_labels += 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if self.num_labels == 0:
		self.initialize_ui_elements()
