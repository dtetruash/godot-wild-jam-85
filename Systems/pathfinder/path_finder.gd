extends Node3D

const TileType = preload("res://Scripts/gen_grid_map.gd").TileType

var debugged:= false

class PriorityQueue:
	var elements = []

	func is_empty() -> bool:
		return elements.is_empty()
		
	func has(element) -> bool:
		return elements.has(element)

	func push(item, priority: float) -> void:
		elements.append({"item": item, "priority": priority})
		elements.sort_custom(func(a, b): return a["priority"] < b["priority"])

	func pop():
		return elements.pop_front()["item"]

@onready var map_manager = self.get_parent()

func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var dq = abs(a.x - b.x)
	var dr = abs(a.y - b.y)
	var ds = abs((-a.x - a.y) - (-b.x - b.y))  # since s = -q-r
	return max(dq, dr, ds)

func reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var total_path: Array[Vector2i] = [current]
	var tile = current
	var depth:int = 0
	var seen: = {}
	while came_from.has(tile):
		if seen.has(tile):
			push_error("Cycle detected in came_from at %s" % tile)
			break
		seen[tile] = true
		tile = came_from[tile]
		total_path.append(tile)
		depth += 1
	total_path.reverse()
	return total_path
	
func movement_cost(tile: Dictionary) -> int:
	match tile['type']:
		TileType.GrassTile:
			return 1
		TileType.ForestTile:
			return 2
		TileType.MountainTile:
			return 4
		TileType.TownTile:
			return 1
		TileType.WaterTile:
			return INF
		_:
			return INF

## A* finds a path from start to goal.
## The path should be the cheapest available with respect to some cost,
## see movement_cost()
func a_star(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var tiles = self.map_manager.cells
	
	if not tiles.has(start) or not tiles.has(goal):
		print_debug("Tiles not found")
		return []
	
	# The open set is the list of points that 
	# still need to be explored
	var open_set:= PriorityQueue.new()
	open_set.push(start, 0)
	
	# for a node N, came_from is the node preceeding it
	var came_from = {}
	# for a node n, g_score[n] is the currently known cost of the cheapest path
	# from start to n
	var g_score = {}
	g_score[start] = 0
	
	var closed := {}
	
	while not open_set.is_empty():
		var current = open_set.pop()
		
		if current == came_from.get(current, null):
			push_error("Self-parent detected at %s" % current)
			return []
			
		# skip if already finalized
		if closed.has(current):
			continue

		# finalize current
		closed[current] = true

		# safety check (self-parent)
		if current == came_from.get(current, null):
			push_error("Self-parent detected at %s" % str(current))
			return []
		
		if current == goal:
			return reconstruct_path(came_from, current)
		var neighbors: Array[Vector2i] = self.map_manager.neighbors(current.x, current.y)
		for neighbor in neighbors:
			if not tiles.has(neighbor):
				continue
				
			if closed.has(neighbor):
				continue
			
			var tile = tiles[neighbor]
			var cost = movement_cost(tile)
			if cost == INF:
				continue # skip if water or invalid
				
			var tentative_g = g_score[current] + cost
			if not g_score.has(neighbor) or tentative_g < g_score[neighbor]:
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				var f_score = tentative_g + hex_distance(neighbor, goal)
				#if not open_set.has(neighbor):
				open_set.push(neighbor, f_score)
				
	return []
	
func _process(delta: float) -> void:
	if not debugged:
		var start = self.map_manager.get_town_centers()[0]
		var goal = self.map_manager.get_town_centers()[1]
		print_debug("Finding shorted path from ", start, " to ", goal)
		var path = self.a_star(start, goal)
		debugged = true
		print_debug("path found: ", path)
