# Deals with the tileset itself and impassable/extra movement cost tiles.

class_name Map extends TileMap

# Grid resource, giving the node access to the grid size, and more.
@export var grid: Resource = preload("res://GameBoard/Grid.tres")

@onready var _units: Units = $"Units"

var priorityQueue = preload("res://GameBoard/PriorityQueue.gd").new()


# This constant represents the directions in which a unit can move on the board.
const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]


func _ready() -> void:
	grid.size = get_used_rect().size
	ResourceSaver.save(grid)


# Gets the movement cost of a tile on the map.
func get_movement_cost_at_tile(cell: Vector2):
	var data: TileData = get_cell_tile_data(0, cell)
	if data:
		return data.get_custom_data("Move Cost") as int

# Gets the impassability of a tile on the map. false = passable.
func get_impassable_at_tile(cell: Vector2):
	var data: TileData = get_cell_tile_data(0, cell)
	if data:
		return data.get_custom_data("Impassable") as bool

# Returns an array of cells a given unit can walk using the flood fill algorithm.
func get_walkable_cells(unit: Unit) -> Array:
	return _get_tiles_in_movement_range(unit.cell, unit.move_range)

# Returns an array with all the coordinates of walkable cells based on the `max_distance`.
func breadth_first_search(start: Vector2, max_distance: int) -> Array:
	var cells: Array = []
	var frontier := PriorityQueue.new()
	frontier.insert(start, 0)
	var came_from := {}
	var cost_so_far := {}
	came_from[start] = null
	cost_so_far[start] = 0
	
	var current: Vector2
	
	while not frontier.is_empty():
		current = frontier.extract()
			
		if not grid.is_within_bounds(current):
			continue

		# Check passability here.
		if get_impassable_at_tile(current) == true:
			continue
			
		if is_occupied(current) and current != start:
			print(current, " is occupied!")
			continue
		

		
		for direction in DIRECTIONS:
			var next: Vector2 = current + direction
			if not grid.is_within_bounds(next): continue
			var new_cost = cost_so_far[current] + get_movement_cost_at_tile(next)
			if new_cost > max_distance: continue
			if next not in cost_so_far or new_cost < cost_so_far[next]:
				cost_so_far[next] = new_cost
				var priority = new_cost
				frontier.insert(next, priority)
				came_from[next] = current
				if not cells.has(next):
					cells.append(next)
		
	return cells

func calculate_path(start: Vector2, goal: Vector2, is_player: bool, max_distance: int = 9999) -> Array:
	var frontier := PriorityQueue.new()
	frontier.insert(start, 0)
	var came_from := {}
	var cost_so_far := {}
	came_from[start] = null
	cost_so_far[start] = 0
	
	var current: Vector2
	
	while not frontier.is_empty():
		current = frontier.extract()
		if (current == goal):
			break
			
		if not grid.is_within_bounds(current):
			continue

		# Check passability here.
		if get_impassable_at_tile(current) == true:
			continue
			
		if is_occupied(current) and current != start:
			continue
			
		for direction in DIRECTIONS:
			var next: Vector2 = current + direction
			if not grid.is_within_bounds(next): continue
			var cost = get_movement_cost_at_tile(next)
			var new_cost = cost_so_far[current] + cost
			if next not in cost_so_far or new_cost < cost_so_far[next]:
				cost_so_far[next] = new_cost
				var priority = new_cost + _heuristic(goal, next)
				frontier.insert(next, priority)
				came_from[next] = current

	
	var path := []
	while (current != start):
		path.append(current)
		current = came_from[current]
	
	path.append(start)
	path.reverse()
	
	if (path.any(func(vector): return vector == goal) and not is_player):
		path.resize(path.size() - 1)
	
	if max_distance == 9999: 
		return path
	
	# Path shortening algorithm
	var limited_path := []
	limited_path.append(path.pop_front())
	var temp_distance: int = max_distance
	while (temp_distance > 0 and not path.is_empty()):
		var temp_cell = path.pop_front()
		
		if temp_distance - get_movement_cost_at_tile(temp_cell) < 0 or cost_so_far[temp_cell] > max_distance: continue
		
		limited_path.append(temp_cell)
		temp_distance -= get_movement_cost_at_tile(temp_cell)


	
	return limited_path


# Returns an array with all the coordinates of walkable cells based on the `movement_range`.
func _get_tiles_in_movement_range(cell: Vector2, movement_range: int) -> PackedVector2Array:
	var array = breadth_first_search(cell, movement_range)
	return array
	
func _same_cell(unitA, unitB):
	if(unitA == null or unitB == null):
		return false
	return (unitA.cell == unitB.cell)


# Returns `true` if the cell is occupied by a unit.
func is_occupied(_cell: Vector2i) -> bool:
	return true if _units.has_unit_at(_cell) and _units.get_unit_at(_cell).get_faction() != "Player" and _units.get_unit_at(_cell).get_faction() == "Enemy" else false

func _heuristic(a: Vector2i, b: Vector2i):
	# Manhattan distance on a square grid
	return abs(a.x - b.x) + abs(a.y - b.y)
