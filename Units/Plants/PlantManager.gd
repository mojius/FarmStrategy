class_name PlantManager extends Node2D

var _plants := {}
const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reinitialize()

func reinitialize() -> void:
	_plants.clear()
	for member in get_tree().get_nodes_in_group("Plant"):
		var plant := member
		if not plant:
			continue
		set_plant_at(plant, plant.cell)

func has_plant_at(cell: Vector2) -> bool:
	return _plants.has(cell)

func get_plant_at(cell: Vector2) -> Plant:
	if not _plants.has(cell): return null
	return _plants[cell]

func set_plant_at(plant: Plant, cell: Vector2) -> void:
	_plants[cell] = plant

func erase_plant_at(cell: Vector2) -> void:
	_plants.erase(cell)

func grow_all() -> void:
	for _plant in _plants:
		_plants.get(_plant).grow()

func _find_plants_in_range(_unit: Unit, only_harvestable = false) -> Array:
	var target_plants: Array
	for direction in DIRECTIONS:
		var coordinates: Vector2 = _unit.cell + direction
		if has_plant_at(coordinates):
			if (only_harvestable and not get_plant_at(coordinates).is_harvestable()): continue
			target_plants.append(get_plant_at(coordinates))
	return target_plants
