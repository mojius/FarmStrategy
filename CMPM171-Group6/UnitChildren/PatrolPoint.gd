extends Sprite2D

@export var visited = false

# Singleton with information about the size of the grid.
@export var grid: Resource = preload("res://GameBoard/Grid.tres")

# Coordinates of the grid's cell the unit is on.
@export var cell := Vector2.ZERO : set = set_cell

func _ready():
	# The following lines initialize the `cell` property and snap the unit to the cell's center on the map.
	self.cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)

# When changing the `cell`'s value, we don't want to allow coordinates outside the grid, so we clamp
# them.
func set_cell(value: Vector2) -> void:
	cell = grid.clamp(value)
