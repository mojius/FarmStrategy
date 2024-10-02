# Deals with the tileset itself and impassable/extra movement cost tiles.

class_name Map extends TileMap

# Grid resource, giving the node access to the grid size, and more.
@export var grid: Resource = preload("res://GameBoard/Grid.gd")

@onready var _units: Units = $"Units"

# This constant represents the directions in which a unit can move on the board.
const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
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
func _flood_fill(cell: Vector2, max_distance: int) -> Array:
	# This is the array of walkable cells the algorithm outputs.
	var array := []
	# The way we implemented the flood fill here is by using a stack. In that stack, we store every
	# cell we want to apply the flood fill algorithm to.
	var stack := [cell]
	# We loop over cells in the stack, popping one cell on every loop iteration.
	while not stack.is_empty():
		var current = stack.pop_back()

		# For each cell, we ensure that we can fill further.
		#
		# The conditions are:
		# 1. We didn't go past the grid's limits.
		# 2. We haven't already visited and filled this cell
		# 3. We are within the `max_distance`, a number of cells.
		# 4. The cell is passable. (BD. was here!) 
		if not grid.is_within_bounds(current):
			continue
		if current in array:
			continue

		# Check passability here.
		if get_impassable_at_tile(current):
			continue

		var difference: Vector2 = (current - cell).abs()
		var distance := int(difference.x + difference.y)
		if distance > max_distance:
			continue
	
		# If we meet all the conditions, we "fill" the `current` cell. To be more accurate, we store
		# it in our output `array` to later use them with the UnitPath and UnitOverlay classes.
		array.append(current)
		# We then look at the `current` cell's neighbors and, if they're not occupied and we haven't
		# visited them already, we add them to the stack for the next iteration.
		# This mechanism keeps the loop running until we found all cells the unit can walk.
		for direction in DIRECTIONS:
			var coordinates: Vector2 = current + direction
			# This is an "optimization". It does the same thing as our `if current in array:` above
			# but repeating it here with the neighbors skips some instructions.
			if is_occupied(coordinates):
				continue
			if coordinates in array:
				continue

			# This is where we extend the stack.
			stack.append(coordinates)
	return array

# Returns an array with all the coordinates of walkable cells based on the `movement_range`.
func _get_tiles_in_movement_range(cell: Vector2, movement_range: int):
	var array = _flood_fill(cell, movement_range)
	var pathfinder = PathFinder.new(grid, array)
	return pathfinder.find_tiles_in_range(cell, movement_range)

func _get_closest_cell_from_array(cell: Vector2, walkable_cells: Array):
	var _best_cell = Vector2(-9999, -9999)
	for _current_cell in walkable_cells:
		if((_best_cell-cell).length_squared() > (_current_cell-cell).length_squared()):
			_best_cell = _current_cell
	return _best_cell
	
func _same_cell(unitA, unitB):
	if(unitA == null or unitB == null):
		return false
	return (unitA.cell == unitB.cell)




# Returns `true` if the cell is occupied by a unit.
func is_occupied(_cell: Vector2) -> bool:
	return true if _units.has_unit_at(_cell) and _units.get_unit_at(_cell).get_faction() != "Player" and _units.get_unit_at(_cell).get_faction() == "Enemy" else false
