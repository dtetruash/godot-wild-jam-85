extends Node3D

const TileType = preload("res://Scripts/gen_grid_map.gd").TileType

@onready var rng = RandomNumberGenerator.new()
@onready var map_manager = self.get_parent()

@onready var grass_library: MeshLibrary = preload("res://Systems/decorations/grass_models.tres")
@onready var forest_library: MeshLibrary = preload("res://Systems/decorations/forest_models.tres")
@onready var mountain_library: MeshLibrary = preload("res://Systems/decorations/mountain_models.tres")
@export var enabled_decorations: bool = true
@export_group("Noise Config")
@export var decoration_seed: int = 42:
	set(seed):
		rng.seed = seed

## These units are in world units NOT axial units
@export var forest_radius: float = 1.5
@export var grass_radius: float = 0.8
@export var mountain_radius: float = 1.5
@export var city_radius: float = 7.0

const K = 30  # attempts per active point

func get_random_vec2() -> Vector2:
	var x = rng.randf_range(-1.0, 1.0)
	var y = rng.randf_range(-1.0, 1.0)
	return Vector2(x, y)

func get_tile_from_world(world_pos: Vector2):
	var axial_coords = self.map_manager.world_to_axial(world_pos)
	return self.map_manager.get_cell(axial_coords.x, axial_coords.y)

func cell_index(p: Vector2, cell_size: float, grid_w: int, grid_h: int, grid_corner: Vector2) -> int:
	var p_ = p - grid_corner
	var gx = int(p_.x / cell_size)
	var gy = int(p_.y / cell_size)

	# clamp to valid grid coordinates
	if gx < 0 or gx >= grid_w or gy < 0 or gy >= grid_h:
		return -1

	return gy * grid_w + gx

func poisson_sample() -> Array:
	var extents: float = 2.0 * (self.map_manager.island_radius + 2) * self.map_manager.hex_radius
	var points: Array = []
	var active_list: Array = []

	# Compute world-space extents based on hex geometry
	var hex_w = 2.0 * self.map_manager.hex_radius        # hex width
	var hex_h = sqrt(3.0) * self.map_manager.hex_radius # hex height

	# bounding box half-size
	var half_width  = 1.5 * hex_w * self.map_manager.island_radius
	var half_height = hex_h * self.map_manager.island_radius

	# grid corner and size
	var grid_corner = Vector2(-half_width, -half_height)
	var grid_size   = Vector2(half_width * 2.0, half_height * 2.0)

	# maximum radius for Poisson spacing
	var max_radius = max(self.grass_radius, self.city_radius, self.mountain_radius, self.forest_radius)
	var cell_size = max_radius / sqrt(2.0)

	# grid dimensions
	var grid_w = int(ceil(grid_size.x / cell_size))
	var grid_h = int(ceil(grid_size.y / cell_size))
	var grid = []
	grid.resize(grid_w * grid_h)
	for i in range(grid.size()):
		grid[i] = []  # allow multiple points per cell

	# start with initial point (can't be in water)
	var start = extents * self.get_random_vec2()
	while get_tile_from_world(start) == null or get_tile_from_world(start)['type'] == TileType.WaterTile:
		start = extents * self.get_random_vec2()
	points.append(start)
	active_list.append(start)
	grid[cell_index(start, cell_size, grid_w, grid_h, grid_corner)].append(0)
	while active_list.size() > 0:
		var idx = rng.randi() % active_list.size()
		var point = active_list[idx]

		var tile_data = get_tile_from_world(point)
		if tile_data == null:
			active_list.remove_at(idx)
			continue

		var radius := 0.0
		match tile_data['type']:
			TileType.MountainTile: radius = self.mountain_radius
			TileType.GrassTile: radius = self.grass_radius
			TileType.ForestTile: radius = self.forest_radius
			TileType.TownTile: radius = self.city_radius

		var found: bool = false

		for _i in range(K):
			var angle = rng.randf() * TAU
			var mag = radius * (1.0 + rng.randf())
			var new_point = point + Vector2(cos(angle), sin(angle)) * mag

			var tile_new = get_tile_from_world(new_point)
			if tile_new == null or tile_new['type'] == TileType.WaterTile:
				continue

			if is_valid(new_point, points, grid, cell_size, grid_w, grid_h, radius, grid_corner):
				points.append(new_point)
				active_list.append(new_point)
				grid[cell_index(new_point, cell_size, grid_w, grid_h, grid_corner)].append(points.size() - 1)
				found = true
				break

			if not found:
				active_list.erase(point)
		#if points.size() >= 100000:
			#break
	print_debug("length of sampled points: ", points.size())
	return points

func is_valid(candidate: Vector2, points: Array, grid: Array, cell_size: float, grid_w: int, grid_h: int, radius: float, grid_corner: Vector2) -> bool:
	var p_ = candidate - grid_corner
	var gx = int(p_.x / cell_size)
	var gy = int(p_.y / cell_size)

	for yy in range(max(gy - 1, 0), min(gy + 1, grid_h)):
		for xx in range(max(gx - 1, 0), min(gx + 1, grid_w)):
			for idx in grid[yy * grid_w + xx]:
				if candidate.distance_to(points[idx]) < radius:
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
				var mesh = grass_library.get_item_mesh(rng.randi_range(0, 7))
				mesh_instance.mesh = mesh
			TileType.ForestTile:
				# sample from mesh library
				var mesh = forest_library.get_item_mesh(rng.randi_range(0, 11))
				mesh_instance.mesh = mesh
			TileType.MountainTile:
				# sample from mesh library
				var mesh = mountain_library.get_item_mesh(rng.randi_range(0, 16))
				mesh_instance.mesh = mesh

		mesh_instance.transform.origin = Vector3(point.x, tile_height, point.y)
		mesh_instance.transform.rotated_local(Vector3.UP, 2 * PI * rng.randf())
		self.add_child(mesh_instance)

func generate_decorations() -> void:
	if not self.enabled_decorations:
		return
	var points = self.poisson_sample()
	self.instantiate_decoration_meshes(points)
