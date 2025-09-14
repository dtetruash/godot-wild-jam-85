@tool
extends Node3D
## Generates grid map terrain for the cozy train
##
## Note that this grid map only generates basic terrain types
## Decorations will be added using a separate type.

signal map_generated


@export var num_towns: int = 15
@export var island_radius: int = 25
@export var city_min_dist: int = 6.0
@export var hex_radius: float = 5.0
@export var radius_threshold: float = 0.9
@export var height_factor: float = 5.0
@export var mountain_height_multiplier:float = 1.5
@export var base_tile_height = 1.25

@onready var is_generated: bool = false

@export_group("Noise Config")
@export var city_seed: int = 38
@export var biome_seed: int = 38 # 38 is a good seed
@export var biome_frequency: float = 0.05
@export var island_shape_seed: int = 38 # 38 is a good seed
@export var island_shape_frequency: float = 0.05
@export var radial_noise_weight: float = 0.7

@onready var tile_mesh = preload("res://Scenes/Tilesv2.tscn")
@onready var water_material = preload("res://Assets/Materials/Water.tres")
@onready var grass_material = preload("res://Assets/Materials/Grass.tres")
@onready var forest_material = preload("res://Assets/Materials/Forest.tres")
@onready var mountain_material = preload("res://Assets/Materials/Mountain.tres")
@onready var town_material = preload("res://Assets/Materials/Town.tres")

# TODO: eventually, this should be an array of 
# "Town" data classes that contain other info about the city
# ie name, location, population (if we care), etc.

@onready var cells := {}
@onready var towns_centers: Array[Vector2i] = []

enum TileType {
	WaterTile,
	ForestTile,
	GrassTile,
	TownTile,
	MountainTile,
}

##
## Cells have the following information
## Cell {
##	axial_coordinates: Vector2(p, r)
## 	type: TileType,
##	height: float
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

# use this function if you do not care about height
func axial_to_world(q: int, r: int) -> Vector2i:
	var y = hex_radius * (3.0/2.0 * q)
	var x = hex_radius * (sqrt(3.0) * (r + q/2.0))
	return Vector2i(x, y)
	
# use this function to get a 3d world position
func axial_to_world_3d(q: int, r: int) -> Vector3:
	var height = self.cells[Vector2i(q, r)]['height']
	var y = hex_radius * (3.0/2.0 * q)
	var x = hex_radius * (sqrt(3.0) * (r + q/2.0))
	
	return Vector3(x, height, y)

func world_to_axial(pos: Vector2) -> Vector2i:
	var q = (2.0/3.0 * pos.y) / hex_radius
	var r = (-1.0/3.0 * pos.y + sqrt(3.0)/3.0 * pos.x) / hex_radius
	var v = _cube_round(Vector3(q, -q-r, r))
	return Vector2i(v.x, v.z)
	
func neighbors(q: int, r: int) -> Array[Vector2i]:
	var dirs = [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
	]
	var results: Array[Vector2i] = []
	for d in dirs:
		var n = Vector2i(q + d.x, r + d.y)
		if n in cells:
			results.append(n)
	return results
	
func get_town_centers() -> Array:
	return self.towns_centers

# returns distance to another city in axial units
func query_distance_to_cities(q: Vector2i) -> float:
	var cities_arr = self.get_town_centers()
	if cities_arr.size() == 0:
		return 1e10;
	var min_dist = 1e10; # some large value
	for city in cities_arr:
		var dist = (city - q).length()
		if min_dist > dist:
			min_dist = dist
	return min_dist
	
func get_cell(q: int, r: int) -> Variant:
	var key = Vector2i(q, r)
	if key in cells:
		return cells[key]
	return null  # or some default like "empty"

func set_cell(q: int, r: int, value: Variant) -> void:
	var key = Vector2i(q, r)
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
				cells[Vector2i(q, r)] = null
				
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
	
	for cell in self.cells.keys():
		var q = cell.x
		var r = cell.y
		var world_loc = axial_to_world(q, r)
		var x_coord = world_loc.x / hex_radius
		var y_coord = world_loc.y / hex_radius
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
		var threshold = (radius_threshold + (radial_noise_weight * radius_change)) * island_radius;
		#print_debug("threshold: ", threshold, " radius_threshold: ", radius_threshold, " radius_noise_weight", radial_noise_weight )
		if dist > threshold:
			tile_type = TileType.WaterTile
		var tile_height = max(0.0, val) if tile_type != TileType.WaterTile else 0.0
		var height_scale = height_factor * tile_height
		if tile_type == TileType.MountainTile:
			height_scale *= mountain_height_multiplier
		height_scale = 1.0 + height_scale
		var cell_data = {
			'type': tile_type,
			'height_scale': height_scale,
			'height':  self.base_tile_height * height_scale
		}
		self.cells[Vector2i(q, r)] = cell_data

func initialize_town_centers() -> void:
	while self.get_town_centers().size() < self.num_towns:
		var indx = randi() % self.cells.keys().size()
		var loc: Vector2i = self.cells.keys()[indx]
		
		var is_not_water: bool = self.cells[loc]['type'] != TileType.WaterTile
		var closest_city_dist: float = self.query_distance_to_cities(loc)
		var is_not_too_to_close_to_other_cities = closest_city_dist > self.city_min_dist
		
		if is_not_water and is_not_too_to_close_to_other_cities:
			self.cells[loc]['type'] = TileType.TownTile
			self.towns_centers.append(loc)
			
func create_map() -> void:
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
				new_tile.find_child('Cylinder').set_surface_override_material(0, forest_material)
			TileType.MountainTile:
				new_tile.find_child('Cylinder').set_surface_override_material(0, mountain_material)
			TileType.TownTile:
				new_tile.find_child('Cylinder').set_surface_override_material(0, town_material)
				
		# apply transforms
		var height_scale = self.cells[cell]['height_scale']
		new_tile.transform.origin = Vector3(world_pos_2d.x, 0, world_pos_2d.y)
		new_tile.transform = new_tile.transform.scaled_local(Vector3(1.0, height_scale, 1.0))
		self.add_child(new_tile)
		
func _init() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# clear
	self.cells.clear()
	
	# seed godot built in rng
	seed(city_seed)
	
	self.generate_hexagon(island_radius)
	self.populate_biomes()
	
	# create and populate towns
	self.initialize_town_centers()
	var town_manager = self.find_child("TownManager")
	town_manager.initialize_town_data(self.towns_centers)
	
	# finally, we instantiate meshes
	self.create_map()
	
	# call the decorate function from my child
	var decoration_manager = self.find_child("DecorationsManager")
	decoration_manager.generate_decorations()
	
	self.is_generated = true
	emit_signal("map_generated")
	
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
