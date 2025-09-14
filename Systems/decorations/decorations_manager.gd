extends Node3D

const TileType = preload("res://Scripts/gen_grid_map.gd").TileType

@onready var rng = RandomNumberGenerator.new()
@onready var map_manager = self.get_parent()

@onready var grass_library: MeshLibrary = preload("res://Systems/decorations/grass_models.tres")
@onready var forest_library: MeshLibrary = preload("res://Systems/decorations/forest_models.tres")
@export var enabled_decorations: bool = true
@export_group("Noise Config")
@export var decoration_seed: int = 42:
	set(seed):
		rng.seed = seed

## These units are in world units NOT axial units
@export var forest_radius: float = 2.0
@export var grass_radius: float = 1.0
@export var mountain_radius: float = 5.0
@export var city_radius: float = 5.0

const K = 30  # attempts per active point

func get_random_vec2() -> Vector2:
	var x = rng.randf_range(-1.0, 1.0)
	var y = rng.randf_range(-1.0, 1.0)
	return Vector2(x, y)
	
func get_tile_from_world(world_pos: Vector2):
	var axial_coords = self.map_manager.world_to_axial(world_pos)
	return self.map_manager.get_cell(axial_coords.x, axial_coords.y)

func poisson_sample() -> Array:
	var extents: float = self.map_manager.island_radius * self.map_manager.hex_radius
	
	var points = []
	var active_list = []
	var max_radius = [self.grass_radius, self.city_radius, self.mountain_radius, self.forest_radius].max()
	var cell_size = max_radius / sqrt(2.0)
	var grid_w = int(ceil(extents / cell_size))
	var grid_h = int(ceil(extents / cell_size))
	var grid = []
	grid.resize(grid_w * grid_h)
	
	# start with initial point (can't be in water)
	var start = extents * self.get_random_vec2()
	while not get_tile_from_world(start) != null and get_tile_from_world(start)['type'] != TileType.WaterTile:
		start = extents * self.get_random_vec2()
	
	points.append(start)
	active_list.append(start)
	
	while active_list.size() > 0:
		var idx = rng.randi() % active_list.size()
		var point = active_list[idx]
		#print_debug("Active point: ", point)
		var tile_type = get_tile_from_world(point)['type']
		# check if tile_type is null?
		var radius = 0.0
		match tile_type:
			TileType.MountainTile:
				radius = self.mountain_radius
			TileType.GrassTile:
				radius = self.grass_radius
			TileType.ForestTile:
				radius = self.forest_radius
			TileType.CityTile:
				radius = self.city_radius
		var found: bool = false
		
		for _i in K:
			var angle = rng.randf() * 2 * PI
			var mag = radius * (1.0 + rng.randf())
			var new_point = point + Vector2(cos(angle), sin(angle)) * mag
			var is_not_null: bool = get_tile_from_world(new_point) != null
			if not is_not_null:
				active_list.erase(point)
				break
			var is_not_water: bool = get_tile_from_world(new_point)['type'] != TileType.WaterTile
			var is_valid: bool = self.is_valid(new_point, points, radius)
			#print_debug("test point: ", new_point )
			if is_valid and is_not_water:
				points.append(new_point)
				active_list.append(new_point)
				found = true
				break
			
			if not found:
				active_list.erase(point)
		if points.size() >= 10000:
			break
	return points
	
func is_valid(candidate: Vector2, points: Array, radius: float) -> bool:
	# reject if too close to existing points
	for p in points:
		if candidate.distance_to(p) < radius:
			return false
	return true
	
func instantiate_decoration_meshes(points: Array) -> void:
	for point in points:
		var tile_type = get_tile_from_world(point)['type']
		var tile_height = get_tile_from_world(point)['height']
		var mesh_instance = MeshInstance3D.new()
		match tile_type:
			TileType.GrassTile:
				# sample from mesh library
				var mesh = grass_library.get_item_mesh(rng.randi_range(0, 14))
				mesh_instance.mesh = mesh
			TileType.ForestTile:
				# sample from mesh library
				var mesh = forest_library.get_item_mesh(rng.randi_range(0, 11))
				mesh_instance.mesh = mesh
				
		mesh_instance.transform.origin = Vector3(point.x, tile_height, point.y)
		self.add_child(mesh_instance)

func _on_map_generated() -> void:
	if not self.enabled_decorations:
		return
	var points = self.poisson_sample()

	self.instantiate_decoration_meshes(points)
	print_debug("length of points: ", points.size())

func _ready() -> void:
	self.map_manager.connect("map_generated", _on_map_generated)
	
