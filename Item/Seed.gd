class_name Seed extends Item

@export var corresponding_plant: PackedScene

func use(unit: Unit):
	unit.try_plant.emit(self)
