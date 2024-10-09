class_name GenericUnit extends Path2D


@export var unit_name: String = "Unit"

# Unit stats.
@export var stats: Resource

# Intensity of the shake from when the unit takes damage.
@export var shake_intensity := 50

# Singleton with information about the size of the grid.
@export var grid: Resource = preload("res://GameBoard/Grid.tres")

# Coordinates of the grid's cell the unit is on.
var cell := Vector2.ZERO : set = set_cell

# When changing the `cell`'s value, we don't want to allow coordinates outside the grid, so we clamp
# them.
func set_cell(value: Vector2) -> void:
	cell = grid.clamp(value)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if stats.hp_override:
		stats.set_hp(stats.override)
	else:
		stats.set_hp(stats.max_hp)
		
	# The following lines initialize the `cell` property and snap the unit to the cell's center on the map.
	self.cell = grid.calculate_grid_coordinates(position)
	position = grid.calculate_map_position(cell)

	if not Engine.is_editor_hint():
		# We create the curve resource here because creating it in the editor prevents us from
		# moving the unit.
		curve = Curve2D.new()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
