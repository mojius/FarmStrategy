class_name Plants extends Node2D

var _plants := {}

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
	return _plants[cell]

func set_plant_at(plant: Plant, cell: Vector2) -> void:
	_plants[cell] = plant

func erase_plant_at(cell: Vector2) -> void:
	_plants.erase(cell)

func grow_all() -> void:
	for _plant in _plants:
		_plants.get(_plant).grow()
