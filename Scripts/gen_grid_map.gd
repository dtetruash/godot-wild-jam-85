@tool
extends Node3D
## Generates grid map terrain for the cozy train
##
## Note that this grid map only generates basic terrain types
## Decorations will be added using a separate type.

@export var num_cities: int = 15
@export var island_radius: int = 25
@export var island_height: int = 50
@export var island_width: int = 50
@export var city_min_dist: int = 3
@export var hex_radius: float = 1.0
@export var radius_threshold: float = 0.8

@export_group("Noise Config")
@export var city_seed: int = 38
@export var biome_seed: int = 38 # 38 is a good seed
@export var biome_frequency: float = 0.05
@export var island_shape_seed: int = 38 # 38 is a good seed
@export var island_shape_frequency: float = 0.05
@export var radial_noise_weight: float = 0.5

@onready var tile_mesh = preload("res://Scenes/Tilesv2.tscn")
@onready var water_material = preload("res://Assets/Materials/Water.tres")
@onready var grass_material = preload("res://Assets/Materials/Grass.tres")
@onready var forest_material = preload("res://Assets/Materials/Forest.tres")
@onready var mountain_material = preload("res://Assets/Materials/Mountain.tres")
@onready var city_material = preload("res://Assets/Materials/City.tres")

# TODO: eventually, this should be an array of 
# "City" data classes that contain other info about the city
# ie name, location, population (if we care), etc.

@onready var cells := {}

enum TileType {
	WaterTile,
	ForestTile,
	GrassTile,
	CityTile,
	MountainTile,
}

##
## Cells have the following information
## Cell {
##	axial_coordinates: Vector2(p, r)
## 	type: TileType,
## }
##

func _cube_round(frac: Vector3) -> Vector3:
	var q = round(frac.x)
	var r = round(frac.z)
	var s = round(frac.y)

	var q_diff = abs(q - frac.x)
	var r_diff = abs(r - frac.z)
	var s_diff = abs(s - frac.y)

	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s
	else:
		s = -q - r
	return Vector3(q, s, r)
	
func for_each_cell(callback: Callable) -> void:
	for key in cells.keys():
		callback.call(key, cells[key])

func axial_to_world(q: int, r: int) -> Vector2:
	var y = hex_radius * (3.0/2.0 * q)
	var x = hex_radius * (sqrt(3.0) * (r + q/2.0))
	return Vector2(x, y)

func world_to_axial(pos: Vector2) -> Vector2:
	var q = (2.0/3.0 * pos.x) / hex_radius
	var r = (-1.0/3.0 * pos.x + sqrt(3.0)/3.0 * pos.y) / hex_radius
	var v = _cube_round(Vector3(q, -q-r, r))
	return Vector2(v.x, v.z)
	
func neighbors(q: int, r: int) -> Array:
	var dirs = [
		Vector2(1, 0), Vector2(1, -1), Vector2(0, -1),
		Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1)
	]
	var results = []
	for d in dirs:
		var n = Vector2(q + d.x, r + d.y)
		if n in cells:
			results.append(n)
	return results
	
func get_cities() -> Array:
	var ret = []
	for cell in cells:
		if self.cells[cell]['type'] == TileType.CityTile:
			ret.append(cell)
	return ret

func query_distance_to_cities(q: Vector2) -> float:
	var cities_arr = self.get_cities()
	if cities_arr.size() == 0:
		return 1000.0
	var min_dist = 100000.0 # some large value
	for city in cities_arr:
		var dist = (city - q).length()
		if min_dist > dist:
			min_dist = dist
	return min_dist
	
func get_cell(q: int, r: int) -> Variant:
	var key = Vector2(q, r)
	if key in cells:
		return cells[key]
	return null  # or some default like "empty"

func set_cell(q: int, r: int, value: Variant) -> void:
	var key = Vector2(q, r)
	if key in cells:
		cells[key] = value
	else:
		push_warning("Tried to set cell out of bounds at (%d, %d)" % [q, r])
		
func generate_hexagon(radius: int) -> void:
	cells.clear()
	for q in range(-radius, radius + 1):
		for r in range(-radius, radius + 1):
			var s = -q - r
			if abs(s) <= radius:
				cells[Vector2(q, r)] = null
				
func populate_biomes() -> void:
	# Instantiate
	var noise = FastNoiseLite.new()
	# Configure
	noise.seed = biome_seed # hard-coded for debugging, can replace with randi() later
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = biome_frequency
	
	# Instantiate
	var radial_noise = FastNoiseLite.new()
	# Configure
	radial_noise.seed = island_shape_seed # hard-coded for debugging, can replace with randi() later
	radial_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	radial_noise.frequency = island_shape_frequency
	
	var map_radius = 0.5 * sqrt(island_height * island_height + island_width * island_width)
	
	for cell in self.cells.keys():
		var q = cell.x
		var r = cell.y
		var world_loc = axial_to_world(q, r)
		var x_coord = world_loc.x
		var y_coord = world_loc.y
		var val = (noise.get_noise_2d(float(x_coord), float(y_coord)) + 1.0) # normalize to (0,1)
		val = max(0.0, val)
		# calculate fall off - we want an island shape, don't we? :)
		var dist = sqrt((x_coord * x_coord) + (y_coord * y_coord))
		var radius_change = radial_noise.get_noise_2d(float(x_coord), float(y_coord))

		var tile_type = TileType.WaterTile
		
		if val < 0.1:
			tile_type = TileType.WaterTile
		if val >= 0.1 and val < 0.4:
			tile_type = TileType.GrassTile
		if val >= 0.4 and val < 0.6:
			tile_type = TileType.ForestTile
		if val >= 0.6:
			tile_type = TileType.MountainTile
			
		if dist > (radius_threshold + radial_noise_weight * radius_change) * island_radius:
			tile_type = TileType.WaterTile
			
		var cell_data = {
			'type': tile_type
		}
		self.cells[Vector2(q, r)] = cell_data

func populate_cities() -> void:
	while self.get_cities().size() < self.num_cities:
		var indx = randi() % self.cells.keys().size()
		var loc: Vector2 = self.cells.keys()[indx]
		
		var is_not_water: bool = self.cells[loc]['type'] != TileType.WaterTile
		var is_not_too_to_close_to_other_cities = self.query_distance_to_cities(loc) > self.city_min_dist
		
		if is_not_water and is_not_too_to_close_to_other_cities:
			self.cells[loc]['type'] = TileType.CityTile

func _init() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# seed godot built in rng
	seed(city_seed)
	
	self.generate_hexagon(island_radius)
	self.populate_biomes()
	self.populate_cities()
	# finally, we instantiate meshes
	for cell in self.cells.keys():
		var world_pos_2d = axial_to_world(cell.x, cell.y)
		
		# create the new tile
		var new_tile = tile_mesh.instantiate()
		match self.cells[cell]['type']:
			TileType.WaterTile:
				new_tile.find_child('Cylinder').set_surface_override_material(0, water_material)
			TileType.ForestTile:
				new_tile.find_child('Cylinder').set_surface_override_material(0, forest_material)
			TileType.GrassTile:
				new_tile.find_child('Cylinder').set_surface_override_material(0, grass_material)
			TileType.MountainTile:
				new_tile.find_child('Cylinder').set_surface_override_material(0, mountain_material)
			TileType.CityTile:
				new_tile.find_child('Cylinder').set_surface_override_material(0, city_material)
		new_tile.transform.origin = Vector3(world_pos_2d.x, 0, world_pos_2d.y)
		self.add_child(new_tile)
	
	
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
