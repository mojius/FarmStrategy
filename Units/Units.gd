class_name Units extends Node2D

# We use a dictionary to keep track of the units that are on the board. Each key-value pair in the
# dictionary represents a unit. The key is the position in grid coordinates, while the value is a
# reference to the unit.
# Mapping of coordinates of a cell to a reference to the unit it contains.
var _units := {}
var _plants := {}

var _active_unit: Unit

signal check_should_turn_end

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reinitialize()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Clears, and refills the `_units` dictionary with game objects that are on the board.
func reinitialize() -> void:

	_units.clear()
	_plants.clear()

	# Loop over the nodes in the unit group.
	for member in get_tree().get_nodes_in_group("Unit"):
		var unit := member as Unit
		if not unit:
			continue
		
		# Using a dictionary of grid coordinates here.
		set_unit_at(unit, unit.cell)
		unit.state_changed.connect(_on_unit_state_changed)
		
		# Loop over the nodes in the unit group.
	for member in get_tree().get_nodes_in_group("Plant"):
		var plant := member
		await plant.ready
		if not plant:
			continue
		set_plant_at(plant, plant.cell)


func get_active_unit() -> Unit:
	return _active_unit

func has_unit_at(cell: Vector2) -> bool:
	return _units.has(cell)

func get_unit_at(cell: Vector2) -> Unit:
	return _units[cell]

func set_unit_at(unit: Unit, cell: Vector2) -> void:
	_units[cell] = unit

func erase_unit_at(cell: Vector2) -> void:
	_units.erase(cell)


func has_plant_at(cell: Vector2) -> bool:
	return _plants.has(cell)

func get_plant_at(cell: Vector2) -> Plant:
	return _plants[cell]

func set_plant_at(plant: Plant, cell: Vector2) -> void:
	_plants[cell] = plant

func erase_plant_at(cell: Vector2) -> void:
	_plants.erase(cell)

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
