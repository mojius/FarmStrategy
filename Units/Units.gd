class_name Units extends Node2D

# We use a dictionary to keep track of the units that are on the board. Each key-value pair in the
# dictionary represents a unit. The key is the position in grid coordinates, while the value is a
# reference to the unit.
# Mapping of coordinates of a cell to a reference to the unit it contains.
var _units := {}

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

var _active_unit: Unit

signal check_should_turn_end

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reinitialize()

# Clears, and refills the `_units` dictionary with game objects that are on the board.
func reinitialize() -> void:

	_units.clear()

	# Loop over the nodes in the unit group.
	for member in get_tree().get_nodes_in_group("Unit"):
		var unit := member as Unit
		if not unit:
			continue
		
		# Using a dictionary of grid coordinates here.
		set_unit_at(unit, unit.cell)
		unit.state_changed.connect(_on_unit_state_changed)

func get_active_unit() -> Unit:
	return _active_unit

func has_unit_at(cell: Vector2) -> bool:
	return _units.has(cell)

func get_unit_at(cell: Vector2) -> Unit:
	if not _units.has(cell): return null
	return _units[cell]

func set_unit_at(unit: Unit, cell: Vector2) -> void:
	_units[cell] = unit

func erase_unit_at(cell: Vector2) -> void:
	_units.erase(cell)

# Callback to check what to do when a unit's state changes.
func _on_unit_state_changed(unit: Unit) -> void:
	var state = unit.get_state()
	if (state == "Exhausted"):
		check_should_turn_end.emit()
		pass
	elif (state == "Moved"):
		pass
	elif (state == "Dead"):
		erase_unit_at(unit.cell)

# Finds all units in range.
func _find_units_in_range(_unit: Unit) -> Array:
	var active_targets: Array
	for direction in DIRECTIONS:
		var coordinates: Vector2 = _unit.cell + direction
		if has_unit_at(coordinates) and get_unit_at(coordinates).get_faction() == _unit.get_enemy_faction() and get_unit_at(coordinates) not in active_targets:
			active_targets.append(get_unit_at(coordinates))
	return active_targets
