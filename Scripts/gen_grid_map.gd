extends GridMap

## Generates grid map terrain for the cozy train
##
## Note that this grid map only generates basic terrain types
## Decorations will be added using a separate type.

@export var num_cities: int = 6
@export var island_height: int = 50
@export var island_width: int = 50
@export var city_min_dist = 5

@export_group("Noise Config")
@export var biome_seed: int = 38 # 38 is a good seed
@export var biome_frequency: float = 0.05
@export var island_shape_seed: int = 38 # 38 is a good seed
@export var island_shape_frequency: float = 0.05

# TODO: eventually, this should be an array of 
# "City" data classes that contain other info about the city
# ie name, location, population (if we care), etc.
@onready var cities_arr: Array[Vector2i] = []


enum TileType {
	WaterTile,
	ForestTile,
	GrassTile,
	CityTile,
	MountainTile,
}

func query_distance_to_cities(q: Vector2i) -> float:
	if cities_arr.size() == 0:
		return 1000.0
	var min_dist = 100000.0 # some large value
	for city in cities_arr:
		var dist = (city - q).length()
		if min_dist > dist:
			min_dist = dist
	return min_dist

func _init() -> void:
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# clear map
	self.clear()
	
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
	
	for i in island_height:
		for j in island_width:
			var x_coord = j - (island_width / 2)
			var y_coord = i - (island_height / 2)
			var val = 0.5 * (noise.get_noise_2d(float(j), float(i)) + 1.0) # normalize to (0,1)
			
			# calculate fall off - we want an island shape, don't we? :)
			var dist = sqrt((x_coord * x_coord) + (y_coord * y_coord))
			

			var radius_change = radial_noise.get_noise_2d(float(j), float(i))
			#print_debug("x, y: ", x_coord, " ", y_coord, "radius_change: ", radius_change)
			if dist > (0.5 + 0.5 * radius_change) * map_radius:
				self.set_cell_item(Vector3i(x_coord, 0, y_coord), TileType.WaterTile, 0)
				continue
			
			if val < 0.1:
				self.set_cell_item(Vector3i(x_coord, 0, y_coord), TileType.WaterTile, 0)
			if val >= 0.1 and val < 0.2:
				self.set_cell_item(Vector3i(x_coord, 0, y_coord), TileType.GrassTile, 0)
			if val >= 0.2:
				self.set_cell_item(Vector3i(x_coord, 0, y_coord), TileType.ForestTile, 0)
				
	# OK now we place cities:	
	while cities_arr.size() < num_cities:
		var x = randi() % island_width - (island_width / 2)
		var y = randi() % island_height - (island_height / 2)
		var candidate_city = Vector2i(x, y)
		
		var is_not_water = self.get_cell_item(Vector3i(candidate_city.x, 0, candidate_city.y)) != TileType.WaterTile
		var is_not_too_close_to_existing_city = query_distance_to_cities(candidate_city) > city_min_dist
		print_debug(query_distance_to_cities(candidate_city))
		
		# check to make sure that this is not water
		if is_not_water and is_not_too_close_to_existing_city:
			cities_arr.append(candidate_city)
			
	# now we place city tiles
	for city in cities_arr:
		self.set_cell_item(Vector3i(city.x, 0, city.y), TileType.CityTile, 0)
	
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
