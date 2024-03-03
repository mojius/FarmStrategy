# Deals with the tileset itself and impassable/extra movement cost tiles.

class_name Map extends TileMap

# Grid resource, giving the node access to the grid size, and more.
@export var grid: Resource = preload("res://GameBoard/Grid.gd")


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
