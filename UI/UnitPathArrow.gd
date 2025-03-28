# Draws the unit's movement path using an autotile.
class_name UnitPathArrow
extends TileMapLayer

@export var grid: Resource

# This property caches a path found by the _pathfinder above.
# We cache the path so we can reuse it from the game board. If the player decides to confirm unit
# movement with the cursor, we can pass the path to the unit's walk_along() function.
var current_path := PackedVector2Array()

var _map: Map 

func initialize(map: Map) -> void:
	_map = map


# Finds and draws the path between `cell_start` and `cell_end`.
func draw(unit: Unit, target_cell: Vector2) -> void:
	clear()
	var pInfo: PathInfo = PathInfo.new(unit.cell, target_cell, unit.move_range, true)
	current_path = _map.calculate_path(pInfo)
	set_cells_terrain_connect(current_path, 0, 0)



# Stops drawing, clearing the drawn path and the `_pathfinder`.
func stop() -> void:
	clear()
